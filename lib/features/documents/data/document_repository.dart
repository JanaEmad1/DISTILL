import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/ai/ai_service.dart';
import '../../../core/constants.dart';
import '../../../shared/services/text_extraction_service.dart';
import 'models/document_model.dart';

/// Live progress of the upload→summary pipeline. Backed by Realtime Database
/// at `progress/{uid}/{docId}` so the Processing screen updates in real time.
class ProcessingProgress {
  const ProcessingProgress({required this.status, required this.percent});
  final DocStatus status;
  final int percent; // 0..100
}

abstract interface class DocumentRepository {
  Stream<List<DocumentModel>> watchDocuments();
  Stream<DocumentModel?> watchDocument(String id);
  Stream<ProcessingProgress?> watchProgress(String docId);

  /// Runs the full pipeline: create doc → upload bytes → extract text →
  /// summarize. Returns the new document id immediately; progress streams via
  /// [watchProgress]. Pushes the heavy work onto [run] in the background.
  Future<String> uploadAndProcess({
    required String fileName,
    required String type,
    required int sizeBytes,
    required Uint8List bytes,
  });

  Future<void> toggleFavorite(String id, bool favorite);
  Future<void> delete(String id);
}

class FirebaseDocumentRepository implements DocumentRepository {
  FirebaseDocumentRepository({
    required this.uid,
    required FirebaseFirestore db,
    required FirebaseStorage storage,
    required FirebaseDatabase rtdb,
    required AiService ai,
    required TextExtractionService extractor,
  })  : _db = db,
        _storage = storage,
        _rtdb = rtdb,
        _ai = ai,
        _extractor = extractor;

  final String uid;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseDatabase _rtdb;
  final AiService _ai;
  final TextExtractionService _extractor;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(uid).collection('documents');

  DatabaseReference _progressRef(String docId) =>
      _rtdb.ref('progress/$uid/$docId');

  @override
  Stream<List<DocumentModel>> watchDocuments() => _col
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => DocumentModel.fromMap(d.id, d.data())).toList());

  @override
  Stream<DocumentModel?> watchDocument(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? DocumentModel.fromMap(d.id, d.data()!) : null);

  @override
  Stream<ProcessingProgress?> watchProgress(String docId) =>
      _progressRef(docId).onValue.map((event) {
        final v = event.snapshot.value;
        if (v is! Map) return null;
        final map = Map<String, dynamic>.from(v);
        return ProcessingProgress(
          status: DocStatus.values.firstWhere(
            (s) => s.name == map['status'],
            orElse: () => DocStatus.uploading,
          ),
          percent: (map['percent'] ?? 0) as int,
        );
      });

  Future<void> _setProgress(String docId, DocStatus status, int percent) =>
      _progressRef(docId).set({'status': status.name, 'percent': percent});

  @override
  Future<String> uploadAndProcess({
    required String fileName,
    required String type,
    required int sizeBytes,
    required Uint8List bytes,
  }) async {
    final now = DateTime.now();
    final ref = await _col.add(DocumentModel(
      id: 'tmp',
      name: fileName,
      type: type,
      sizeBytes: sizeBytes,
      status: DocStatus.uploading,
      createdAt: now,
      updatedAt: now,
    ).toMap());
    final docId = ref.id;

    // Run the pipeline without blocking the caller (UI navigates to Processing).
    unawaited(_runPipeline(docId, fileName, type, bytes));
    return docId;
  }

  Future<void> _runPipeline(
      String docId, String fileName, String type, Uint8List bytes) async {
    final docRef = _col.doc(docId);
    try {
      await _setProgress(docId, DocStatus.uploading, 10);
      final path = 'users/$uid/documents/$docId/$fileName';
      final task =
          await _storage.ref(path).putData(bytes, SettableMetadata(contentType: _mime(type)));
      final url = await task.ref.getDownloadURL();
      await docRef.update({'storagePath': path, 'downloadUrl': url});
      await _setProgress(docId, DocStatus.uploading, 35);

      await _setProgress(docId, DocStatus.extracting, 45);
      final extracted = await _extractor.extract(bytes: bytes, type: type);
      await docRef.update({
        'status': DocStatus.extracting.name,
        'extractedText': extracted.text,
        'pages': extracted.pages,
      });
      await _setProgress(docId, DocStatus.extracting, 60);

      await _setProgress(docId, DocStatus.summarizing, 70);
      final result = await _ai.summarize(extracted.text, title: fileName);
      await docRef.update({
        'status': DocStatus.ready.name,
        'summary': result.summary,
        'keyPoints': result.keyPoints,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      await _setProgress(docId, DocStatus.ready, 100);
      await _bumpUserDocCount(1);
    } catch (e) {
      await docRef.update({'status': DocStatus.error.name});
      await _setProgress(docId, DocStatus.error, 0);
    }
  }

  Future<void> _bumpUserDocCount(int delta) => _db
      .collection('users')
      .doc(uid)
      .set({'docCount': FieldValue.increment(delta)}, SetOptions(merge: true));

  @override
  Future<void> toggleFavorite(String id, bool favorite) =>
      _col.doc(id).update({'favorite': favorite});

  @override
  Future<void> delete(String id) async {
    final snap = await _col.doc(id).get();
    final path = snap.data()?['storagePath'] as String?;
    if (path != null) {
      try {
        await _storage.ref(path).delete();
      } catch (_) {/* file may already be gone */}
    }
    await _col.doc(id).delete();
    await _progressRef(id).remove();
    await _bumpUserDocCount(-1);
  }

  String _mime(String type) => switch (type) {
        'pdf' => 'application/pdf',
        'docx' =>
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        _ => 'text/plain',
      };
}

import 'dart:async';
import 'dart:typed_data';

import '../../../core/ai/ai_service.dart';
import '../../../core/constants.dart';
import '../../../shared/services/text_extraction_service.dart';
import 'document_repository.dart';
import 'models/document_model.dart';

/// In-memory DocumentRepository for DEMO mode and tests. Seeds the sample
/// documents shown in the mockups and runs the same pipeline shape using the
/// injected (stub) AI + extractor, broadcasting progress via a stream.
class DemoDocumentRepository implements DocumentRepository {
  DemoDocumentRepository({required AiService ai, TextExtractionService? extractor})
      : _ai = ai,
        _extractor = extractor ?? const TextExtractionService() {
    _docs.addAll(_seed());
    _emit();
  }

  final AiService _ai;
  final TextExtractionService _extractor;

  final _docs = <DocumentModel>[];
  final _docsController = StreamController<List<DocumentModel>>.broadcast();
  final _progressControllers =
      <String, StreamController<ProcessingProgress?>>{};

  bool _disposed = false;

  void _emit() {
    if (_disposed) return;
    _docsController.add(List.unmodifiable(_docs));
  }

  @override
  Stream<List<DocumentModel>> watchDocuments() async* {
    yield List.unmodifiable(_docs);
    yield* _docsController.stream;
  }

  @override
  Stream<DocumentModel?> watchDocument(String id) =>
      watchDocuments().map((list) {
        for (final d in list) {
          if (d.id == id) return d;
        }
        return null;
      });

  StreamController<ProcessingProgress?> _progressCtrl(String id) =>
      _progressControllers.putIfAbsent(
          id, () => StreamController<ProcessingProgress?>.broadcast());

  @override
  Stream<ProcessingProgress?> watchProgress(String docId) async* {
    final ctrl = _progressCtrl(docId);
    yield null;
    yield* ctrl.stream;
  }

  void _setProgress(String id, DocStatus status, int percent) {
    if (_disposed) return;
    _progressCtrl(id).add(ProcessingProgress(status: status, percent: percent));
  }

  void _update(String id, DocumentModel Function(DocumentModel) fn) {
    final i = _docs.indexWhere((d) => d.id == id);
    if (i != -1) {
      _docs[i] = fn(_docs[i]);
      _emit();
    }
  }

  @override
  Future<String> uploadAndProcess({
    required String fileName,
    required String type,
    required int sizeBytes,
    required Uint8List bytes,
  }) async {
    final id = 'doc-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    _docs.insert(
      0,
      DocumentModel(
        id: id,
        name: fileName,
        type: type,
        sizeBytes: sizeBytes,
        status: DocStatus.uploading,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _emit();
    unawaited(_runPipeline(id, fileName, type, bytes));
    return id;
  }

  Future<void> _runPipeline(
      String id, String fileName, String type, Uint8List bytes) async {
    try {
      _setProgress(id, DocStatus.uploading, 20);
      await Future<void>.delayed(const Duration(milliseconds: 500));

      _setProgress(id, DocStatus.extracting, 50);
      final extracted = await _extractor.extract(bytes: bytes, type: type);
      _update(
          id,
          (d) => d.copyWith(
              status: DocStatus.extracting,
              extractedText: extracted.text,
              pages: extracted.pages));

      _setProgress(id, DocStatus.summarizing, 75);
      final result = await _ai.summarize(extracted.text, title: fileName);
      _update(
          id,
          (d) => d.copyWith(
              status: DocStatus.ready,
              summary: result.summary,
              keyPoints: result.keyPoints,
              updatedAt: DateTime.now()));
      _setProgress(id, DocStatus.ready, 100);
    } catch (_) {
      _update(id, (d) => d.copyWith(status: DocStatus.error));
      _setProgress(id, DocStatus.error, 0);
    }
  }

  @override
  Future<void> toggleFavorite(String id, bool favorite) async =>
      _update(id, (d) => d.copyWith(favorite: favorite));

  @override
  Future<void> delete(String id) async {
    _docs.removeWhere((d) => d.id == id);
    _emit();
  }

  List<DocumentModel> _seed() {
    final now = DateTime.now();
    return [
      DocumentModel(
        id: 'seed-q4',
        name: 'Q4_Financial_Report.pdf',
        type: 'pdf',
        sizeBytes: 4 * 1024 * 1024 + 200 * 1024,
        status: DocStatus.ready,
        pages: 24,
        summary:
            'The Fourth Quarter Financial Report highlights a robust period of '
            'growth, with total revenue reaching \$48.2 million, representing a '
            'solid +15% year-over-year increase. This expansion was primarily '
            'driven by the strong performance of core digital offerings and '
            'strategic market penetration.\n\nA significant highlight of this '
            'quarter is the exceptional 28% growth in SaaS revenue, signaling a '
            'successful transition toward more predictable recurring income.',
        keyPoints: const [
          'Total revenue reached \$48.2M, up 15% year-over-year',
          'SaaS revenue grew 28%, improving recurring income',
          'Operating margins expanded to 24.3%',
          'APAC expansion and AI Premium tier launch drove growth',
        ],
        extractedText:
            'Q4 Financial Report. Total revenue reached \$48.2 million, a 15% '
            'year-over-year increase. Enterprise SaaS revenue grew 28% '
            'year-over-year, outpacing internal projections for the quarter. '
            'Operating margins expanded to 24.3% due to streamlined cloud '
            'infrastructure costs. Key risks include FX exposure in APAC and '
            'customer concentration in the top five accounts.',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      DocumentModel(
        id: 'seed-manifesto',
        name: 'Project_Manifesto_v2.docx',
        type: 'docx',
        sizeBytes: 1024 * 1024 + 100 * 1024,
        status: DocStatus.ready,
        pages: 8,
        summary:
            'A comprehensive breakdown of the core pillars for Project '
            'Mindflow, outlining the product vision, guiding principles, and '
            'the roadmap for the next two quarters.',
        keyPoints: const [
          'Defines three product pillars: clarity, speed, trust',
          'Sets a two-quarter delivery roadmap',
          'Establishes team working agreements',
        ],
        extractedText:
            'Project Mindflow Manifesto. Our mission is to help people think '
            'more clearly. Three pillars guide us: clarity, speed, and trust.',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      DocumentModel(
        id: 'seed-research',
        name: 'Research_Paper_AI_Ethics.pdf',
        type: 'pdf',
        sizeBytes: 8 * 1024 * 1024 + 500 * 1024,
        status: DocStatus.summarizing,
        pages: 32,
        extractedText:
            'On the ethics of artificial intelligence: fairness, accountability, '
            'and transparency in automated decision systems.',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      DocumentModel(
        id: 'seed-notes',
        name: 'Meeting_Notes_Jan.txt',
        type: 'txt',
        sizeBytes: 12 * 1024,
        status: DocStatus.ready,
        pages: 1,
        summary:
            'Action items from the January sync including the transition to the '
            'new sprint cadence and ownership assignments.',
        keyPoints: const [
          'Adopt two-week sprint cadence',
          'Assign feature owners for Q1',
          'Schedule design review for next Thursday',
        ],
        extractedText:
            'January sync notes. Action items: move to two-week sprints, '
            'assign owners, schedule design review.',
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
    ];
  }

  void dispose() {
    _disposed = true;
    _docsController.close();
    for (final c in _progressControllers.values) {
      c.close();
    }
  }
}

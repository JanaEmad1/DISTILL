import 'package:distill/core/constants.dart';
import 'package:distill/features/documents/data/models/document_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fixtures.dart';

void main() {
  group('DocumentModel', () {
    test('isReady reflects status', () {
      expect(Fixtures.document(status: DocStatus.ready).isReady, isTrue);
      expect(Fixtures.document(status: DocStatus.summarizing).isReady, isFalse);
    });

    test('toMap/fromMap roundtrips all fields', () {
      final doc = Fixtures.document(favorite: true);
      final restored = DocumentModel.fromMap(doc.id, doc.toMap());

      expect(restored.id, doc.id);
      expect(restored.name, doc.name);
      expect(restored.type, doc.type);
      expect(restored.sizeBytes, doc.sizeBytes);
      expect(restored.status, doc.status);
      expect(restored.pages, doc.pages);
      expect(restored.summary, doc.summary);
      expect(restored.keyPoints, doc.keyPoints);
      expect(restored.extractedText, doc.extractedText);
      expect(restored.favorite, isTrue);
      expect(restored.createdAt, doc.createdAt);
      expect(restored.updatedAt, doc.updatedAt);
    });

    test('fromMap falls back to safe defaults for missing fields', () {
      final doc = DocumentModel.fromMap('x', const {});
      expect(doc.name, 'Untitled');
      expect(doc.type, 'txt');
      expect(doc.sizeBytes, 0);
      expect(doc.status, DocStatus.ready);
      expect(doc.keyPoints, isEmpty);
      expect(doc.favorite, isFalse);
    });

    test('fromMap parses an unknown status as ready', () {
      final doc = DocumentModel.fromMap('x', {'status': 'bogus'});
      expect(doc.status, DocStatus.ready);
    });

    test('copyWith preserves identity fields and overrides the rest', () {
      final doc = Fixtures.document(status: DocStatus.summarizing);
      final updated = doc.copyWith(status: DocStatus.ready, favorite: true);

      expect(updated.id, doc.id);
      expect(updated.type, doc.type);
      expect(updated.createdAt, doc.createdAt);
      expect(updated.status, DocStatus.ready);
      expect(updated.favorite, isTrue);
    });
  });

  group('DocStatusX', () {
    test('isProcessing is true for in-flight states only', () {
      expect(DocStatus.uploading.isProcessing, isTrue);
      expect(DocStatus.extracting.isProcessing, isTrue);
      expect(DocStatus.summarizing.isProcessing, isTrue);
      expect(DocStatus.ready.isProcessing, isFalse);
      expect(DocStatus.error.isProcessing, isFalse);
    });

    test('label is human readable', () {
      expect(DocStatus.ready.label, 'Summarized');
      expect(DocStatus.error.label, 'Failed');
    });
  });
}

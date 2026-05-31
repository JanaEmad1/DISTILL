import 'package:distill/core/ai/stub_ai_service.dart';
import 'package:distill/core/constants.dart';
import 'package:distill/features/documents/data/demo_document_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures.dart';

void main() {
  late DemoDocumentRepository repo;

  setUp(() => repo = DemoDocumentRepository(ai: const StubAiService()));
  tearDown(() => repo.dispose());

  test('seeds the sample documents shown in the mockups', () async {
    final docs = await repo.watchDocuments().first;
    expect(docs.map((d) => d.id),
        containsAll(['seed-q4', 'seed-manifesto', 'seed-research', 'seed-notes']));
  });

  test('uploadAndProcess inserts the new doc at the top in uploading state',
      () async {
    final id = await repo.uploadAndProcess(
      fileName: 'New.txt',
      type: 'txt',
      sizeBytes: 12,
      bytes: Fixtures.txtBytes(),
    );

    final docs = await repo.watchDocuments().first;
    expect(docs.first.id, id);
    expect(docs.first.name, 'New.txt');
    expect(docs.first.status, DocStatus.uploading);
  });

  test('pipeline drives a TXT upload through to ready with a summary',
      () async {
    final id = await repo.uploadAndProcess(
      fileName: 'New.txt',
      type: 'txt',
      sizeBytes: 40,
      bytes: Fixtures.txtBytes('Alpha beta gamma delta epsilon.'),
    );

    // Wait for the document to reach a terminal state.
    final doc = await repo
        .watchDocument(id)
        .firstWhere((d) => d != null && !d.status.isProcessing);

    expect(doc!.status, DocStatus.ready);
    expect(doc.extractedText, contains('Alpha beta gamma'));
    expect(doc.summary, isNotNull);
    expect(doc.keyPoints, isNotEmpty);
  });

  test('watchProgress reports completion at 100%', () async {
    final id = await repo.uploadAndProcess(
      fileName: 'New.txt',
      type: 'txt',
      sizeBytes: 40,
      bytes: Fixtures.txtBytes(),
    );

    final done = await repo
        .watchProgress(id)
        .firstWhere((p) => p != null && p.status == DocStatus.ready);
    expect(done!.percent, 100);
  });

  test('toggleFavorite flips the favorite flag', () async {
    await repo.toggleFavorite('seed-notes', true);
    final doc =
        (await repo.watchDocuments().first).firstWhere((d) => d.id == 'seed-notes');
    expect(doc.favorite, isTrue);
  });

  test('delete removes a document', () async {
    await repo.delete('seed-notes');
    final docs = await repo.watchDocuments().first;
    expect(docs.any((d) => d.id == 'seed-notes'), isFalse);
  });
}

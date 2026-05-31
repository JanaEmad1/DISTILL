import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:distill/shared/services/text_extraction_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a minimal but valid `.docx` (a zip whose body is `word/document.xml`)
/// from the given WordprocessingML body XML.
Uint8List _docxWithBody(String bodyXml) {
  final xml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:body>$bodyXml</w:body></w:document>';
  final data = utf8.encode(xml);
  final archive = Archive()
    ..addFile(ArchiveFile('word/document.xml', data.length, data));
  return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
}

void main() {
  const service = TextExtractionService();

  group('TextExtractionService DOCX', () {
    test('extracts paragraph text and decodes entities, dropping markup',
        () async {
      final bytes = _docxWithBody(
        '<w:p><w:r><w:t>Hello world</w:t></w:r></w:p>'
        '<w:p><w:r><w:t>Second &amp; final line</w:t></w:r></w:p>',
      );

      final result = await service.extract(bytes: bytes, type: 'docx');

      expect(result.text, contains('Hello world'));
      expect(result.text, contains('Second & final line'));
      // Markup must be gone, and entities decoded (no raw &amp;).
      expect(result.text, isNot(contains('<w:')));
      expect(result.text, isNot(contains('&amp;')));
      // The two paragraphs land on separate lines.
      expect(result.text.split('\n').length, greaterThanOrEqualTo(2));
      expect(result.pages, 1);
    });

    test('falls back without throwing on bytes that are not a valid zip',
        () async {
      final garbage = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7]);

      final result = await service.extract(bytes: garbage, type: 'docx');

      // The fallback path returns a non-empty string rather than throwing.
      expect(result.text, isNotEmpty);
      expect(result.pages, 1);
    });
  });

  group('TextExtractionService TXT', () {
    test('decodes plain text directly', () async {
      final bytes = Uint8List.fromList(utf8.encode('Just some text.'));

      final result = await service.extract(bytes: bytes, type: 'txt');

      expect(result.text, 'Just some text.');
      expect(result.pages, 1);
    });
  });
}

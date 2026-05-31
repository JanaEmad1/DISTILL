import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ExtractedText {
  const ExtractedText({required this.text, required this.pages});
  final String text;
  final int pages;
}

/// Extracts plain text from uploaded files, client-side (no server needed).
/// PDF via Syncfusion, TXT decoded directly, DOCX unzipped via `archive`
/// (with a tag-strip fallback for malformed files).
class TextExtractionService {
  const TextExtractionService();

  Future<ExtractedText> extract({
    required Uint8List bytes,
    required String type,
  }) async {
    switch (type) {
      case 'pdf':
        return _extractPdf(bytes);
      case 'txt':
        return ExtractedText(text: _decode(bytes), pages: 1);
      case 'docx':
        return ExtractedText(text: _extractDocx(bytes), pages: 1);
      default:
        return ExtractedText(text: _decode(bytes), pages: 1);
    }
  }

  ExtractedText _extractPdf(Uint8List bytes) {
    final doc = PdfDocument(inputBytes: bytes);
    try {
      final pages = doc.pages.count;
      final text = PdfTextExtractor(doc).extractText();
      return ExtractedText(text: text.trim(), pages: pages);
    } finally {
      doc.dispose();
    }
  }

  String _decode(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes);
    }
  }

  /// A DOCX is a zip archive whose body lives in `word/document.xml`. We unzip
  /// it, turn paragraph (`</w:p>`), break (`<w:br/>`) and tab (`<w:tab/>`) tags
  /// into real whitespace, strip the remaining XML, and decode entities — so
  /// the output reads like the original document rather than raw markup.
  ///
  /// If anything goes wrong (corrupt zip, missing part, unexpected format) we
  /// fall back to the previous best-effort tag-strip so the upload pipeline
  /// never crashes on a malformed file.
  String _extractDocx(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final entry = archive.findFile('word/document.xml');
      if (entry == null) return _stripDocxBytes(bytes);

      final xml = utf8.decode(
        (entry.content as List<int>),
        allowMalformed: true,
      );

      final withBreaks = xml
          .replaceAll(RegExp(r'</w:p>'), '\n')
          .replaceAll(RegExp(r'<w:br\s*/?>'), '\n')
          .replaceAll(RegExp(r'<w:tab\s*/?>'), '\t');
      final stripped = withBreaks.replaceAll(RegExp(r'<[^>]+>'), '');
      final decoded = _decodeXmlEntities(stripped);

      final lines = decoded
          .split('\n')
          .map((l) => l.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
          .where((l) => l.isNotEmpty)
          .toList();
      final text = lines.join('\n').trim();

      return text.isEmpty ? _stripDocxBytes(bytes) : text;
    } catch (_) {
      return _stripDocxBytes(bytes);
    }
  }

  /// Last-resort DOCX fallback: decode the raw bytes and strip anything that
  /// looks like a tag. Garbled, but never throws.
  String _stripDocxBytes(Uint8List bytes) {
    final raw = _decode(bytes);
    final cleaned = raw
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty
        ? 'Unable to extract text from this DOCX file. Try a PDF or TXT.'
        : cleaned;
  }

  String _decodeXmlEntities(String input) => input
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'");
}

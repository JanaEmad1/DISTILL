import 'dart:convert';
import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

class ExtractedText {
  const ExtractedText({required this.text, required this.pages});
  final String text;
  final int pages;
}

/// Extracts plain text from uploaded files, client-side (no server needed).
/// PDF via Syncfusion, TXT decoded directly. DOCX is best-effort.
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

  /// DOCX is a zip of XML. Without a zip dependency we strip XML tags from the
  /// raw bytes as a best-effort fallback; PDF/TXT are the fully-supported paths.
  String _extractDocx(Uint8List bytes) {
    final raw = _decode(bytes);
    final stripped = raw.replaceAll(RegExp(r'<[^>]+>'), ' ');
    final cleaned =
        stripped.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isEmpty
        ? 'Unable to extract text from this DOCX file. Try a PDF or TXT.'
        : cleaned;
  }
}

import 'models/document_model.dart';

/// Builds a plain-text representation of a document's AI insights, used both
/// for copying to the clipboard and for the system share sheet.
///
/// Pure (no Flutter / IO) so it can be unit-tested directly. Sections are
/// omitted gracefully when empty, so an in-progress document still produces
/// sensible text (just its title + footer).
String buildShareText(DocumentModel doc) {
  final buffer = StringBuffer()..writeln(doc.name);

  final summary = doc.summary?.trim();
  if (summary != null && summary.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('AI Summary')
      ..writeln(summary);
  }

  final points = doc.keyPoints.where((p) => p.trim().isNotEmpty).toList();
  if (points.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('Key Points');
    for (final point in points) {
      buffer.writeln('• ${point.trim()}');
    }
  }

  buffer
    ..writeln()
    ..write('Summarized with Distill');

  return buffer.toString().trim();
}

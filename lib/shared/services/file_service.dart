import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../core/constants.dart';

class PickedDocument {
  const PickedDocument({
    required this.name,
    required this.type,
    required this.sizeBytes,
    required this.bytes,
  });
  final String name;
  final String type; // extension without dot
  final int sizeBytes;
  final Uint8List bytes;
}

class FilePickException implements Exception {
  FilePickException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Wraps file_picker and enforces the allowed types / size limit.
class FileService {
  const FileService();

  Future<PickedDocument?> pickDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final ext = (file.extension ?? '').toLowerCase();
    if (!AppConstants.allowedExtensions.contains(ext)) {
      throw FilePickException('Only PDF, DOCX, or TXT files are supported.');
    }
    if (file.size > AppConstants.maxFileSizeBytes) {
      throw FilePickException('That file is larger than the 50MB limit.');
    }
    final bytes = file.bytes;
    if (bytes == null) {
      throw FilePickException('Could not read that file. Please try again.');
    }
    return PickedDocument(
      name: file.name,
      type: ext,
      sizeBytes: file.size,
      bytes: bytes,
    );
  }
}

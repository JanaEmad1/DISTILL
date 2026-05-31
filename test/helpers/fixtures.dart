import 'dart:typed_data';

import 'package:distill/core/constants.dart';
import 'package:distill/features/auth/data/models/app_user.dart';
import 'package:distill/features/chat/data/models/chat_message.dart';
import 'package:distill/features/documents/data/models/document_model.dart';

/// Sample data factories. Keep test setup terse and intention-revealing.
abstract final class Fixtures {
  static final _epoch = DateTime(2026, 1, 1, 9);

  static AppUser user({
    String uid = 'user-1',
    String email = 'alice@test.com',
    String? displayName = 'Alice',
    int docCount = 3,
    int questionCount = 12,
    int storageBytes = 1024 * 1024,
  }) =>
      AppUser(
        uid: uid,
        email: email,
        displayName: displayName,
        docCount: docCount,
        questionCount: questionCount,
        storageBytes: storageBytes,
      );

  static DocumentModel document({
    String id = 'doc-1',
    String name = 'Report.pdf',
    String type = 'pdf',
    int sizeBytes = 2 * 1024 * 1024,
    DocStatus status = DocStatus.ready,
    String? summary = 'A concise summary of the document.',
    List<String> keyPoints = const ['Point one', 'Point two'],
    String extractedText = 'The full extracted body text.',
    bool favorite = false,
  }) =>
      DocumentModel(
        id: id,
        name: name,
        type: type,
        sizeBytes: sizeBytes,
        status: status,
        pages: 10,
        summary: summary,
        keyPoints: keyPoints,
        extractedText: extractedText,
        favorite: favorite,
        createdAt: _epoch,
        updatedAt: _epoch,
      );

  static ChatMessage message({
    String id = 'm-1',
    bool isUser = true,
    String text = 'What is this about?',
    List<Citation> citations = const [],
    bool pending = false,
  }) =>
      ChatMessage(
        id: id,
        isUser: isUser,
        text: text,
        citations: citations,
        pending: pending,
        createdAt: _epoch,
      );

  /// A tiny TXT payload for exercising the upload pipeline.
  static Uint8List txtBytes([String content = 'Hello world. This is a test document.']) =>
      Uint8List.fromList(content.codeUnits);
}

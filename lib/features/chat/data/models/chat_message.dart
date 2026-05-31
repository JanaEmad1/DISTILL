import 'package:cloud_firestore/cloud_firestore.dart';

/// A quote pulled from the source document, optionally with a page reference.
class Citation {
  const Citation({required this.quote, this.page});
  final String quote;
  final int? page;

  Map<String, dynamic> toMap() => {'quote': quote, 'page': page};
  factory Citation.fromMap(Map<String, dynamic> m) =>
      Citation(quote: (m['quote'] ?? '') as String, page: m['page'] as int?);
}

/// One message in a document chat. Maps to
/// `users/{uid}/chats/{chatId}/messages/{msgId}`.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.citations = const [],
    required this.createdAt,
    this.pending = false,
  });

  final String id;
  final bool isUser;
  final String text;
  final List<Citation> citations;
  final DateTime createdAt;

  /// True while an AI reply is still streaming in (not persisted).
  final bool pending;

  Map<String, dynamic> toMap() => {
        'isUser': isUser,
        'text': text,
        'citations': citations.map((c) => c.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) =>
      ChatMessage(
        id: id,
        isUser: (map['isUser'] ?? false) as bool,
        text: (map['text'] ?? '') as String,
        citations: (map['citations'] as List?)
                ?.map((e) => Citation.fromMap(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  ChatMessage copyWith({String? text, bool? pending, List<Citation>? citations}) =>
      ChatMessage(
        id: id,
        isUser: isUser,
        text: text ?? this.text,
        citations: citations ?? this.citations,
        createdAt: createdAt,
        pending: pending ?? this.pending,
      );
}

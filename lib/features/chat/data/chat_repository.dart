import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/chat_message.dart';

/// Lightweight summary of a conversation, used to render the Chats tab.
class ChatSummary {
  const ChatSummary({
    required this.documentId,
    required this.documentName,
    required this.lastMessage,
    required this.updatedAt,
  });

  final String documentId;
  final String documentName;
  final String lastMessage;
  final DateTime updatedAt;
}

/// Persists chat messages per document. One chat document per source document
/// (chatId == documentId) keeps the model simple.
abstract interface class ChatRepository {
  Stream<List<ChatMessage>> watchMessages(String chatId);
  Stream<List<ChatSummary>> watchChats();
  Future<void> addMessage(String chatId, ChatMessage message,
      {String? documentName});
  Future<void> incrementQuestionCount();
}

class FirebaseChatRepository implements ChatRepository {
  FirebaseChatRepository({required this.uid, required FirebaseFirestore db})
      : _db = db;

  final String uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _messages(String chatId) => _db
      .collection('users')
      .doc(uid)
      .collection('chats')
      .doc(chatId)
      .collection('messages');

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) => _messages(chatId)
      .orderBy('createdAt')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList());

  @override
  Stream<List<ChatSummary>> watchChats() => _db
      .collection('users')
      .doc(uid)
      .collection('chats')
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) {
            final m = d.data();
            return ChatSummary(
              documentId: (m['documentId'] ?? d.id) as String,
              documentName: (m['documentName'] ?? 'Document') as String,
              lastMessage: (m['lastMessage'] ?? '') as String,
              updatedAt:
                  (m['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList());

  @override
  Future<void> addMessage(String chatId, ChatMessage message,
      {String? documentName}) async {
    final chatRef =
        _db.collection('users').doc(uid).collection('chats').doc(chatId);
    await chatRef.set({
      'documentId': chatId,
      'documentName': documentName,
      'lastMessage': message.text,
      'updatedAt': Timestamp.fromDate(message.createdAt),
    }, SetOptions(merge: true));
    await _messages(chatId).add(message.toMap());
  }

  @override
  Future<void> incrementQuestionCount() => _db
      .collection('users')
      .doc(uid)
      .set({'questionCount': FieldValue.increment(1)}, SetOptions(merge: true));
}

import 'dart:async';

import 'chat_repository.dart';
import 'models/chat_message.dart';

/// In-memory ChatRepository for DEMO mode and tests.
class DemoChatRepository implements ChatRepository {
  final _store = <String, List<ChatMessage>>{};
  final _controllers = <String, StreamController<List<ChatMessage>>>{};
  final _summaries = <String, ChatSummary>{};
  final _summaryCtrl = StreamController<List<ChatSummary>>.broadcast();

  StreamController<List<ChatMessage>> _ctrl(String chatId) =>
      _controllers.putIfAbsent(
          chatId, () => StreamController<List<ChatMessage>>.broadcast());

  List<ChatSummary> get _sortedSummaries {
    final list = _summaries.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(list);
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) async* {
    yield List.unmodifiable(_store[chatId] ?? const []);
    yield* _ctrl(chatId).stream;
  }

  @override
  Stream<List<ChatSummary>> watchChats() async* {
    yield _sortedSummaries;
    yield* _summaryCtrl.stream;
  }

  @override
  Future<void> addMessage(String chatId, ChatMessage message,
      {String? documentName}) async {
    final list = _store.putIfAbsent(chatId, () => []);
    list.add(message);
    _ctrl(chatId).add(List.unmodifiable(list));

    _summaries[chatId] = ChatSummary(
      documentId: chatId,
      documentName: documentName ?? _summaries[chatId]?.documentName ?? 'Document',
      lastMessage: message.text,
      updatedAt: message.createdAt,
    );
    _summaryCtrl.add(_sortedSummaries);
  }

  @override
  Future<void> incrementQuestionCount() async {}

  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
    _summaryCtrl.close();
  }
}

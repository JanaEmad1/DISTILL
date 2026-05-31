import 'package:distill/features/chat/data/demo_chat_repository.dart';
import 'package:distill/features/chat/data/models/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures.dart';

void main() {
  late DemoChatRepository repo;

  setUp(() => repo = DemoChatRepository());
  tearDown(() => repo.dispose());

  test('watchMessages starts empty for an unknown chat', () async {
    expect(await repo.watchMessages('nope').first, isEmpty);
  });

  test('addMessage appends and is observable via watchMessages', () async {
    await repo.addMessage('doc-1', Fixtures.message(text: 'first'),
        documentName: 'Report.pdf');
    await repo.addMessage('doc-1', Fixtures.message(id: 'm-2', text: 'second'));

    final messages = await repo.watchMessages('doc-1').first;
    expect(messages.map((m) => m.text), ['first', 'second']);
  });

  group('watchChats summaries', () {
    test('records one summary per chat with the latest message', () async {
      await repo.addMessage('doc-1', Fixtures.message(text: 'hi'),
          documentName: 'Report.pdf');
      await repo.addMessage('doc-1', Fixtures.message(id: 'm-2', text: 'bye'));

      final chats = await repo.watchChats().first;
      expect(chats, hasLength(1));
      expect(chats.single.documentId, 'doc-1');
      expect(chats.single.documentName, 'Report.pdf');
      expect(chats.single.lastMessage, 'bye');
    });

    test('orders chats by most recently updated first', () async {
      await repo.addMessage('doc-old', _msgAt('old', DateTime(2026, 1, 1)),
          documentName: 'Old');
      await repo.addMessage('doc-new', _msgAt('new', DateTime(2026, 2, 1)),
          documentName: 'New');

      final chats = await repo.watchChats().first;
      expect(chats.map((c) => c.documentId), ['doc-new', 'doc-old']);
    });
  });
}

ChatMessage _msgAt(String text, DateTime when) =>
    ChatMessage(id: text, isUser: true, text: text, createdAt: when);

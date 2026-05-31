import 'package:distill/features/chat/data/models/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fixtures.dart';

void main() {
  group('Citation', () {
    test('toMap/fromMap roundtrips with and without a page', () {
      const withPage = Citation(quote: 'a quote', page: 7);
      final r1 = Citation.fromMap(withPage.toMap());
      expect(r1.quote, 'a quote');
      expect(r1.page, 7);

      const noPage = Citation(quote: 'no page');
      final r2 = Citation.fromMap(noPage.toMap());
      expect(r2.page, isNull);
    });
  });

  group('ChatMessage', () {
    test('toMap/fromMap roundtrips core fields', () {
      final msg = Fixtures.message(
        isUser: false,
        text: 'an answer',
        citations: const [Citation(quote: 'cited', page: 2)],
      );
      final restored = ChatMessage.fromMap(msg.id, msg.toMap());

      expect(restored.id, msg.id);
      expect(restored.isUser, isFalse);
      expect(restored.text, 'an answer');
      expect(restored.citations, hasLength(1));
      expect(restored.citations.first.page, 2);
      expect(restored.createdAt, msg.createdAt);
    });

    test('pending defaults to false after deserialization', () {
      final msg = Fixtures.message(pending: true);
      final restored = ChatMessage.fromMap(msg.id, msg.toMap());
      expect(restored.pending, isFalse);
    });

    test('copyWith updates text and pending while keeping id', () {
      final msg = Fixtures.message(text: '', pending: true);
      final done = msg.copyWith(text: 'streamed reply', pending: false);
      expect(done.id, msg.id);
      expect(done.text, 'streamed reply');
      expect(done.pending, isFalse);
    });
  });
}

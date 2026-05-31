import 'package:distill/core/ai/ai_service.dart';
import 'package:distill/core/ai/stub_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ai = StubAiService();

  group('StubAiService.summarize', () {
    test('returns a non-empty summary and key points', () async {
      final result = await ai.summarize('one two three four five');
      expect(result.summary, isNotEmpty);
      expect(result.keyPoints, isNotEmpty);
    });

    test('reflects the approximate word count in the summary', () async {
      final result = await ai.summarize('alpha beta gamma');
      expect(result.summary, contains('3 words'));
    });

    test('includes the title when provided', () async {
      final result = await ai.summarize('body text', title: 'My Doc');
      expect(result.summary, contains('My Doc'));
    });
  });

  group('StubAiService.answer', () {
    test('streams chunks that reassemble into a reply mentioning the question',
        () async {
      final buffer = StringBuffer();
      await for (final chunk in ai.answer(
          question: 'Why is the sky blue?', context: 'some context')) {
        buffer.write(chunk);
      }
      final reply = buffer.toString();
      expect(reply, isNotEmpty);
      expect(reply, contains('Why is the sky blue?'));
    });

    test('emits more than one chunk (token-style streaming)', () async {
      final chunks = await ai
          .answer(question: 'Q', context: 'c', history: const <ChatTurn>[])
          .toList();
      expect(chunks.length, greaterThan(1));
    });
  });
}

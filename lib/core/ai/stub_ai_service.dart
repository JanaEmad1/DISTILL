import 'ai_service.dart';

/// Offline AiService that returns deterministic canned content. Lets the full
/// app run and be demoed when Firebase AI Logic isn't configured, and backs the
/// unit tests. Selected automatically when the Gemini backend is unavailable.
class StubAiService implements AiService {
  const StubAiService();

  @override
  Future<SummaryResult> summarize(String text, {String? title}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final preview = words.take(40).join(' ');
    return SummaryResult(
      summary:
          'This document${title != null ? ' ("$title")' : ''} contains roughly '
          '${words.length} words. Here is a representative excerpt to give you a '
          'sense of its contents: "$preview..."\n\n(AI summaries are running in '
          'offline demo mode. Connect Firebase AI Logic to generate real, '
          'document-specific summaries.)',
      keyPoints: const [
        'Offline demo summary — connect Gemini for real insights',
        'The full document text was extracted successfully',
        'Open the chat to ask questions about this document',
      ],
    );
  }

  @override
  Stream<String> answer({
    required String question,
    required String context,
    List<ChatTurn> history = const [],
  }) async* {
    final reply =
        "I'm running in offline demo mode, so I can't read this document yet. "
        "Once Firebase AI Logic is connected I'll answer questions like "
        '"$question" using the document\'s content.';
    for (final word in reply.split(' ')) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
      yield '$word ';
    }
  }
}

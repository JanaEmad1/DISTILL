/// Result of summarizing a document: a prose summary plus extracted key points.
class SummaryResult {
  const SummaryResult({required this.summary, required this.keyPoints});

  final String summary;
  final List<String> keyPoints;
}

/// A single turn in a chat, used to give the model conversational context.
class ChatTurn {
  const ChatTurn({required this.isUser, required this.text});
  final bool isUser;
  final String text;
}

/// Abstraction over the LLM. Implemented by [GeminiAiService] (Firebase AI
/// Logic) and [StubAiService] (offline canned responses). UI and repositories
/// depend on this interface, never on a concrete provider.
abstract interface class AiService {
  /// Summarize [text] (the extracted document content) into prose + key points.
  Future<SummaryResult> summarize(String text, {String? title});

  /// Stream an answer to [question], grounded in document [context] and prior
  /// conversation [history].
  Stream<String> answer({
    required String question,
    required String context,
    List<ChatTurn> history,
  });
}

class AiException implements Exception {
  AiException(this.message);
  final String message;
  @override
  String toString() => 'AiException: $message';
}

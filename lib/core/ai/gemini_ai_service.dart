import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../constants.dart';
import 'ai_service.dart';

/// AiService backed by Firebase AI Logic (Vertex AI Gemini API path).
///
/// The API key lives in the Firebase project, never in the app bundle, and
/// requests are protected by App Check. Uses gemini-2.0-flash for low latency.
/// Vertex backend is used so requests bill against the project's Cloud Billing
/// (paid/trial) quota rather than the Developer API free tier, which returns
/// limit: 0 in the EU region.
class GeminiAiService implements AiService {
  GeminiAiService()
      : _summaryModel = FirebaseAI.vertexAI().generativeModel(
          model: 'gemini-2.5-flash',
          // Structured output: force a valid JSON object so the summary and key
          // points are always parsed cleanly (raw-newline replies used to break
          // jsonDecode and collapse the key points into the summary, esp. TXT).
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            responseSchema: Schema.object(
              properties: {
                'summary': Schema.string(),
                'keyPoints': Schema.array(items: Schema.string()),
              },
            ),
          ),
        ),
        _chatModel = FirebaseAI.vertexAI().generativeModel(
          model: 'gemini-2.5-flash',
        );

  /// JSON-structured model for one-shot summaries.
  final GenerativeModel _summaryModel;

  /// Plain-text streaming model for document chat.
  final GenerativeModel _chatModel;

  String _clip(String text) => text.length > AppConstants.maxContextChars
      ? text.substring(0, AppConstants.maxContextChars)
      : text;

  @override
  Future<SummaryResult> summarize(String text, {String? title}) async {
    final prompt = '''
You are Distill, an assistant that helps people read less and understand more.
Summarize the document below${title != null ? ' titled "$title"' : ''}.

Respond with ONLY valid JSON in this exact shape, no markdown fences:
{"summary": "<2-3 paragraph prose summary>", "keyPoints": ["<point>", "..."]}

Provide 3-6 concise key points. Document:
"""
${_clip(text)}
"""''';

    try {
      final res = await _summaryModel.generateContent([Content.text(prompt)]);
      final raw = res.text;
      if (raw == null || raw.trim().isEmpty) {
        throw AiException('The model returned an empty summary.');
      }
      return _parseSummary(raw);
    } on AiException {
      rethrow;
    } catch (e) {
      throw AiException('Could not generate a summary: $e');
    }
  }

  SummaryResult _parseSummary(String raw) {
    // Strip any accidental markdown fences before decoding.
    var cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'^```(json)?'), '').trim();
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3).trim();
      }
    }
    try {
      final map = jsonDecode(cleaned) as Map<String, dynamic>;
      return SummaryResult(
        summary: (map['summary'] as String?)?.trim() ?? cleaned,
        keyPoints: (map['keyPoints'] as List?)
                ?.map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList() ??
            const [],
      );
    } catch (_) {
      // Model didn't return clean JSON — fall back to the raw prose.
      return SummaryResult(summary: cleaned, keyPoints: const []);
    }
  }

  @override
  Stream<String> answer({
    required String question,
    required String context,
    List<ChatTurn> history = const [],
  }) async* {
    final historyText = history
        .map((t) => '${t.isUser ? 'User' : 'Assistant'}: ${t.text}')
        .join('\n');

    final prompt = '''
You are Distill, answering questions about a specific document. Use ONLY the
document content below. If the answer is not present, say so honestly. Be
concise and cite page or section when the document makes it possible.

DOCUMENT:
"""
${_clip(context)}
"""

${historyText.isEmpty ? '' : 'CONVERSATION SO FAR:\n$historyText\n'}
USER QUESTION: $question''';

    try {
      final stream = _chatModel.generateContentStream([Content.text(prompt)]);
      await for (final chunk in stream) {
        final t = chunk.text;
        if (t != null && t.isNotEmpty) yield t;
      }
    } catch (e) {
      throw AiException('Could not answer that question: $e');
    }
  }
}

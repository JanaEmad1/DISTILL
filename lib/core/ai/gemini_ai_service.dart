import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../constants.dart';
import 'ai_service.dart';

/// AiService backed by Firebase AI Logic (Gemini Developer API path).
///
/// The API key lives in the Firebase project, never in the app bundle, and
/// requests are protected by App Check. Uses gemini-2.0-flash for low latency
/// and free-tier friendliness.
class GeminiAiService implements AiService {
  GeminiAiService()
      : _model = FirebaseAI.googleAI().generativeModel(
          model: 'gemini-2.0-flash',
        );

  final GenerativeModel _model;

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
      final res = await _model.generateContent([Content.text(prompt)]);
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
      final stream = _model.generateContentStream([Content.text(prompt)]);
      await for (final chunk in stream) {
        final t = chunk.text;
        if (t != null && t.isNotEmpty) yield t;
      }
    } catch (e) {
      throw AiException('Could not answer that question: $e');
    }
  }
}

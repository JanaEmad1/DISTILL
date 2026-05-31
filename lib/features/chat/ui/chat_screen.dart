import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/ai/ai_service.dart';
import '../../../core/di/providers.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/ai_badge.dart';
import '../data/models/chat_message.dart';
import 'widgets/message_bubble.dart';

/// Conversational Q&A grounded in a single document. Persisted messages come
/// from [chatMessagesProvider]; the in-flight AI reply streams into local state
/// and is persisted once complete.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.documentId});
  final String documentId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  ChatMessage? _streaming;
  bool _responding = false;

  static const _suggestions = [
    'Summarize this in one sentence',
    'What are the main takeaways?',
    'Explain it simply',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send(String text) async {
    final q = text.trim();
    if (q.isEmpty || _responding) return;
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;

    _input.clear();
    final doc = ref.read(documentByIdProvider(widget.documentId)).value;
    final docName = doc?.name ?? '';
    final docContext = (doc?.extractedText.isNotEmpty ?? false)
        ? doc!.extractedText
        : (doc?.summary ?? '');

    final history = (ref.read(chatMessagesProvider(widget.documentId)).value ??
            const <ChatMessage>[])
        .map((m) => ChatTurn(isUser: m.isUser, text: m.text))
        .toList();

    final ts = DateTime.now();
    await repo.addMessage(
      widget.documentId,
      ChatMessage(
          id: 'u-${ts.microsecondsSinceEpoch}',
          isUser: true,
          text: q,
          createdAt: ts),
      documentName: docName,
    );
    // ignore: unawaited_futures
    repo.incrementQuestionCount();

    setState(() {
      _responding = true;
      _streaming = ChatMessage(
          id: 'stream',
          isUser: false,
          text: '',
          createdAt: DateTime.now(),
          pending: true);
    });
    _scrollToEnd();

    final ai = ref.read(aiServiceProvider);
    final buffer = StringBuffer();
    try {
      await for (final chunk in ai.answer(
          question: q, context: docContext, history: history)) {
        buffer.write(chunk);
        if (!mounted) return;
        setState(() => _streaming = _streaming?.copyWith(text: buffer.toString()));
        _scrollToEnd();
      }
    } catch (_) {
      if (buffer.isEmpty) {
        buffer.write('Sorry — I ran into a problem answering that. '
            'Please try again.');
      }
    }

    await repo.addMessage(
      widget.documentId,
      ChatMessage(
          id: 'a-${ts.microsecondsSinceEpoch}',
          isUser: false,
          text: buffer.toString(),
          createdAt: DateTime.now()),
      documentName: docName,
    );
    if (!mounted) return;
    setState(() {
      _responding = false;
      _streaming = null;
    });
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final persisted =
        ref.watch(chatMessagesProvider(widget.documentId)).value ??
            const <ChatMessage>[];
    final doc = ref.watch(documentByIdProvider(widget.documentId)).value;
    final messages = [
      ...persisted,
      ?_streaming,
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/chats'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doc?.name ?? 'Document chat',
                style: context.text.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const AiBadge(label: 'Grounded in your document'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _EmptyChat(suggestions: _suggestions, onPick: _send)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: messages.length,
                    itemBuilder: (_, i) =>
                        MessageBubble(message: messages[i]),
                  ),
          ),
          if (messages.isNotEmpty)
            _SuggestionRow(suggestions: _suggestions, onPick: _send),
          _Composer(
            controller: _input,
            enabled: !_responding,
            onSend: () => _send(_input.text),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.suggestions, required this.onPick});
  final List<String> suggestions;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.auto_awesome,
                size: 48, fill: 1, color: context.colors.secondary),
            const SizedBox(height: AppSpacing.lg),
            Text('Ask anything about this document',
                style: context.text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text('Answers are grounded in the content you uploaded.',
                style: context.text.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final s in suggestions)
                  ActionChip(label: Text(s), onPressed: () => onPick(s)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestions, required this.onPick});
  final List<String> suggestions;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          for (final s in suggestions)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ActionChip(label: Text(s), onPressed: () => onPick(s)),
            ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(hintText: 'Ask a question…'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Symbols.send, fill: 1),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/chat_message.dart';

/// A single chat row. User messages are right-aligned filled bubbles; AI
/// messages are left-aligned with an optional set of citation cards.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor =
        isUser ? context.colors.primary : context.colors.surfaceContainerHigh;
    final textColor =
        isUser ? context.colors.onPrimary : context.colors.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: align,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.lg),
                  topRight: const Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(isUser ? AppRadius.lg : AppRadius.sm),
                  bottomRight:
                      Radius.circular(isUser ? AppRadius.sm : AppRadius.lg),
                ),
              ),
              child: message.pending && message.text.isEmpty
                  ? const _TypingDots()
                  : Text(
                      message.text,
                      style: context.text.bodyLarge
                          ?.copyWith(color: textColor, height: 1.4),
                    ),
            ),
          ),
          if (message.citations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final c in message.citations) _CitationCard(citation: c),
          ],
        ],
      ),
    );
  }
}

class _CitationCard extends StatelessWidget {
  const _CitationCard({required this.citation});
  final Citation citation;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.secondaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border(
            left: BorderSide(color: context.colors.secondary, width: 3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Symbols.format_quote,
                size: 16, color: context.colors.secondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"${citation.quote}"',
                      style: context.text.bodyMedium
                          ?.copyWith(fontStyle: FontStyle.italic)),
                  if (citation.page != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text('Page ${citation.page}',
                        style: context.text.labelSmall?.copyWith(
                            color: context.colors.secondary,
                            fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three pulsing dots shown while the AI reply is still being generated.
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 16,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_c.value + i * 0.2) % 1.0;
              final opacity = 0.3 + 0.7 * (1 - (t - 0.5).abs() * 2);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Opacity(
                  opacity: opacity.clamp(0.3, 1.0),
                  child: CircleAvatar(
                      radius: 4, backgroundColor: context.colors.onSurfaceVariant),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ai_badge.dart';
import '../../data/models/document_model.dart';

/// A document row card: type icon, name, AI status, summary snippet, and meta.
class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.doc,
    required this.onTap,
    this.onMore,
  });

  final DocumentModel doc;
  final VoidCallback onTap;
  final VoidCallback? onMore;

  IconData get _typeIcon => switch (doc.type) {
        'pdf' => Symbols.picture_as_pdf,
        'docx' => Symbols.description,
        _ => Symbols.text_snippet,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      context.colors.primaryContainer.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(_typeIcon, color: context.colors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(doc.name,
                              style: context.text.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (doc.favorite)
                          Icon(Symbols.star,
                              size: 18,
                              fill: 1,
                              color: context.colors.secondary),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _statusLine(context),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      doc.summary ?? 'Awaiting summary…',
                      style: context.text.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _metaLine(context),
                  ],
                ),
              ),
              if (onMore != null)
                IconButton(
                  icon: const Icon(Symbols.more_vert, size: 20),
                  onPressed: onMore,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusLine(BuildContext context) {
    if (doc.isReady) return const AiBadge(label: 'Summarized');
    if (doc.status == DocStatus.error) {
      return Row(children: [
        Icon(Symbols.error, size: 16, color: context.colors.error),
        const SizedBox(width: AppSpacing.xs),
        Text('Failed to process',
            style: context.text.labelMedium
                ?.copyWith(color: context.colors.error)),
      ]);
    }
    return Row(children: [
      _PulsingDot(color: context.colors.secondary),
      const SizedBox(width: AppSpacing.sm),
      Text('Processing AI insights…',
          style: context.text.labelMedium
              ?.copyWith(color: context.colors.secondary)),
    ]);
  }

  Widget _metaLine(BuildContext context) {
    return Row(
      children: [
        _Chip(label: doc.type.toUpperCase()),
        const SizedBox(width: AppSpacing.sm),
        Text('· ${doc.sizeBytes.readableSize} · ${doc.updatedAt.relative}',
            style: context.text.labelMedium),
      ],
    );
  }
}

/// A small dot that softly pulses its opacity — a calmer "in progress" cue
/// than a spinning indicator. Owns and disposes its own controller.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(label,
          style: context.text.labelSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

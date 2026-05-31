import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Live "Analyzing your document" screen. Reflects pipeline progress streamed
/// from Realtime Database and auto-advances to the detail screen when ready.
class ProcessingScreen extends ConsumerWidget {
  const ProcessingScreen({super.key, required this.documentId});
  final String documentId;

  static const _steps = [
    (DocStatus.uploading, 'Uploaded successfully'),
    (DocStatus.extracting, 'Extracted text'),
    (DocStatus.summarizing, 'Generating AI summary'),
    (DocStatus.ready, 'Preparing for questions'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(processingProgressProvider(documentId)).value;
    final doc = ref.watch(documentByIdProvider(documentId)).value;
    final status = progress?.status ?? doc?.status ?? DocStatus.uploading;
    final percent = progress?.percent ?? 0;

    // Auto-navigate when ready.
    ref.listen(documentByIdProvider(documentId), (_, next) {
      if (next.value?.status == DocStatus.ready && context.mounted) {
        context.pushReplacement('/document/$documentId');
      }
    });

    final stepIndex = _steps.indexWhere((s) => s.$1 == status);
    final activeIndex = status == DocStatus.ready ? _steps.length : stepIndex;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Symbols.close),
                  onPressed: () => context.go('/home'),
                ),
              ),
              const Spacer(),
              Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  // Fixed brand gradient (not theme colors) so the white sparkle
                  // always has enough contrast in both light and dark themes.
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
                ),
                child: const Icon(Symbols.auto_awesome,
                    size: 64, color: Colors.white, fill: 1),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text('Analyzing your document',
                  style: context.text.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text('This usually takes 10-30 seconds',
                  style: context.text.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              if (doc != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Symbols.description, size: 16),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                          child: Text(doc.name,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.labelMedium)),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xxxl),
              ..._steps.asMap().entries.map((e) => _StepRow(
                    label: e.value.$2,
                    done: e.key < activeIndex,
                    active: e.key == activeIndex,
                  )),
              const Spacer(),
              if (status == DocStatus.error)
                _ErrorState(onRetry: () => context.go('/home'))
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('$percent%',
                        style: context.text.titleMedium
                            ?.copyWith(color: context.colors.primary)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 8,
                    backgroundColor: context.colors.surfaceContainerHigh,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Continue in background'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow(
      {required this.label, required this.done, required this.active});
  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Widget leading;
    if (done) {
      color = context.colors.secondary;
      leading = Icon(Symbols.check_circle, fill: 1, color: color);
    } else if (active) {
      color = context.colors.primary;
      leading = SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
      );
    } else {
      color = context.colors.outline;
      leading = Icon(Symbols.circle, color: context.colors.outlineVariant);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          leading,
          const SizedBox(width: AppSpacing.md),
          Text(label,
              style: context.text.bodyLarge?.copyWith(
                color: active ? context.colors.onSurface : color,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              )),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Symbols.error, color: context.colors.error, size: 40),
        const SizedBox(height: AppSpacing.sm),
        Text('We couldn’t process this document.',
            style: context.text.bodyLarge, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(onPressed: onRetry, child: const Text('Back to home')),
      ],
    );
  }
}

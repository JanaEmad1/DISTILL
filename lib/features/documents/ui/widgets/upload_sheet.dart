import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/services/file_service.dart';
import '../../../../shared/widgets/ai_badge.dart';

/// Confirmation bottom sheet shown right after a file is picked. Returns `true`
/// when the user taps "Summarize", and `false`/`null` on cancel.
Future<bool?> showUploadConfirmSheet(
  BuildContext context,
  PickedDocument file,
) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _UploadConfirmSheet(file: file),
  );
}

class _UploadConfirmSheet extends StatelessWidget {
  const _UploadConfirmSheet({required this.file});
  final PickedDocument file;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Upload document', style: context.text.titleLarge),
                const Spacer(),
                const AiBadge(),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(Symbols.description, color: context.colors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(file.name,
                            style: context.text.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(
                          '${file.type.toUpperCase()} · '
                          '${file.sizeBytes.readableSize}',
                          style: context.text.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Symbols.auto_awesome,
                    size: 18, color: context.colors.secondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'AI will read this and generate a summary and key points, '
                    'then let you chat with the document.',
                    style: context.text.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Symbols.auto_awesome, fill: 1),
              label: const Text('Summarize'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

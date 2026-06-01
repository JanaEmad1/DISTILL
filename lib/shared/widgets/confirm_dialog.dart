import 'package:flutter/material.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_spacing.dart';

/// A reusable confirmation dialog with two equal-width buttons laid out side by
/// side (Cancel | confirm) — avoids Material's default action overflow that
/// stacks a right-aligned Cancel above a full-width button.
///
/// Returns `true` only if the user taps the confirm button; `false` on cancel
/// or dismiss. Set [destructive] to render the confirm button in the error
/// color (e.g. for deletes).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = 'Cancel',
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(cancelLabel),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: ctx.colors.error,
                        foregroundColor: ctx.colors.onError,
                      )
                    : null,
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(confirmLabel),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}

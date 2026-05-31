import 'package:flutter/material.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_spacing.dart';
import 'google_logo.dart';

/// "Continue with Google" button following Google's standard sign-in styling:
/// a neutral surface background, a thin outline, the real multi-color "G", and
/// a neutral label. Reads correctly in both light and dark themes.
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: context.colors.surfaceContainerLowest,
        foregroundColor: context.colors.onSurface,
        side: BorderSide(color: context.colors.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      icon: const GoogleLogo(),
      label: Text('Continue with Google', style: context.text.labelLarge),
    );
  }
}

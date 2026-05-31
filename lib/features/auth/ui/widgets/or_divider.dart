import 'package:flutter/material.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_spacing.dart';

/// A horizontal "OR" divider used to separate primary auth from Google sign-in.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    Widget line() =>
        Expanded(child: Divider(color: context.colors.outlineVariant));
    return Row(
      children: [
        line(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('OR', style: context.text.labelMedium),
        ),
        line(),
      ],
    );
  }
}

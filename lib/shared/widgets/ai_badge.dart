import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_spacing.dart';

/// The ✦ sparkle signature that marks any AI-powered feature or insight.
class AiBadge extends StatelessWidget {
  const AiBadge({super.key, this.label, this.color});

  final String? label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.secondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Symbols.auto_awesome, size: 16, color: c, fill: 1),
        if (label != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            label!,
            style: context.text.labelMedium?.copyWith(
              color: c,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

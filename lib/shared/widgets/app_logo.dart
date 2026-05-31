import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/extensions/context_ext.dart';

/// The Distill mark: a rounded document glyph in a circle, used on splash,
/// auth headers, and the app bar.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 40,
    this.onPrimary = false,
  });

  final double size;

  /// When true, renders white-on-navy (splash); otherwise navy-on-light.
  final bool onPrimary;

  @override
  Widget build(BuildContext context) {
    final bg = onPrimary ? Colors.white : context.colors.primary;
    final fg = onPrimary ? context.colors.primary : context.colors.onPrimary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(Symbols.description, color: fg, size: size * 0.5, weight: 600),
    );
  }
}

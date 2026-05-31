import 'package:flutter/material.dart';

/// Distill color tokens — single source of truth, derived from the
/// "Premium Document Intelligence" design system (design/DESIGN (2).md).
///
/// Deep navy primary establishes authority; sky-blue secondary highlights
/// AI-driven features. Never hardcode Color(0xFF..) in widgets — reference here.
abstract final class AppColors {
  // ---- Light palette ----
  static const surface = Color(0xFFFAF8FF);
  static const surfaceDim = Color(0xFFDAD9E1);
  static const surfaceBright = Color(0xFFFAF8FF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF4F3FA);
  static const surfaceContainer = Color(0xFFEEEDF4);
  static const surfaceContainerHigh = Color(0xFFE9E7EF);
  static const surfaceContainerHighest = Color(0xFFE3E1E9);
  static const onSurface = Color(0xFF1A1B21);
  static const onSurfaceVariant = Color(0xFF444651);
  static const inverseSurface = Color(0xFF2F3036);
  static const inverseOnSurface = Color(0xFFF1F0F7);
  static const outline = Color(0xFF757682);
  static const outlineVariant = Color(0xFFC5C5D3);
  static const surfaceTint = Color(0xFF4059AA);

  static const primary = Color(0xFF00236F);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF1E3A8A);
  static const onPrimaryContainer = Color(0xFF90A8FF);
  static const inversePrimary = Color(0xFFB6C4FF);

  static const secondary = Color(0xFF006591);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF39B8FD);
  static const onSecondaryContainer = Color(0xFF004666);

  static const tertiary = Color(0xFF4B1C00);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF6E2C00);
  static const onTertiaryContainer = Color(0xFFF39461);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const background = Color(0xFFFAF8FF);
  static const onBackground = Color(0xFF1A1B21);

  /// Sky-blue accent used for the AI sparkle (✦) signature.
  static const aiAccent = Color(0xFF39B8FD);

  /// Subtle level-1 elevation outline for cards/inputs.
  static const cardOutline = Color(0xFFC5C5D3);

  // ---- Dark palette ("digital study" surface, softer & lifted for comfort:
  // surfaces sit off pure-dark, text is a soft off-white not stark white) ----
  static const dSurface = Color(0xFF181D2A);
  static const dSurfaceContainerLowest = Color(0xFF12161F);
  static const dSurfaceContainerLow = Color(0xFF1D222E);
  static const dSurfaceContainer = Color(0xFF222734);
  static const dSurfaceContainerHigh = Color(0xFF2A2F3D);
  static const dSurfaceContainerHighest = Color(0xFF333949);
  static const dOnSurface = Color(0xFFE2E5ED);
  static const dOnSurfaceVariant = Color(0xFFAAB0BF);
  static const dOutline = Color(0xFF5A6072);
  static const dOutlineVariant = Color(0xFF333949);
  static const dPrimary = Color(0xFFB6C4FF);
  static const dOnPrimary = Color(0xFF002B73);
  static const dPrimaryContainer = Color(0xFF1E3A8A);
  static const dOnPrimaryContainer = Color(0xFFDCE1FF);
  static const dSecondary = Color(0xFF89CEFF);
  static const dOnSecondary = Color(0xFF003450);
  static const dSecondaryContainer = Color(0xFF004C6E);
  static const dOnSecondaryContainer = Color(0xFFC9E6FF);
  static const dError = Color(0xFFFFB4AB);
  static const dOnError = Color(0xFF690005);
  static const dErrorContainer = Color(0xFF93000A);
}

/// 4/8px baseline spacing grid and radius scale from the design system.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16; // standard mobile side margin
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Gutter between list/grid items on narrow screens.
  static const double gutter = 12;
}

/// Corner radius scale. Cards/buttons/inputs = md; thumbnails/sheets = lg;
/// FAB/search bars = xl (emphasis).
abstract final class AppRadius {
  static const double sm = 4;
  static const double base = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 9999;
}

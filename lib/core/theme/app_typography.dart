import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Inter type scale from the design system. Body-large uses a 1.5x line
/// height, optimized for extended document reading.
abstract final class AppTypography {
  static TextTheme textTheme(Color onSurface, Color onSurfaceVariant) {
    // Recolor EVERY style up front. GoogleFonts.interTextTheme() ships with the
    // near-black default colors baked in; styles we don't explicitly override
    // below (e.g. headlineSmall, titleSmall, bodySmall) would otherwise stay
    // black and vanish on the dark surface. .apply() fixes all of them at once.
    final base = GoogleFonts.interTextTheme()
        .apply(bodyColor: onSurface, displayColor: onSurface);
    return base.copyWith(
      // Display — anchors page sections.
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        color: onSurface,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
        color: onSurface,
        letterSpacing: -0.25,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 24 / 18,
        color: onSurface,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 24 / 16,
        color: onSurface,
      ),
      // Body-large — the workhorse for document text.
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: onSurfaceVariant,
      ),
      // Label — slightly heavier for legibility at small sizes.
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        color: onSurface,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        color: onSurfaceVariant,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 16 / 11,
        color: onSurfaceVariant,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        color: onSurfaceVariant,
      ),
    );
  }
}

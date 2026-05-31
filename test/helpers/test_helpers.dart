import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pump a widget wrapped in ProviderScope + MaterialApp + Scaffold. Uses a
/// plain Material 3 theme (not the google_fonts-backed AppTheme) so widget
/// tests stay offline and fast while still providing a ColorScheme + TextTheme.
extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget widget) {
    return pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(body: widget),
        ),
      ),
    );
  }
}

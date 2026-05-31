import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

/// Persists the user's theme preference (system/light/dark) in
/// SharedPreferences and exposes it as ThemeMode.
class ThemeController extends Notifier<ThemeMode> {
  SharedPreferences? _prefs;

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs?.getString(AppConstants.prefThemeMode);
    state = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(AppConstants.prefThemeMode, mode.name);
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);

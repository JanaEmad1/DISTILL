import 'package:flutter/material.dart';

extension ContextX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  void showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? colors.error : null,
        ),
      );
  }
}

extension FileSizeX on int {
  /// Human-readable byte size, e.g. "4.2 MB".
  String get readableSize {
    if (this < 1024) return '$this B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(0)} KB';
    return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

extension RelativeTimeX on DateTime {
  /// e.g. "2 days ago", "1 week ago".
  String get relative {
    final diff = DateTime.now().difference(this);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    final weeks = (diff.inDays / 7).floor();
    if (weeks < 4) return '$weeks week${weeks == 1 ? '' : 's'} ago';
    final months = (diff.inDays / 30).floor();
    return '$months month${months == 1 ? '' : 's'} ago';
  }
}

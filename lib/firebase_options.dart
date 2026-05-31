// PLACEHOLDER — replaced automatically when you run `flutterfire configure`.
//
// Until then these values are inert: main.dart only calls
// Firebase.initializeApp when kFirebaseConfigured (lib/core/app_config.dart)
// is true. Do not ship these placeholder values to production.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return _placeholder;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      default:
        return _placeholder;
    }
  }

  static const FirebaseOptions _placeholder = FirebaseOptions(
    apiKey: 'PLACEHOLDER_API_KEY',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'distill-placeholder',
    storageBucket: 'distill-placeholder.appspot.com',
  );
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/app_config.dart';
import 'core/di/providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The app runs fully in DEMO mode (in-memory data + stub AI) until a real
  // Firebase project is configured. See lib/core/app_config.dart.
  var firebaseReady = false;
  if (kFirebaseConfigured) {
    try {
      // On Android the native SDK auto-initializes the default app from
      // google-services.json, so a second initializeApp() throws
      // [core/duplicate-app]. (Firebase.apps can still read empty in Dart at
      // this point, so guarding on it isn't reliable.) Skip if an app already
      // exists; otherwise initialize (web).
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      firebaseReady = true;
    } on FirebaseException catch (e) {
      // duplicate-app means Firebase is already up natively — that's success.
      if (e.code == 'duplicate-app') {
        firebaseReady = true;
      } else {
        debugPrint('Firebase init failed; falling back to demo mode: $e');
      }
    } catch (e) {
      debugPrint('Firebase init failed; falling back to demo mode: $e');
    }
  }

  runApp(
    ProviderScope(
      overrides: [firebaseReadyProvider.overrideWithValue(firebaseReady)],
      child: const DistillApp(),
    ),
  );
}

/// Build-time configuration flags.
///
/// [kFirebaseConfigured] gates whether the app talks to a real Firebase
/// project or runs in self-contained DEMO mode (in-memory data + stub AI).
///
/// To go live:
///   1. Install the Firebase CLI:  npm install -g firebase-tools
///   2. Activate FlutterFire:      dart pub global activate flutterfire_cli
///   3. From the project root run:  flutterfire configure
///      (this regenerates lib/firebase_options.dart with your real project)
///   4. Flip this flag to `true` and hot-restart.
///
/// See FIREBASE_SETUP.md for the full walkthrough.
const bool kFirebaseConfigured = false;

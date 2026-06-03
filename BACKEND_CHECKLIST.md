# Distill — Backend (Firebase) Bring-Up Checklist

> Distill is **feature-complete and runs in DEMO mode** today
> (`kFirebaseConfigured = false` in [`lib/core/app_config.dart`](lib/core/app_config.dart)):
> in-memory data + a stub AI, 60 tests passing, `flutter analyze` clean.
>
> The backend itself is **already written** — `FirebaseAuthRepository`,
> `FirebaseDocumentRepository`, `FirebaseChatRepository`, `GeminiAiService`, and
> all three security-rule files exist and compile. There is **no remaining
> coding**. What's left is taking it **live on Firebase**, which needs your
> Google account + a browser, so it has to be done by you. Work top to bottom and
> tick items off. Full prose walkthrough: [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md).

---

## A. Firebase project + CLI setup

- [x] Create a Firebase project at <https://console.firebase.google.com>. *(project `distill-d0c18`)*
- [x] `npm install -g firebase-tools`
- [x] `dart pub global activate flutterfire_cli`
- [x] `firebase login`
- [x] From `distill/`: `flutterfire configure` → regenerated
      [`lib/firebase_options.dart`](lib/firebase_options.dart) and dropped the
      platform config files. *(Manually added the missing `databaseURL` to all
      three configs afterwards — see PROJECT_GUIDE §2.13.)*

## B. Platform config (created by `flutterfire configure` — verify they land)

- [x] Web Firebase init in place (`flutterfire configure` + `lib/firebase_options.dart`
      web config). **Web + Android both brought up and verified live.**
- [x] `android/app/google-services.json` present. Android verified live on the
      `Pixel_4_2` emulator after fixing the `[core/duplicate-app]` demo-mode
      fallback in `main.dart` + supplying the RTDB URL in `providers.dart` (see
      PROJECT_GUIDE §2.13).
- [ ] `ios/Runner/GoogleService-Info.plist` present. *(iOS not yet brought up/verified.)*
- [ ] **Google Sign-In extras** (NOT handled by `flutterfire configure`):
  - [ ] Android — add your app's **SHA-1 / SHA-256** debug + release
        fingerprints in the Firebase console (required for Google sign-in on
        Android).
  - [ ] iOS — add the **reversed client ID** URL scheme to `Info.plist`.
  - [x] **Web Google sign-in:** `google_sign_in` v7's interactive `authenticate()`
        is unsupported in the browser, so `signInWithGoogle()` now branches on
        `kIsWeb` and uses `FirebaseAuth.signInWithPopup(GoogleAuthProvider())` on
        web (native flow kept on mobile). No client-ID meta tag / `index.html`
        edit needed. See PROJECT_GUIDE §2.13.
  - [ ] Mobile: confirm the live Google flow returns a user on Android/iOS when tested.

## C. Enable backend services in the Firebase console

- [x] Authentication → enabled **Email/Password** and **Google**.
- [x] Firestore Database → created (production mode).
- [x] Realtime Database → created (`europe-west1`).
- [x] Cloud Storage → got started (on the **Blaze** free-trial plan). *Note: web
      uploads currently fail the browser CORS preflight; the app degrades
      gracefully (try/catch + 5s timeout) and proceeds Firestore-only. Cosmetic;
      see PROJECT_GUIDE §2.13.*
- [x] Firebase AI Logic (Gemini) → enabled. **Uses the Vertex AI backend**, NOT
      the Developer API: the EU Developer-API free tier is `limit: 0`, so
      [`gemini_ai_service.dart`](lib/core/ai/gemini_ai_service.dart) calls
      `FirebaseAI.vertexAI().generativeModel(model: 'gemini-2.5-flash')` and the
      **Vertex AI API** (`aiplatform.googleapis.com`) is enabled. See §2.13.
- [ ] *(Optional)* enable **App Check** to protect the AI/key — referenced in
      [`lib/core/ai/gemini_ai_service.dart`](lib/core/ai/gemini_ai_service.dart).

## D. Deploy security rules

- [x] Deployed Firestore + Realtime DB rules. *(Fixed a Realtime DB rules field
      mismatch `step → status` and redeployed — see §2.13.)*

## E. Go live

- [x] Set `kFirebaseConfigured = true` in
      [`lib/core/app_config.dart`](lib/core/app_config.dart).
- [x] Runs live via `flutter run -d chrome`. *(If Firebase init fails at runtime,
      `main.dart` auto-falls back to demo mode so the app still launches.)*

## F. Live verification (check in the Firebase console after the flip)

- [x] Sign up + sign in with **email** → creates an Auth user + `users/{uid}`
      profile doc. *(Verified on web **and** Android emulator — a fresh account
      starts empty, confirming live mode.)*
- [ ] Sign in with **Google** → returns a user, profile created. *(Code now
      web-ready via `signInWithPopup`; verify in the browser — see §2.13
      verification steps.)*
- [x] Upload a **TXT** → clean extracted text + full pipeline ran (verified on
      web and Android). On **Android the raw file uploads to Storage** (no CORS);
      on **web** Storage is CORS-blocked (cosmetic; §2.13). PDF/DOCX still worth a
      spot-check but the pipeline is proven.
- [x] Processing screen progress writes to Realtime DB `progress/{uid}/{docId}`.
      *(Confirmed `status: ready`, `percent: 100`.)*
- [x] Finished summary + key points saved to the Firestore document. *(Confirmed
      in `users/{uid}/documents/{docId}`.)*
- [x] Chat → streamed Gemini answer renders. *(Verified; messages persist.)*
- [ ] Stats increment (`docCount`, `questionCount`, `storageBytes`). *(Not yet
      hand-verified.)*
- [ ] **Security check** — confirm one user cannot read another user's
      `users/{uid}/**` data (rules deny by default). *(Not yet hand-verified.)*
- [ ] Delete a document → removes the Firestore doc, the Storage file, and the
      progress node. *(Not yet hand-verified live.)*

## G. Demo-mode items still worth closing (from PROJECT_GUIDE passes 4 & 5)

- [ ] Hand-verify the full flow on a device/emulator **and** Chrome (the
      automated tests pass but the UI was never driven live from the build env).
- [ ] Run the on-device integration test:
      `flutter test integration_test/app_test.dart`.
- [ ] Confirm pass-4/5 UX fixes on device: Copy/Share on a ready doc, Delete
      confirm dialog, mismatched-password block on sign-up, side-by-side dialog
      buttons, Processing screen no longer overflows on a short Chrome window.

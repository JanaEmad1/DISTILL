# Firebase setup

Distill ships in **DEMO mode** — it runs fully offline with in-memory data and a
stubbed AI so it can be graded and explored without any backend. To connect a
real Firebase project (Authentication, Firestore, Realtime Database, Cloud
Storage, and Gemini via Firebase AI Logic), follow the steps below.

The single switch that flips demo ↔ live is `kFirebaseConfigured` in
[`lib/core/app_config.dart`](lib/core/app_config.dart).

## Prerequisites

- A Google account and a Firebase project (create one at <https://console.firebase.google.com>).
- Node.js (for the Firebase CLI) and the Dart/Flutter SDK already installed.

## 1. Install the CLIs

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
```

## 2. Generate the Flutter config

From the project root (`distill/`):

```bash
flutterfire configure
```

Select your project and the platforms you target (Android / iOS / web). This
**overwrites** [`lib/firebase_options.dart`](lib/firebase_options.dart) with your
real project values (the committed file is an inert placeholder).

## 3. Enable the backend services in the Firebase console

- **Authentication** → Sign-in method → enable **Email/Password** and **Google**.
- **Firestore Database** → create database (production mode).
- **Realtime Database** → create database.
- **Cloud Storage** → get started. (Newly created projects may require the
  Blaze pay-as-you-go plan for Storage; it still includes a free allotment. If
  you must stay on Spark only, the app degrades gracefully — extracted text is
  kept in Firestore and raw-file Storage can be skipped.)
- **Firebase AI Logic** (Gemini) → enable it and pick the **Gemini Developer
  API** path (free tier, no server, key never ships in the app).

## 4. Deploy the security rules

The rules in this repo grant each user access to **only their own data**
(`users/{uid}/**`), with a 50MB / allowed-content-type cap on uploads. They are
wired up in [`firebase.json`](firebase.json):

- [`firestore.rules`](firestore.rules) — per-user `users/{uid}` tree (documents, folders, chats, messages).
- [`storage.rules`](storage.rules) — per-user files under `users/{uid}/documents/{docId}/...`.
- [`database.rules.json`](database.rules.json) — per-user processing progress at `progress/{uid}/{docId}`.

Deploy them:

```bash
firebase deploy --only firestore:rules,storage,database
```

## 5. Flip the flag and run

Set `kFirebaseConfigured = true` in
[`lib/core/app_config.dart`](lib/core/app_config.dart), then:

```bash
flutter run
```

The app now reads/writes live Firebase and uses Gemini for summaries and chat.
If Firebase initialization fails at runtime, `main.dart` automatically falls
back to demo mode so the app always launches.

## Data model (where each service is used)

| Service            | Path                                   | Purpose                                              |
| ------------------ | -------------------------------------- | ---------------------------------------------------- |
| Auth               | —                                      | Email/password + Google sign-in.                     |
| Firestore          | `users/{uid}`                          | Profile + stats (docCount, questionCount, storage).  |
| Firestore          | `users/{uid}/documents/{docId}`        | Document metadata, summary, key points, text.        |
| Firestore          | `users/{uid}/chats/{chatId}/messages`  | Per-document Q&A history.                             |
| Realtime Database  | `progress/{uid}/{docId}`               | Live `{ step, percent }` for the processing screen.  |
| Cloud Storage      | `users/{uid}/documents/{docId}/{file}` | The raw uploaded PDF/DOCX/TXT.                        |
| Firebase AI Logic  | —                                      | Gemini: `summarize()` and streamed `answer()`.       |

## Verifying

After a live run, confirm in the console that a sign-in creates an Auth user, an
upload writes a Storage file + a Firestore document, and the processing screen's
progress appears under the Realtime Database `progress/{uid}` node.

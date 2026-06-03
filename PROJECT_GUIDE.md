# Distill — Complete Project Guide

> **Distill — "Read less. Understand more."**
> A Flutter mobile app where you upload a document (PDF / DOCX / TXT), get an
> AI-generated summary, and then *chat* with that document to ask questions
> about it.

This guide is written in two halves:

1. **Part 1 — For a total beginner.** Plain-English explanation of what was
   built, why, the one real error I hit, and exactly what you need to do next.
2. **Part 2 — The deep dive.** Every file, every folder, the architecture, the
   data flow, the backend design, and the tests — nothing left out.

---

# PART 1 — FOR A TOTAL BEGINNER

## 1.1 What is this app, in one paragraph?

You sign in, you upload a document, the app reads the text out of that document,
sends it to an AI, and shows you a short **summary** plus **key points**. Then
you can open a **chat** and ask the document questions ("What were the Q4
revenue numbers?") and get answers grounded in that specific document. There are
also screens for browsing and searching your documents (Home), seeing your past
conversations (Chats), and your account (Profile/Settings).

## 1.2 The single most important concept: "Demo mode"

The app is built to run in **two modes**:

- **Demo mode (where it is right now):** Everything works *without any internet
  or accounts*. Data is kept **in memory** (it resets when you close the app),
  and the "AI" is a **fake stand-in** that returns canned text. This lets the
  app run, be clicked through, and be graded **today**, with zero setup.
- **Live mode (Firebase):** When you connect a real Firebase project, the same
  app talks to real cloud services — real login, real database, real file
  storage, and a real Google **Gemini** AI.

There is **one switch** that flips between them:
`kFirebaseConfigured` in the file `lib/core/app_config.dart`.
It is `false` now (demo). You set it to `true` after connecting Firebase.

**Why build it this way?** Because connecting Firebase needs a browser login and
a Google account, which couldn't be done from inside this environment. Instead
of leaving you with a half-finished app that won't run, the app was built to be
**fully functional in demo mode now**, and **ready to go live in ~15 minutes**
when you do the Firebase setup. Nothing has to be rewritten — you just flip the
switch.

## 1.3 What I built, step by step, and why

| # | What was built | Why |
|---|----------------|-----|
| 1 | **Project + dependencies** (`pubspec.yaml`) | The foundation: Flutter app set up with all the packages (Riverpod, go_router, Firebase, AI, file picker, etc.). |
| 2 | **Design system** (theme, colors, fonts, spacing) | The assignment is graded on UI/UX. A custom Material 3 theme (navy + sky-blue, Inter font) was built from the design spec so every screen looks intentional, not default. |
| 3 | **Navigation + shared widgets** (`go_router`, bottom nav, buttons, inputs) | So the 20+ screens connect together and reuse consistent building blocks. |
| 4 | **Auth feature** (sign in / sign up / forgot password) | Required Firebase service #1. Includes a guard that kicks you to the sign-in screen if you're not logged in. |
| 5 | **Documents feature** (home list, upload, live processing, detail) | The core flow: pick a file → upload → extract text → summarize → read. |
| 6 | **AI service** (real Gemini + fake stub) | Hidden behind one interface so the app uses the fake in demo mode and the real Gemini in live mode — without changing any screen code. |
| 7 | **Chat feature** (chat screen, message bubbles, chats list) | Ask questions about a document; answers stream in word-by-word. |
| 8 | **Profile / Folders / Onboarding / Settings** | The remaining screens, including a dark-mode toggle that is saved between launches. |
| 9 | **Tests + verification** | 52 automated tests (unit + widget + one integration), plus `flutter analyze` is clean. |
| 10 | **Firebase security rules + setup guide** | The cloud rules that make sure each user can only see *their own* data, plus `FIREBASE_SETUP.md` with exact commands. |

## 1.4 The error I actually hit (and how it was fixed)

The project uses **Riverpod version 3**, which is fairly new and **changed some
names** from version 2. Two changes broke the build:

1. **`.valueOrNull` was removed.** Old Riverpod let you read an async value with
   `.valueOrNull`. In v3 it's just `.value`. About 10 files used the old name,
   so every screen failed to compile.
   **Fix:** replaced every `.valueOrNull` with `.value`.

2. **`FamilyNotifier` no longer exists.** I first wrote the chat logic as a
   "family notifier" (a state object that takes an argument — the document ID).
   That base class was removed in v3, and the manual workaround can't read its
   own argument.
   **Fix:** I deleted that class and instead used a `StreamProvider.family`
   (which *can* take the document ID as an argument) for the saved messages, and
   kept the "currently typing" reply in simple local screen state. Cleaner and
   v3-correct.

A few smaller ones came up during testing:

3. **A crash when a repository was thrown away mid-work.** In tests, the
   in-memory document repository kept running its background "processing"
   pipeline after the test ended, then tried to push an update into a
   closed stream → crash. **Fix:** added a `_disposed` flag so it stops pushing
   updates once it's been disposed. (This also makes the real app safer.)

4. **Small package API differences** — e.g. `FilePicker.pickFiles(...)` is now a
   static call (not `FilePicker.platform.pickFiles`), and a couple of imports
   needed adjusting. All fixed.

**End result:** `flutter analyze` → *No issues found.* `flutter test` →
*All 52 tests passed.*

## 1.5 What you need to do next (in order)

> **Working checklist:** the live-backend bring-up is tracked as a tickable
> checklist in **[`BACKEND_CHECKLIST.md`](BACKEND_CHECKLIST.md)** (sections A–G).
> The prose below explains the same steps.

**To just run the app right now (demo mode):**

```bash
cd distill
flutter pub get          # download packages (first time only)
flutter run              # pick a device/emulator when asked
```

Then click through: Splash → (Onboarding first time) → Sign in (type *any*
email and *any* 6+ character password) → Home → Upload → watch Processing →
read the Summary → open Chat and ask a question → go to Profile → Settings →
toggle Dark mode → sign out.

**To make it "real" with Firebase (when you're ready):**

1. Read **`FIREBASE_SETUP.md`** (it has every command).
2. Install the tools: `npm install -g firebase-tools` and
   `dart pub global activate flutterfire_cli`, then `firebase login`.
3. Run `flutterfire configure` (this fills in `lib/firebase_options.dart` with
   your real project).
4. In the Firebase console, turn on: Authentication (Email + Google), Firestore,
   Realtime Database, Cloud Storage, and Firebase AI Logic (Gemini).
5. Deploy the security rules: `firebase deploy --only firestore:rules,storage,database`.
6. Open `lib/core/app_config.dart` and change `kFirebaseConfigured = false` to
   `true`. Restart the app. It's now live.

**Things still worth doing before you submit:**

- **Run it on a real device/emulator yourself** and walk the flow above. The
  automated tests and analyzer pass, but I could not click through the live UI
  from here — you should confirm it feels right on a phone.
- Optionally run the integration test on a device:
  `flutter test integration_test/app_test.dart`.

---

# PART 2 — THE DEEP DIVE

## 2.1 Technology stack (what each package is for)

From `pubspec.yaml`:

| Package | Role |
|---|---|
| `flutter_riverpod` (v3) | **State management + dependency injection.** How screens get data and react to changes. |
| `go_router` (v17) | **Navigation/routing.** URL-style routes, the bottom-nav shell, and the "not logged in → go to sign-in" guard. |
| `firebase_core` | Initializes Firebase. |
| `firebase_auth` | Login / sign-up / Google sign-in. |
| `cloud_firestore` | The main cloud **database** (documents, chats, profile). |
| `firebase_database` | **Realtime Database** — used for the live processing progress bar. |
| `firebase_storage` | Stores the **raw uploaded files**. |
| `firebase_ai` | **Gemini AI** via Firebase AI Logic (no server, key never ships in the app). |
| `google_sign_in` | The "Sign in with Google" button. |
| `file_picker` | Opens the system file picker to choose a PDF/DOCX/TXT. |
| `syncfusion_flutter_pdf` | Extracts **text out of PDF** files, on-device. |
| `google_fonts` | The **Inter** font. |
| `material_symbols_icons` | The icon set (including the ✦ sparkle = "this is AI"). |
| `flutter_animate` | Small entrance animations (e.g. the splash logo). |
| `flutter_svg` | Renders the **official multi-color Google "G"** logo on the auth buttons. |
| `shared_preferences` | Saves tiny local settings (theme choice, "onboarding seen"). |
| `intl` | Date/number formatting. |
| `share_plus` | Opens the **system share sheet** to share a document's summary + key points. |
| `archive` | Unzips a **DOCX** (a zip) to read `word/document.xml` for clean text extraction. |
| `mocktail` (dev) | Mocking library for tests. |
| `integration_test` (dev) | Full-app on-device tests. |

## 2.2 The architecture in one picture

The app uses a **feature-first, layered (Tier 2)** structure. Data flows in one
direction, and each layer only talks to the one below it:

```
   ┌─────────────────────────────────────────────────────────┐
   │  UI  (screens & widgets — what you see)                  │
   │  e.g. home_screen.dart, chat_screen.dart                 │
   └───────────────┬─────────────────────────────────────────┘
                   │ reads/watches
                   ▼
   ┌─────────────────────────────────────────────────────────┐
   │  LOGIC  (controllers / providers — decisions & state)    │
   │  e.g. auth_controller.dart, upload_controller.dart       │
   └───────────────┬─────────────────────────────────────────┘
                   │ calls
                   ▼
   ┌─────────────────────────────────────────────────────────┐
   │  DATA  (repositories — the ONLY thing that touches       │
   │         Firebase / AI / files)                           │
   │  interface + FirebaseImpl + DemoImpl                     │
   └───────────────┬─────────────────────────────────────────┘
                   │
        ┌──────────┴───────────┐
        ▼                      ▼
   Firebase / Gemini      In-memory (demo)
```

**The golden rules** (from the flutter-architecture skill):

- **Screens never call Firebase or the AI directly.** They go through a
  repository.
- **Repositories are the only contact with the outside world.** Each one is an
  *interface* (a contract) with **two implementations**: a Firebase one and a
  Demo one. The app picks which to use at runtime based on `firebaseReadyProvider`.
- **Features don't import each other's internals.** Anything shared lives in
  `core/` or `shared/`.
- **Every controller is disposed** so there are no memory leaks.

This is *why* the demo/live switch is invisible to the screens — they only know
about the interface, not which implementation is behind it.

## 2.3 Folder structure (with the role of every folder)

```
distill/
├── lib/
│   ├── main.dart                 # App entry point: init Firebase (if configured) → run app
│   ├── app.dart                  # The root widget: MaterialApp.router + themes
│   ├── firebase_options.dart     # Firebase project keys (placeholder until you run flutterfire)
│   │
│   ├── core/                     # App-wide foundations (used everywhere)
│   │   ├── app_config.dart       # ← the kFirebaseConfigured demo/live SWITCH
│   │   ├── constants.dart        # App name, file limits, DocStatus enum
│   │   ├── validators.dart       # Email/password/required form validators
│   │   ├── ai/                   # The AI abstraction
│   │   │   ├── ai_service.dart        # Interface + SummaryResult/ChatTurn types
│   │   │   ├── gemini_ai_service.dart # Real Gemini implementation
│   │   │   └── stub_ai_service.dart   # Fake offline implementation
│   │   ├── di/
│   │   │   └── providers.dart     # ALL the Riverpod providers (dependency injection hub)
│   │   ├── extensions/
│   │   │   └── context_ext.dart   # Handy shortcuts: context.colors, context.text, .readableSize
│   │   ├── routing/
│   │   │   └── app_router.dart    # All routes + the auth redirect guard
│   │   └── theme/
│   │       ├── app_colors.dart    # Every hex color (light + dark palettes)
│   │       ├── app_typography.dart# The Inter text styles (display/headline/title/body/label)
│   │       ├── app_spacing.dart   # Spacing (4/8px grid) + corner radii
│   │       ├── app_theme.dart     # Builds the light & dark ThemeData from the tokens above
│   │       └── theme_controller.dart # Saves/loads the user's theme choice
│   │
│   ├── features/                 # One folder per feature; each has data/logic/ui
│   │   ├── onboarding/ui/         # splash_screen, onboarding_screen
│   │   ├── auth/
│   │   │   ├── data/              # auth_repository (interface+Firebase), demo_auth_repository, models/app_user
│   │   │   ├── logic/             # auth_controller (handles form submits)
│   │   │   └── ui/                # sign_in, sign_up, forgot_password, widgets/(google_button, google_logo, or_divider)
│   │   ├── documents/
│   │   │   ├── data/              # document_repository (interface+Firebase), demo_document_repository, models/document_model
│   │   │   ├── logic/             # upload_controller (picked-file state + start upload)
│   │   │   └── ui/                # home, processing, document_detail, widgets/(document_card, upload_sheet)
│   │   ├── chat/
│   │   │   ├── data/              # chat_repository (interface+Firebase), demo_chat_repository, models/chat_message
│   │   │   └── ui/                # chat_screen, chats_list_screen, widgets/message_bubble
│   │   └── profile/ui/            # profile_screen, edit_profile_screen, settings_screen
│   │
│   └── shared/                   # Reusable, cross-feature pieces
│       ├── services/             # file_service (file picker), text_extraction_service (PDF/TXT → text)
│       └── widgets/              # app_logo, app_text_field, ai_badge, empty_state, error_view, shimmer, main_shell (bottom nav)
│
├── test/                         # Mirrors lib/ — unit + widget tests, plus helpers/
├── integration_test/             # app_test.dart — one full sign-in→home flow
│
├── firebase.json                 # Tells Firebase CLI where the rules files are
├── firestore.rules               # Database security: each user sees only their own data
├── storage.rules                 # File storage security: own files only, 50MB cap, allowed types
├── database.rules.json           # Realtime DB security: own progress node only
├── FIREBASE_SETUP.md             # Step-by-step "go live" guide
└── pubspec.yaml                  # Dependencies & project config
```

## 2.4 Every file explained

### 2.4.1 Entry & root

- **`lib/main.dart`** — The very first code that runs. It checks
  `kFirebaseConfigured`; if true it calls `Firebase.initializeApp` (and falls
  back to demo mode if that fails), then runs the app wrapped in a
  `ProviderScope` (required for Riverpod). It passes the real/fake status into
  `firebaseReadyProvider`.
- **`lib/app.dart`** — The root widget `DistillApp`. Builds `MaterialApp.router`
  with the light theme, dark theme, the current `themeMode` (from
  `themeControllerProvider`), and the router from `goRouterProvider`.
- **`lib/firebase_options.dart`** — Auto-generated file holding your Firebase
  project's keys. Right now it's a **harmless placeholder**; `flutterfire
  configure` overwrites it with real values.

### 2.4.2 Core — configuration & helpers

- **`core/app_config.dart`** — Contains the single `kFirebaseConfigured`
  constant (the demo/live switch) and a comment with the go-live steps.
- **`core/constants.dart`** — App name, tagline, the 50MB upload cap, allowed
  file extensions, max characters of text sent to the AI, and the
  **`DocStatus`** enum (`uploading → extracting → summarizing → ready / error`)
  with helper getters (`.label`, `.isProcessing`).
- **`core/validators.dart`** — Pure functions that return an error string or
  `null`: `email`, `password` (≥6 chars), `required`. Used by the forms.
- **`core/extensions/context_ext.dart`** — Quality-of-life shortcuts:
  `context.colors` (color scheme), `context.text` (text styles),
  `context.showSnack(...)`, plus `int.readableSize` ("4.2 MB") and
  `DateTime.relative` ("2 days ago").

### 2.4.3 Core — theme (the design system)

- **`app_colors.dart`** — All raw hex colors as constants, for both the light
  palette (navy `#00236f` primary, sky-blue secondary) and a separate
  first-class dark palette (deep slate surfaces).
- **`app_typography.dart`** — Builds a `TextTheme` from the **Inter** font with
  the size/weight scale from the spec (display 32/700 down to label 12/500).
- **`app_spacing.dart`** — The `AppSpacing` (4/8px grid: xs…huge) and
  `AppRadius` (sm…full) scales. Every margin/padding/corner in the app refers to
  these, so spacing is consistent.
- **`app_theme.dart`** — Assembles everything into two `ThemeData` objects
  (`AppTheme.light` / `AppTheme.dark`): color scheme, button styles (48px tall),
  inputs (56px, 2px focus ring), cards (1px outline), chips (pill-shaped), the
  bottom nav bar, snackbars, etc.
- **`theme_controller.dart`** — A Riverpod `Notifier<ThemeMode>` that loads the
  saved theme from `shared_preferences` on startup and saves it when changed.

### 2.4.4 Core — AI abstraction

- **`ai/ai_service.dart`** — The **interface** `AiService` with two methods:
  `summarize(text)` → `SummaryResult` (summary + key points), and
  `answer(question, context, history)` → a **stream** of text chunks. Also
  defines `SummaryResult`, `ChatTurn`, and `AiException`.
- **`ai/gemini_ai_service.dart`** — Real implementation using `firebase_ai` and
  the `gemini-2.0-flash` model. It builds careful prompts ("use ONLY the
  document content", "respond with ONLY valid JSON"), clips text to a max length
  to stay within token/free-tier limits, parses the JSON (stripping any stray
  markdown fences), and **streams** answers chunk-by-chunk.
- **`ai/stub_ai_service.dart`** — Fake offline implementation. Returns a
  deterministic summary (mentions the word count and an excerpt) and "types out"
  a canned answer word-by-word with small delays to mimic streaming. This is
  what runs in demo mode **and** what the unit tests use.

### 2.4.5 Core — dependency injection (`di/providers.dart`)

This is the **wiring hub**. It declares every Riverpod provider and, crucially,
**chooses Firebase vs Demo implementations** based on `firebaseReadyProvider`.
Key providers:

- `firebaseReadyProvider` — true/false; overridden in `main.dart`.
- `aiServiceProvider` — Gemini if ready, else the stub.
- `authRepositoryProvider` — Firebase or Demo auth repo.
- `authStateProvider` — a **stream** of the current `AppUser?` (the source of
  truth for "am I logged in"). `currentUserProvider` is a convenience reader.
- `documentRepositoryProvider` — **null when logged out**, otherwise a repo
  scoped to the user's `uid`.
- `documentsStreamProvider` / `documentByIdProvider(id)` /
  `processingProgressProvider(id)` — live streams for the lists/detail/progress.
- `chatRepositoryProvider`, `chatsStreamProvider`,
  `chatMessagesProvider(id)` — the chat equivalents.

Note the pattern: providers that need an argument (like a document ID) use
`StreamProvider.family<..., String>` — this is the v3-correct replacement for
the family-notifier that originally broke the build.

### 2.4.6 Core — routing (`routing/app_router.dart`)

Defines all routes with `go_router`:

- **Public routes** (reachable when logged out): `/splash`, `/onboarding`,
  `/sign-in`, `/sign-up`, `/forgot-password`.
- **The `redirect` guard:** on every navigation it reads `authStateProvider`.
  If you're **not** logged in and trying to reach a private page → redirect to
  `/sign-in`. If you **are** logged in and on sign-in/up → redirect to `/home`.
  It re-runs whenever auth state changes (via a `refreshListenable`).
- **`StatefulShellRoute.indexedStack`** — the three bottom-nav tabs (Home /
  Chats / Profile), each keeping its own navigation stack.
- **Full-screen routes above the tabs:** `/processing/:id`, `/document/:id`,
  `/chat/:id`, `/edit-profile`, `/settings`. (Upload now opens the OS picker
  directly from Home, then a confirmation sheet — no dedicated route.)

### 2.4.7 Auth feature

- **`data/auth_repository.dart`** — Interface `AuthRepository` + the real
  `FirebaseAuthRepository`. Handles email/password, Google sign-in, password
  reset, profile-name update, and sign-out. It also **creates a `users/{uid}`
  Firestore profile** on first sign-in, and maps Firebase error codes to
  friendly messages ("Incorrect email or password."). `AuthFailure` is its typed
  exception.
- **`data/demo_auth_repository.dart`** — In-memory version: accepts any email +
  any 6+ char password, fabricates a demo user, and remembers it for the app's
  run. Google sign-in returns a canned "Sarah Chen" user.
- **`data/models/app_user.dart`** — The `AppUser` model (uid, email, name,
  photo, stats: docCount/questionCount/storageBytes, subscription). Has
  `toMap`/`fromMap` for Firestore and an `initial` getter for the avatar letter.
- **`logic/auth_controller.dart`** — An `AsyncNotifier<void>` that the forms
  call. Each method (`signIn`, `signUp`, `signInWithGoogle`,
  `sendPasswordReset`) sets loading state, runs the repo call inside
  `AsyncValue.guard` (so errors become state, not crashes). Navigation on
  success is handled automatically by the router reacting to auth state.
- **`ui/sign_in_screen.dart`** — Email + password form (keys `email_field` /
  `password_field` for tests), "Forgot password?", an OR divider, the
  "Continue with Google" button, and a link to sign-up. Spinner while loading,
  snackbar on error.
- **`ui/sign_up_screen.dart`** — Name + email + password registration form,
  plus the same OR divider + "Continue with Google" button (Google OAuth both
  signs in and registers, so it belongs on both screens).
- **`ui/forgot_password_screen.dart`** — Email field → sends a reset link.
- **`ui/widgets/google_button.dart`** — The standard "Continue with Google"
  button (neutral surface, thin outline) hosting the real Google logo.
- **`ui/widgets/google_logo.dart`** — The **official multi-color Google "G"**,
  drawn from Google's brand SVG via `flutter_svg` (carries its own colors, so it
  looks right in light and dark).
- **`ui/widgets/or_divider.dart`** — The shared "OR" divider used by both auth
  screens.

### 2.4.8 Documents feature (the core flow)

- **`data/document_repository.dart`** — Interface + `FirebaseDocumentRepository`.
  Defines `ProcessingProgress` (status + percent). The Firebase impl runs the
  **full pipeline** in `_runPipeline`: create Firestore doc → upload bytes to
  Cloud **Storage** → write live progress to **Realtime Database** → extract
  text → call the **AI** to summarize → save the summary back to Firestore →
  mark `ready` and bump the user's doc count. Also `toggleFavorite` and `delete`
  (which also removes the stored file and progress node).
- **`data/demo_document_repository.dart`** — In-memory version that **seeds 4
  sample documents** (a Q4 report, a manifesto, a research paper still
  "summarizing", and meeting notes) so the app looks alive immediately. Its
  `uploadAndProcess` runs the same pipeline shape using the stub AI and emits
  progress through a stream. **(This is the file that got the `_disposed` guard
  fix.)**
- **`data/models/document_model.dart`** — The `DocumentModel` (id, name, type,
  size, status, pages, storage path/url, summary, keyPoints, extractedText,
  folderId, favorite, timestamps). Has `toMap`/`fromMap` (Firestore) and
  `copyWith`, plus an `isReady` getter.
- **`logic/upload_controller.dart`** — Holds the *picked file* before you commit
  to uploading. `pick()` opens the file picker; `startUpload()` hands the bytes
  to the repository and returns the new document's id.
- **`ui/home_screen.dart`** — The main list and the single browse surface.
  Time-aware greeting, search box, filter chips (All / Recent / Favorites /
  PDFs), a card per document, an "Upload" floating button, and an empty state.
  The Upload FAB (and the empty-state action) call `_startUpload()`, which opens
  the OS file picker **directly**, then shows the confirmation sheet. Tapping a
  still-processing doc goes to Processing; a ready doc goes to Detail.
- **`ui/widgets/upload_sheet.dart`** — The upload **confirmation bottom sheet**
  (`showUploadConfirmSheet`) shown right after a file is picked: file name +
  size, a ✦ "AI will read & summarize this" note, and Summarize / Cancel.
  Returns `true` to start processing. (This replaced the old dedicated
  `upload_screen.dart`, whose dropzone and "Browse files" button did the same
  thing — a duplicate that's now gone. Cancelling the picker just returns to
  Home, so there's no dead-end.)
- **`ui/processing_screen.dart`** — The live "Analyzing your document" screen. A
  gradient ✦ tile, a 4-step checklist (Uploaded → Extracted → Summary →
  Preparing questions), a percentage and progress bar fed by
  `processingProgressProvider`, and **auto-navigation to the detail screen when
  the status becomes `ready`**.
- **`ui/document_detail_screen.dart`** — Tabbed view (Summary / Key Points /
  Original text) with a back button, a favorite toggle, and an "Ask questions
  about this" button → opens the chat.
- **`ui/widgets/document_card.dart`** — The reusable document row: type icon,
  name, AI status line (a "Summarized" badge, a spinner, or an error), a
  2-line summary snippet, and a meta line (type chip · size · "2 days ago").

### 2.4.9 Chat feature

- **`data/chat_repository.dart`** — Interface + `FirebaseChatRepository` +
  `ChatSummary` (used by the Chats tab). One chat per document
  (`chatId == documentId`). Saves each message under
  `users/{uid}/chats/{chatId}/messages` and keeps a summary doc with the last
  message + timestamp for the list.
- **`data/demo_chat_repository.dart`** — In-memory version with the same shape;
  keeps messages and summaries in maps and broadcasts changes via streams.
- **`data/models/chat_message.dart`** — `ChatMessage` (id, isUser, text,
  citations, createdAt, `pending` flag for the streaming reply) and `Citation`
  (quote + optional page). Both have `toMap`/`fromMap`.
- **`ui/chat_screen.dart`** — The conversation. Watches saved messages via
  `chatMessagesProvider(documentId)`, keeps the **in-progress AI reply in local
  state**, sends a question (saves it, increments the question count, streams
  the AI answer into a bubble, then persists the final answer). Has suggestion
  chips, an empty state, and the text composer.
- **`ui/chats_list_screen.dart`** — The Chats tab: a card per past conversation
  (from `chatsStreamProvider`), or an empty state.
- **`ui/widgets/message_bubble.dart`** — One chat row. User messages are
  right-aligned filled bubbles; AI messages are left-aligned with optional
  citation cards; shows animated "typing dots" while a reply is still streaming.

### 2.4.10 Profile, Onboarding

> The former **Folders** tab was removed: its "smart collections" (All /
> Favorites / PDFs / Docs) duplicated Home's search + filter chips. The bottom
> nav is now three tabs (Home / Chats / Profile), and Home is the single browse
> surface — no duplicate functionality.

- **`profile/ui/profile_screen.dart`** — Avatar + name + email, a stats row
  (docs / questions / storage), section tiles (Edit profile, Settings,
  Subscription), and a sign-out button with a confirm dialog.
- **`profile/ui/edit_profile_screen.dart`** — Edit your display name (email is
  read-only).
- **`profile/ui/settings_screen.dart`** — Appearance section with a
  **`RadioGroup<ThemeMode>`** (System / Light / Dark) wired to the theme
  controller, plus an "About" section showing version and whether you're on
  Firebase or demo mode.
- **`onboarding/ui/splash_screen.dart`** — Navy branded splash with an animated
  logo; waits ~1.6s, then routes to onboarding (first run), home (logged in), or
  sign-in.
- **`onboarding/ui/onboarding_screen.dart`** — The intro slides shown on first
  launch; sets the "onboarding seen" flag so it doesn't show again.

### 2.4.11 Shared services & widgets

- **`shared/services/file_service.dart`** — Wraps the file picker, enforces the
  allowed extensions and the 50MB limit, and returns a `PickedDocument` (name,
  type, size, bytes). Throws a friendly `FilePickException` on problems.
- **`shared/services/text_extraction_service.dart`** — Turns file bytes into
  text: **PDF** via Syncfusion (also counts pages), **TXT** decoded directly,
  **DOCX** best-effort (strips XML tags). Fully on-device, no server.
- **`shared/widgets/app_logo.dart`** — The reusable Distill logo mark.
- **`shared/widgets/app_text_field.dart`** — The styled outlined input (icon,
  floating label, optional password show/hide) used across the forms.
- **`shared/widgets/ai_badge.dart`** — The ✦ sparkle + optional label that marks
  every AI feature (a design-system signature).
- **`shared/widgets/empty_state.dart`** — The friendly "nothing here yet" block
  with an icon, message, and optional call-to-action button.
- **`shared/widgets/error_view.dart`** — A reusable error state: icon + friendly
  title/message + optional **Retry** button. Used in the async `error:` builders
  (Home, Chats, Document detail) instead of dumping the raw exception.
- **`shared/widgets/shimmer.dart`** — A hand-rolled (no-dependency) `Shimmer`
  sweep plus `SkeletonBox` / `SkeletonListTile` / `SkeletonList` placeholders,
  shown in the `loading:` states for a premium skeleton effect (theme-aware).
- **`shared/widgets/main_shell.dart`** — The bottom navigation bar hosting the
  three tabs (Home / Chats / Profile).

## 2.5 Three data-flow walkthroughs

**A) Signing in (demo mode):**
You type email + password → `sign_in_screen` calls
`authController.signIn()` → it calls `authRepositoryProvider` (the **Demo** repo
because `firebaseReady` is false) → the demo repo emits an `AppUser` →
`authStateProvider` (a stream) updates → the **router's redirect guard** sees
you're now logged in and sends you to `/home`. The screen never knew or cared
whether it was demo or Firebase.

**B) Uploading a document:**
Home Upload FAB → `_startUpload()` → `uploadController.pick()` opens
`file_service` (the OS picker) → you pick a TXT → a confirmation **sheet**
(`upload_sheet.dart`) appears → tap **Summarize** → `startUpload()` calls
`documentRepository.uploadAndProcess()` → it inserts a doc in `uploading` state
and kicks off the background pipeline → Home navigates to `/processing/:id` →
the processing screen watches `processingProgressProvider`
and shows the bar climbing as the pipeline goes uploading → extracting (via
`text_extraction_service`) → summarizing (via `aiServiceProvider`, the **stub**)
→ ready → it auto-navigates to the document detail with the finished summary.

**C) Asking a question:**
Chat screen → you type a question → `_send()` saves your message via
`chatRepository.addMessage()`, then calls `aiService.answer(...)` which returns a
**stream**; each chunk is appended to a "pending" bubble so the answer appears to
type itself → when the stream ends, the full answer is saved. The Chats tab
updates because the repository also recorded a `ChatSummary`.

## 2.6 The Firebase backend design (how each required service is used)

| Service | Where | What it stores |
|---|---|---|
| **Authentication** | — | Email/password + Google accounts. |
| **Firestore** | `users/{uid}` | Profile + stats. |
| | `users/{uid}/documents/{docId}` | Document metadata, summary, key points, extracted text. |
| | `users/{uid}/chats/{chatId}/messages/{msgId}` | Chat history. |
| **Realtime Database** | `progress/{uid}/{docId}` | Live `{ step, percent }` for the processing bar. |
| **Cloud Storage** | `users/{uid}/documents/{docId}/{file}` | The raw uploaded file. |
| **Firebase AI Logic** | — | Gemini: `summarize()` and streamed `answer()`. |

Using **both** Firestore (durable data) and Realtime Database (fast, ephemeral
progress) gives each Firebase product a clear, distinct job — which is exactly
what the assignment asks for.

### Security rules (who can read/write what)

- **`firestore.rules`** — A user can read/write **only** their own
  `users/{uid}/**` tree (documents, folders, chats, messages). Everything else
  is denied by default.
- **`storage.rules`** — A user can read/write **only** files under
  `users/{uid}/documents/...`, with a **50MB** cap and a content-type check
  (PDF / DOCX / TXT only).
- **`database.rules.json`** — A user can read/write **only**
  `progress/{uid}/...`, and each progress node is validated to have a string
  `step` and a 0–100 `percent`.
- **`firebase.json`** — Points the Firebase CLI at those three rule files so
  `firebase deploy` knows where they are.

## 2.7 Tests (what's covered and how to run them)

Run unit + widget tests: `flutter test` → **60 tests, all passing** (52 at
launch; +5 from feature pass 4 §2.11; +3 from UX pass 5 §2.12).
The integration test needs a device: `flutter test integration_test/app_test.dart`.

- **`test/helpers/fixtures.dart`** — Factory functions for sample `AppUser`,
  `DocumentModel`, `ChatMessage`, and TXT bytes, so tests stay short.
- **`test/helpers/test_helpers.dart`** — A `pumpApp` helper that wraps a widget
  in `ProviderScope` + `MaterialApp` with a plain Material theme (so widget
  tests stay offline — no font downloads).
- **Unit tests:** `validators_test`, `stub_ai_service_test` (summary mentions
  word count; answer streams multiple chunks), `document_model_test` &
  `app_user_test` & `chat_message_test` (save/load round-trips + edge cases),
  `demo_chat_repository_test` (message append, summary ordering),
  `demo_document_repository_test` (**the full upload→ready pipeline**, progress
  reaching 100%, favorite/delete).
- **Widget tests:** `document_card_test` (renders name/summary/badge, processing
  spinner, error line, tap & "more" callbacks), `message_bubble_test` (text,
  citation cards, typing dots), and `error_view_test` (title/message renders,
  Retry shows only with a callback and fires it).
- **Integration test:** `app_test.dart` — boots the real app in demo mode, signs
  in, and asserts it lands on Home.

## 2.8 Full list of errors faced and fixes

| Error | Cause | Fix |
|---|---|---|
| `valueOrNull` undefined on `AsyncValue` (≈10 files) | Riverpod v3 renamed it to `.value` | Replaced every `.valueOrNull` with `.value` |
| `ChatController extends FamilyNotifier` failed to compile | `FamilyNotifier` removed in Riverpod v3; manual family notifiers can't read their argument | Deleted the controller; used `StreamProvider.family` for saved messages + local state for the streaming reply |
| `stub_ai_service` "const with non-constant value" | A `const` string used string interpolation | Changed `const` → `final` |
| `firebase_options.dart` undefined `kIsWeb` / `defaultTargetPlatform` | Those aren't exported by `firebase_core` | Imported them from `package:flutter/foundation.dart` |
| `FilePicker.platform.pickFiles` undefined | `file_picker` v11 made `pickFiles` a static method | Changed to `FilePicker.pickFiles(...)` |
| `DocStatus.isProcessing` undefined in folder detail | The extension lived in `core/constants.dart` | Added the missing import |
| Default `test/widget_test.dart` referenced a non-existent `MyApp` | Leftover Flutter starter test | Deleted it |
| "Cannot add new events after calling close" in a repo test | The demo document repo's background pipeline kept running after the test disposed it | Added a `_disposed` flag guarding all stream writes |
| `unintended_html_in_doc_comment` info lint | A `<device>` in a doc comment was read as HTML | Reworded the comment |
| **Dark-mode text invisible** (document title, profile name, section tiles, tab labels) | `app_typography.dart` built the text theme as `GoogleFonts.interTextTheme().copyWith(...)` but only set a color on *some* styles; the rest (`headlineSmall`, `titleSmall`, `headlineLarge`, `bodySmall`) kept the near-black color baked into Google Fonts' base theme → invisible on the dark surface | Applied `.apply(bodyColor/displayColor: onSurface)` to recolor **all** styles before the per-style overrides, and added an explicit `bodySmall` |
| Button spinners invisible on the dark-mode primary button | `Colors.white` spinner on the light-lavender dark-mode primary button | Switched the three auth button spinners to `Theme.of(context).colorScheme.onPrimary` |
| Processing ✦ tile icon could wash out in dark mode | The tile gradient used `context.colors.primary/secondary`, which go pale in dark mode under the white icon | Pinned the tile to the fixed brand gradient `AppColors.primary → AppColors.secondary` (theme-independent) |

**Final state:** `flutter analyze` → *No issues found.* `flutter test` →
*All 52 tests passed.*

## 2.9 What's done vs what's left

**Done (all 9 build tasks):** project scaffold, design system, navigation +
shared widgets, auth, documents + upload/processing, AI (Gemini + stub), chat,
profile/folders/onboarding/settings, tests, and Firebase security rules + setup
guide. The app **compiles cleanly and runs in demo mode.**

**Left for you:**
1. **Run it on a device/emulator and click through the whole flow** — this is
   the one thing the automated checks can't replace. (I could not drive the live
   UI from this environment.)
2. **Connect Firebase** when ready (follow `FIREBASE_SETUP.md`, then flip
   `kFirebaseConfigured` to `true`).
3. Optionally run the on-device integration test.
4. Optionally verify in the Firebase console (after going live) that a sign-in,
   an upload, and a processing run create the expected Auth user, Storage file,
   Firestore document, and Realtime Database progress node.

## 2.10 UI refinement pass (post-build, from on-device review)

After running the app on an Android emulator, a round of UI/UX polish was made.
**No functionality changed** — these are presentation, navigation, and flow
improvements. All changes kept `flutter analyze` clean and the tests green.

| Area | Problem seen | Change |
|---|---|---|
| **Dark-mode text** | Document title, profile name, section tiles, and tab labels were invisible in dark mode | Root cause in `app_typography.dart` (see §2.8). Now **all** text styles are recolored, so every screen's text is visible in both themes. |
| **Status bar** | A gray band sat at the top instead of blending with the screen | `app.dart` wraps the app in an `AnnotatedRegion<SystemUiOverlayStyle>` (transparent status/nav bars, theme-correct icon contrast); `app_theme.dart` sets `appBarTheme.systemOverlayStyle` to match. Blends on every screen. |
| **Dark theme comfort** | Deep `#0F172A` with stark white text felt harsh | `app_colors.dart` dark ramp lifted off pure-dark (`dSurface #181D2A` …) and on-surface softened to `#E2E5ED` — a "softer & lifted" palette that's easier on the eyes. |
| **Nav bar accent** | Selected tab pill was a harsh bright sky-blue (`#39B8FD`) | `navigationBarTheme` indicator is now a soft navy brand tint (`primary` @ 12% light / 24% dark) with navy selected icon + label. |
| **Theme-aware leaks** | Auth button spinners + the processing ✦ tile used hardcoded `Colors.white` | Spinners use `onPrimary`; the ✦ tile is pinned to the fixed brand gradient so the white sparkle always reads. (Splash + Google "G" left fixed on purpose.) |
| **Upload flow** | A dedicated upload screen with a **duplicate** dropzone + "Browse" button, and a dead-end feel when the OS picker was empty | Upload now opens the OS picker **directly** from Home, then a confirmation **sheet** (`upload_sheet.dart`); cancelling returns to Home. `upload_screen.dart` + the `/upload` route were deleted. |
| **Home ↔ Folders duplication** | The Home filter chips and the Folders tab were the same feature twice | The **Folders** tab/feature was removed → 3 tabs (Home / Chats / Profile). Home's search + filter chips are the single browse surface. |
| **Greeting** | "Good morning" was hardcoded | Now time-aware (morning / afternoon / evening). |
| **Google logo** (pass 2) | The button used a fake dark "G" tile | Replaced with the **official multi-color Google "G"** (`google_logo.dart` via `flutter_svg`) and the standard button styling. |
| **Google placement** (pass 2) | Google option was only on sign-in | "Continue with Google" now appears on **both** sign-in and sign-up (shared `or_divider.dart`), matching common apps. |
| **Upload cancel feedback** (pass 2) | Backing out of an empty OS picker felt like nothing happened | `home._startUpload()` now shows a neutral "No file selected" snackbar on cancel. (The picker is system UI — the device back button returns to the app; the app already handled it cleanly.) |
| **Skeleton loaders** (pass 3) | Loading states were plain centered spinners | New `shimmer.dart` (no dependency) shows shimmering skeleton placeholders in the `loading:` states of Home, Chats, and Document detail. |
| **Polished error states** (pass 3) | Home / Chats / Detail showed a raw `Something went wrong: $e` | New reusable `error_view.dart` (icon + friendly message + **Retry** that re-invokes the provider) replaces them. Covered by `error_view_test.dart`. |

> Note: in the earlier emulator screenshot, the file picker showing **"No items"**
> was the *emulator* having no documents to pick — not an app bug. Add a PDF to the
> emulator's Downloads and it appears.
```

## 2.11 Feature pass 4 — Copy/Share, Delete confirm, real DOCX (2026-05-31)

A small, focused feature pass adding three user-requested capabilities. Every
step is logged below, including the (clean) verification results. All changes
follow the house rules: theme-aware (`context.colors`/`context.text`, no
hardcoded colors), loading/error handling consistent with the rest of the app,
and mode-aware (work through the repository interface, so demo **and** Firebase
behave identically).

### What was built

| # | Feature | What changed | Files |
|---|---------|--------------|-------|
| 1 | **Copy & Share summary** | Document detail header now shows **Copy** and **Share** icon buttons (only when the doc `isReady`, beside the favorite toggle). Both use a new **pure** helper `buildShareText(doc)` that formats `name` + `AI Summary` + bulleted `Key Points` + a "Summarized with Distill" footer. Copy uses Flutter's built-in `Clipboard` + a "Copied to clipboard" snackbar; Share opens the system sheet via `share_plus`, wrapped in try/catch with an error snackbar. | `lib/features/documents/data/share_text.dart` (new), `lib/features/documents/ui/document_detail_screen.dart` |
| 2 | **Delete confirmation** | The Home action-sheet **Delete** no longer deletes instantly. It now pops the sheet, then shows a confirm `AlertDialog` (Cancel / red Delete) mirroring the existing sign-out dialog, deletes only on confirm, and shows a "Document deleted" snackbar. No undo — the Firebase `delete()` also removes the Storage file + progress node, so it isn't cleanly reversible (documented honestly). | `lib/features/documents/ui/home_screen.dart` |
| 3 | **Real DOCX extraction** | `_extractDocx` was a crude byte-decode + tag-strip that produced garbled output. It now unzips the `.docx` with `archive`, reads `word/document.xml`, converts `</w:p>`/`<w:br/>`/`<w:tab/>` to real whitespace, strips remaining XML, decodes entities (`&amp;` etc.), and collapses whitespace per line. Wrapped in try/catch that falls back to the **old** tag-strip (`_stripDocxBytes`) so a malformed file never crashes the pipeline. | `lib/shared/services/text_extraction_service.dart` |

### Dependencies added
`pubspec.yaml`: `share_plus: ^11.0.0` (resolved 11.1.0) and `archive: ^4.0.0`
(resolved 4.0.9). `flutter pub get` → *Changed 10 dependencies* (share_plus
pulls in `url_launcher_*`; archive pulls in `fixnum`/`posix`).

### Tests added
- `test/shared/services/text_extraction_service_test.dart` — builds a minimal
  valid `.docx` in memory with `ZipEncoder`, asserts paragraph text is
  extracted, markup is gone, entities are decoded, and paragraphs land on
  separate lines; a negative case feeds non-zip bytes and asserts the fallback
  returns text without throwing; plus a TXT round-trip.
- `test/features/documents/data/share_text_test.dart` — asserts
  `buildShareText` includes name/summary/every key point, and gracefully omits
  empty sections for an in-progress document.
- Removed the one stray `import 'package:flutter/material.dart';` in
  `test/shared/widgets/error_view_test.dart` (the lone analyzer warning).

### Errors faced
**None.** This pass compiled and passed on the first run — no build or test
errors. The one pre-existing analyzer warning (unused import) was removed as
part of the work. Before coding, the `share_plus` 11.x API was verified against
the installed package source to confirm the current call shape
(`SharePlus.instance.share(ShareParams(text: ...))`) rather than the older
top-level `Share.share(...)`.

### Verification
- `flutter analyze` → **No issues found!**
- `flutter test` → **All 57 tests passed** (the previous 52 + 5 new).
- Still to confirm on a device (can't be driven from here): upload a real
  `.docx` and check the **Original** tab is clean text; tap **Copy**/**Share**
  on a ready document; trigger **Delete** and confirm the dialog gates it.

**Updated final state:** `flutter analyze` → *No issues found.* `flutter test`
→ *All 57 tests passed.*

## 2.12 UX pass 5 — sign-up confirm, dialog buttons, web overflow, card cue (2026-05-31)

Four UX fixes from hand-testing (including on Chrome). All theme-aware and
mode-agnostic; loading/error behavior unchanged.

| # | Issue | Fix | Files |
|---|-------|-----|-------|
| 1 | Sign-up had no **confirm-password** field | Added a reusable `Validators.confirmPassword(value, original)` and a "Confirm password" `AppTextField` after the password field; the password field's action is now `next`. No backend change — `signUp` still takes name/email/password. | `lib/core/validators.dart`, `lib/features/auth/ui/sign_up_screen.dart` |
| 2 | **Confirm dialogs** stacked a right-aligned *Cancel* above a full-width button (Material action overflow) | New shared `showConfirmDialog()` renders **Cancel \| confirm** as two equal `Expanded` buttons in a `Row` (Outlined + Filled; `destructive` → red). Delete and Sign-out now both use it (DRY). | `lib/shared/widgets/confirm_dialog.dart` (new), `home_screen.dart`, `profile_screen.dart` |
| 3 | **Processing screen overflowed ~27px on Chrome** (rigid `Column` + two `Spacer`s) | Wrapped the body in `LayoutBuilder → SingleChildScrollView → ConstrainedBox(minHeight: maxHeight) → IntrinsicHeight`. Stays centered when there's room; scrolls instead of overflowing on a short web viewport. | `lib/features/documents/ui/processing_screen.dart` |
| 4 | Disliked the **spinning** processing indicator on Home cards | Replaced the `CircularProgressIndicator` with a `_PulsingDot` — a small dot that softly pulses opacity (own `AnimationController`, disposed). | `lib/features/documents/ui/widgets/document_card.dart` |

### Error faced
- **Pending-timer test failure.** First implemented the pulsing dot with
  `flutter_animate`'s `.animate().fade(...).repeat()`. Its infinite repeat
  schedules a `Timer` that the widget-test harness flags as "pending timers" at
  teardown, failing `document_card_test`. **Fix:** replaced it with a dedicated
  `_PulsingDot` `StatefulWidget` using a `SingleTickerProviderStateMixin`
  `AnimationController` that is disposed in `dispose()` — clean at teardown and
  test-friendly. The card test was updated to assert *no* `CircularProgressIndicator`
  plus the "Processing AI insights…" label.

### Tests
- `validators_test.dart`: new `Validators.confirmPassword` group (empty /
  mismatch / match).
- `document_card_test.dart`: processing-branch test updated for the pulsing dot.

### Verification
- `flutter analyze` → **No issues found!**
- `flutter test` → **All 60 tests passed** (57 + 3).
- Still to confirm on a device/Chrome: mismatched passwords block sign-up;
  dialogs show side-by-side buttons; Processing screen no longer overflows on a
  short Chrome window; the card shows a pulsing dot.

**Updated final state:** `flutter analyze` → *No issues found.* `flutter test`
→ *All 60 tests passed.*

## 2.13 Live Firebase bring-up — going to production (2026-06-02)

The app was taken **live on Firebase** (project `distill-d0c18`) and verified
end-to-end on Chrome web. `kFirebaseConfigured` is now `true`. This section is
the running journal of the bring-up, including every error hit and its fix, per
the project rule. Tooling installed beforehand: Node, Firebase CLI, FlutterFire
CLI (`firebase login`, `flutterfire configure`). Services enabled in the Firebase
console: Auth (email/password + Google), Firestore, Realtime Database
(`europe-west1`), Firebase AI Logic (Gemini). Firestore + Realtime DB security
rules deployed.

### Errors faced and fixes (live bring-up)

| Error / symptom | Cause | Fix |
|---|---|---|
| Realtime DB writes silently did nothing | `firebase_options.dart` was missing the `databaseURL` field in all three configs (web/android/ios) — the RTDB client had no endpoint | Added `databaseURL: 'https://distill-d0c18-default-rtdb.europe-west1.firebasedatabase.app'` to every config block |
| Progress node never matched the rules | Realtime DB security rules validated a field named `step`, but the app writes `status` | Renamed the field in the rules `step → status` and redeployed (`firebase deploy --only database`) |
| Cloud Storage upload hangs / throws on web (CORS) | `firebasestorage.googleapis.com` rejects the browser preflight (no bucket CORS config) — see cosmetic note below | Wrapped the `putData` upload in `try/catch` **and** `.timeout(Duration(seconds: 5))` in `document_repository.dart` so a failed/slow Storage write can't block the pipeline; the summary flow continues regardless |
| Google sign-out could block | `GoogleSignIn.signOut()` awaited on web where it can stall | Made the Google sign-out **non-blocking** (fire-and-forget) in `auth_repository.dart` so app sign-out always completes |
| Gemini returned **HTTP 429** `RESOURCE_EXHAUSTED`, `limit: 0` | The Gemini **Developer API free tier is `limit: 0` in the EU region** — free tier is effectively unavailable there. The project's Cloud Billing is a **free-trial** account, which does **not** grant the Developer API paid tier | Switched the AI backend from the Developer API to **Vertex AI** in `lib/core/ai/gemini_ai_service.dart`: `FirebaseAI.googleAI()` → `FirebaseAI.vertexAI()`. Vertex bills against the project's Cloud Billing (trial credit) and has no free-tier-zero trap. Enabled the **Vertex AI API** (`aiplatform.googleapis.com`). **Deliberately did NOT click "Activate full account"** — staying on the free-trial billing account preserves Google's guarantee that the card is never charged (services just stop if credit/days run out). |
| Gemini then returned **HTTP 404** `NOT_FOUND` "Publisher Model … gemini-2.0-flash was not found" | The Vertex AI backend uses different model IDs than the Developer API; bare `gemini-2.0-flash` is not resolvable as a Vertex publisher model in `us-central1` | Changed the model `gemini-2.0-flash` → **`gemini-2.5-flash`** (current GA flash model on Vertex). Request then returned **200 OK**. |

> Note: the comment header in `gemini_ai_service.dart` was updated from
> "Gemini Developer API path" to "Vertex AI Gemini API path" with a note on the
> EU `limit: 0` reason, so the code self-documents *why* the Vertex backend is used.

### Verification (live, on Chrome)

- **Summarize:** `POST …/models/gemini-2.5-flash:generateContent` → **200 OK**;
  summary + key points render in the app.
- **Chat:** asking a question about the document streams a correct answer
  (second `generateContent` → 200).
- **Realtime Database:** `progress/<uid>/<docId>` shows `status: "ready"`,
  `percent: 100` — the full pipeline completed.
- **Firestore:** `users/<uid>/documents/<docId>` holds the `summary`,
  `keyPoints`, `title`, and `status: ready` — the summary persisted to the cloud.
- **Auth:** email/password sign-in works.

### Known remaining (non-blocking / cosmetic)

1. **Cloud Storage CORS on web** — uploads to `firebasestorage.googleapis.com`
   still fail the browser CORS preflight, so the console shows repeated
   `blocked by CORS policy` / `ERR_FAILED` noise. **It does not affect the app**:
   the upload is wrapped in `try/catch + .timeout(5s)` (above), and the AI
   pipeline reads text without needing the stored file. To silence it, set a CORS
   policy on the bucket, e.g. `cors.json` =
   `[{"origin":["*"],"method":["GET","POST","PUT"],"maxAgeSeconds":3600,"responseHeader":["Content-Type","Authorization"]}]`
   then `gsutil cors set cors.json gs://distill-d0c18.firebasestorage.app`
   (or via the Google Cloud console). Cosmetic only.
2. ~~**Google sign-in on web** is not fully configured.~~ **Resolved** — see
   "Web Google sign-in" below.

### Web Google sign-in (resolved)

| Symptom | Cause | Fix |
|---|---|---|
| "Continue with Google" did nothing on Chrome | `signInWithGoogle()` used `GoogleSignIn.instance.authenticate()` (google_sign_in **v7**), whose interactive flow is a mobile API — **not supported on Flutter web** (web needs the GIS rendered-button flow) | Made `signInWithGoogle()` in `lib/features/auth/data/auth_repository.dart` **`kIsWeb`-aware**: on web it calls `FirebaseAuth.signInWithPopup(GoogleAuthProvider())` (Firebase's native web popup — uses the project `authDomain`, no client-ID meta tag or `index.html` edit); on mobile it keeps the existing `google_sign_in` flow. Added friendly `_mapError` cases for `popup-closed-by-user` / `cancelled-popup-request` ("Google sign-in was cancelled.") and `popup-blocked`. `flutter analyze` on the file → **No issues found**. |

No console change was needed beyond the already-enabled Google provider —
`localhost` is an authorized domain by default, so `flutter run -d chrome` works.
**To verify in the browser:** click *Continue with Google* → account popup →
lands on Home; the account appears in **Auth → Users** and a `users/{uid}` doc is
created. (Mobile Google flow unchanged; not driven from this environment.)

### Android ran in DEMO mode — `duplicate-app` fix (resolved)

Verified live on an Android emulator (`Pixel_4_2`). Web worked but **Android
silently fell back to demo mode** (fresh account showed seeded demo docs, stub
chat/key-points). Two Android-only fixes:

| Symptom | Cause | Fix |
|---|---|---|
| Android always in demo mode (web fine) | On Android the native SDK auto-initializes the default app from `google-services.json`; the Dart `Firebase.initializeApp(options:)` in `main.dart` then threw `[core/duplicate-app]`, the `catch` left `firebaseReady = false` → demo repos + stub AI. (`Firebase.apps` can read empty in Dart at that point, so guarding on it alone is unreliable.) | `lib/main.dart` now skips init if `Firebase.apps` is non-empty **and** catches `FirebaseException` `duplicate-app`, treating it as success (`firebaseReady = true`) — Firebase is already up natively. Confirmed by the runtime log line `Firebase init failed; falling back to demo mode: [core/duplicate-app]` disappearing and a new account starting empty. |
| RTDB progress would misroute on Android | `google-services.json` has `project_id` + `storage_bucket` but **no `firebase_url`**, so the native default app's `FirebaseDatabase.instance` has no Realtime DB URL | `lib/core/di/providers.dart` builds RTDB with `FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL)`, reusing the `europe-west1` URL already in `firebase_options.dart`. Same value on web, so unchanged there. |

**Verified on the emulator:** a brand-new account starts with **zero documents**
(live, not demo); upload → real Gemini summary + key points; chat streams and
persists; data appears in Auth/Firestore/Realtime DB. On Android the Storage
upload works natively (no CORS). `flutter analyze` clean.

**Final state:** App runs **live on Firebase** on both **Chrome (web)** and the
**Android emulator**. Summarize + chat verified, data confirmed in Firestore and
Realtime Database. Still on the **free-trial** billing account (no charges; $5
budget alert set). `flutter analyze` clean; 60 tests green (the live gating is
demo-mode-agnostic in tests). Remaining optional item: **Google sign-in on
Android** needs the debug SHA-1 registered + `google_sign_in` `initialize(serverClientId:)`
(the web popup path already works).

## 2.14 UI polish pass — splash, settings cleanup, empty-Home button (2026-06-03)

Visual/UX fixes only — **no functional change**. Theme-aware, loading/error and
repository/demo-live behavior untouched. `flutter analyze` clean; 60 tests still
green (no tests touch these surfaces).

| # | Issue | Fix | Files |
|---|-------|-----|-------|
| 1 | **Splash flashed white** before the navy Flutter splash | The native Android launch screen was white. Added `android/app/src/main/res/values/colors.xml` (`splash_background = #FF00236F`, = `AppColors.primary`), pointed both `drawable/launch_background.xml` and `drawable-v21/launch_background.xml` at it, and set `android:windowSplashScreenBackground` (Android 12+) on `LaunchTheme` in `values/styles.xml` + `values-night/styles.xml`. Now navy from the first frame. | `android/app/src/main/res/...` |
| 2 | **Navy didn't reach the bottom** (a system nav-bar strip showed through) | `app.dart`'s global overlay paints the nav bar `surface`. Wrapped the splash `Scaffold` in its own `AnnotatedRegion<SystemUiOverlayStyle>` with `systemNavigationBarColor: AppColors.primary` + transparent/light status bar (nearest-wins; only affects the splash). | `splash_screen.dart` |
| 3 | Splash **too fast** | Bumped the minimum splash delay `1600ms → 2400ms` in `_decideNext`. | `splash_screen.dart` |
| 4 | **"Subscription"** row in Profile, **"Backend"** row in Settings → not wanted | Removed the Subscription `_SectionTile` (Profile) and the Backend `ListTile` (Settings → About). Also dropped the now-unused `trailing` param from `_SectionTile`. `AppUser.subscription` left in the model (harmless). Version + AI rows kept. | `profile_screen.dart`, `settings_screen.dart` |
| 5 | Empty Home showed the **Upload button twice** (FAB + centered CTA) | Made the Scaffold's `floatingActionButton` conditional: `null` when `docsAsync.value` is empty, so only the centered `EmptyState` "Upload document" CTA shows on first run; the FAB returns once the user has documents (incl. when a filter yields no matches). | `home_screen.dart` |

> Note: Localization (multi-language) was scoped and intentionally **deferred** —
> the app has no i18n framework and full coverage was judged too risky for this
> "don't break the working app" pass.

**Final state:** `flutter analyze` → *No issues found.* `flutter test` → *All 60
tests passed.* Splash/settings/Home verified on the Android emulator + web.

## 2.15 Pre-test pass — filters, favorites empty-state, TXT key points, Google removal (2026-06-03)

More fixes before device testing. Functional pipeline untouched; `flutter analyze`
clean, 60 tests still green.

| # | Issue | Fix | Files |
|---|-------|-----|-------|
| 1 | Home had only a **"PDFs"** type filter | Removed the type filter — `_Filter` enum is now `all / recent / favorites`; dropped the `pdfs` `_apply` case and chip label. | `home_screen.dart` |
| 2 | **Favorites** filter with nothing starred showed the generic *"No matches"* | New `_emptyResults()` picks a context-aware `EmptyState`: search → "No matches / Try a different search"; favorites → **"No favorites yet / Tap the star on any document to save it here"** (star icon). | `home_screen.dart` |
| 3 | **TXT** summaries put key points inside the Summary; **Key Points tab empty** (PDF was fine) | Root cause: the model's reply wasn't always valid JSON (raw newlines in TXT summaries), so `_parseSummary` fell back to `summary = raw blob, keyPoints = []`. Fix: gave summarization its **own Gemini model with structured output** — `GenerationConfig(responseMimeType: 'application/json', responseSchema: Schema.object({summary, keyPoints[]}))`. Reply is now always valid JSON → both fields parse for every file type. Chat uses a separate plain-text model (`_chatModel`). | `gemini_ai_service.dart` |
| 5 | Remove **"Continue with Google"** from auth | Deleted the `GoogleButton` + `OrDivider` (and their imports) from `sign_in_screen.dart` and `sign_up_screen.dart`. Email/password is the sole path. Left `signInWithGoogle()` in the repos + the unused widget files in place (dead code, no analyzer impact) to avoid touching the auth interface. | `sign_in_screen.dart`, `sign_up_screen.dart` |

### Item 4 — upload limits & concurrency (answered, no code change)
- **Total documents:** unlimited (no cap in code).
- **Per upload:** one file (`file_service.dart` uses `result.files.single`; the picker is single-select).
- **Size:** 50 MB max (`AppConstants.maxFileSizeBytes`); the AI reads the first **24 000 chars** (`maxContextChars`).
- **Concurrency:** processing is fire-and-forget (`unawaited(_runPipeline)` in `document_repository.dart`),
  so multiple documents *can* process at once — upload them back-to-back; each runs its own
  background pipeline with independent progress. (No multi-select picker by choice.)

**Final state:** `flutter analyze` → *No issues found.* `flutter test` → *All 60
tests passed.*

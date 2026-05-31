import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/demo_auth_repository.dart';
import '../../features/auth/data/models/app_user.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/chat/data/demo_chat_repository.dart';
import '../../features/chat/data/models/chat_message.dart';
import '../../features/documents/data/demo_document_repository.dart';
import '../../features/documents/data/document_repository.dart';
import '../../features/documents/data/models/document_model.dart';
import '../ai/ai_service.dart';
import '../ai/gemini_ai_service.dart';
import '../ai/stub_ai_service.dart';
import '../app_config.dart';
import '../../shared/services/file_service.dart';
import '../../shared/services/text_extraction_service.dart';

/// Whether the app is wired to a real Firebase project. Overridden in main
/// after a successful Firebase.initializeApp; defaults to the build flag.
final firebaseReadyProvider = Provider<bool>((_) => kFirebaseConfigured);

// ---- Stateless services ----

final aiServiceProvider = Provider<AiService>((ref) {
  if (ref.watch(firebaseReadyProvider)) return GeminiAiService();
  return const StubAiService();
});

final fileServiceProvider = Provider<FileService>((_) => const FileService());

final textExtractionProvider =
    Provider<TextExtractionService>((_) => const TextExtractionService());

// ---- Auth ----

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ref.watch(firebaseReadyProvider)) {
    return FirebaseAuthRepository(
        FirebaseAuth.instance, FirebaseFirestore.instance);
  }
  final repo = DemoAuthRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// Source of truth for the signed-in user.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Convenience accessor for the current user (null when signed out / loading).
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).value;
});

// ---- Documents (scoped to the current user) ----

final documentRepositoryProvider = Provider<DocumentRepository?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final ai = ref.watch(aiServiceProvider);

  if (ref.watch(firebaseReadyProvider)) {
    return FirebaseDocumentRepository(
      uid: user.uid,
      db: FirebaseFirestore.instance,
      storage: FirebaseStorage.instance,
      rtdb: FirebaseDatabase.instance,
      ai: ai,
      extractor: ref.watch(textExtractionProvider),
    );
  }
  final repo = DemoDocumentRepository(
      ai: ai, extractor: ref.watch(textExtractionProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

/// Live list of the user's documents.
final documentsStreamProvider =
    StreamProvider<List<DocumentModel>>((ref) async* {
  final repo = ref.watch(documentRepositoryProvider);
  if (repo == null) {
    yield const [];
    return;
  }
  yield* repo.watchDocuments();
});

/// Live stream of a single document (used by detail + processing screens).
final documentByIdProvider =
    StreamProvider.family<DocumentModel?, String>((ref, id) async* {
  final repo = ref.watch(documentRepositoryProvider);
  if (repo == null) {
    yield null;
    return;
  }
  yield* repo.watchDocument(id);
});

/// Live processing progress (RTDB-backed) for a document being analyzed.
final processingProgressProvider =
    StreamProvider.family<ProcessingProgress?, String>((ref, id) async* {
  final repo = ref.watch(documentRepositoryProvider);
  if (repo == null) {
    yield null;
    return;
  }
  yield* repo.watchProgress(id);
});

// ---- Chat (scoped to the current user) ----

final chatRepositoryProvider = Provider<ChatRepository?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  if (ref.watch(firebaseReadyProvider)) {
    return FirebaseChatRepository(
        uid: user.uid, db: FirebaseFirestore.instance);
  }
  final repo = DemoChatRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// Live list of the user's conversations (most recent first).
final chatsStreamProvider = StreamProvider<List<ChatSummary>>((ref) async* {
  final repo = ref.watch(chatRepositoryProvider);
  if (repo == null) {
    yield const [];
    return;
  }
  yield* repo.watchChats();
});

/// Persisted messages for one document chat (chatId == documentId).
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, id) async* {
  final repo = ref.watch(chatRepositoryProvider);
  if (repo == null) {
    yield const [];
    return;
  }
  yield* repo.watchMessages(id);
});

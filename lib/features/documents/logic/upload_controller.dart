import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../shared/services/file_service.dart';

/// Holds the currently picked file (if any) before the user commits to upload.
class UploadController extends Notifier<AsyncValue<PickedDocument?>> {
  @override
  AsyncValue<PickedDocument?> build() => const AsyncData(null);

  Future<void> pick() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(fileServiceProvider).pickDocument());
  }

  void clear() => state = const AsyncData(null);

  /// Kicks off the upload+processing pipeline. Returns the new document id, or
  /// null if there is nothing to upload.
  Future<String?> startUpload() async {
    final picked = state.value;
    final repo = ref.read(documentRepositoryProvider);
    if (picked == null || repo == null) return null;
    final id = await repo.uploadAndProcess(
      fileName: picked.name,
      type: picked.type,
      sizeBytes: picked.sizeBytes,
      bytes: picked.bytes,
    );
    clear();
    return id;
  }
}

final uploadControllerProvider =
    NotifierProvider<UploadController, AsyncValue<PickedDocument?>>(
        UploadController.new);

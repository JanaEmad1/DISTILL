import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';

/// Drives auth form submissions. State is `AsyncValue<void>`: loading while a
/// request is in flight, error when it fails. Navigation on success is handled
/// by the router reacting to authStateProvider.
class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(authRepositoryProvider).signIn(email, password));
  }

  Future<void> signUp(String name, String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(authRepositoryProvider).signUp(name, email, password));
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(authRepositoryProvider).signInWithGoogle());
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
        () => ref.read(authRepositoryProvider).sendPasswordReset(email));
    state = result;
    return !result.hasError;
  }

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

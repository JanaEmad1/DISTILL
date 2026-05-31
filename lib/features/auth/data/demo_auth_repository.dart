import 'dart:async';

import 'auth_repository.dart';
import 'models/app_user.dart';

/// In-memory AuthRepository for DEMO mode (no Firebase) and tests. Accepts any
/// well-formed credentials and persists the session only for the app's run.
class DemoAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  AppUser? get currentUser => _user;

  void _emit(AppUser? u) {
    _user = u;
    _controller.add(u);
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (password.length < 6) {
      throw AuthFailure('Incorrect email or password.');
    }
    final user = AppUser(
      uid: 'demo-user',
      email: email.trim(),
      displayName: _nameFromEmail(email),
      docCount: 4,
      questionCount: 12,
      storageBytes: 18 * 1024 * 1024,
    );
    _emit(user);
    return user;
  }

  @override
  Future<AppUser> signUp(String name, String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final user = AppUser(
      uid: 'demo-user',
      email: email.trim(),
      displayName: name.trim(),
    );
    _emit(user);
    return user;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final user = const AppUser(
      uid: 'demo-user',
      email: 'sarah.chen@email.com',
      displayName: 'Sarah Chen',
      docCount: 24,
      questionCount: 156,
      storageBytes: 45 * 1024 * 1024,
    );
    _emit(user);
    return user;
  }

  @override
  Future<void> sendPasswordReset(String email) async =>
      Future<void>.delayed(const Duration(milliseconds: 300));

  @override
  Future<void> updateProfileName(String name) async {
    if (_user != null) _emit(_user!.copyWith(displayName: name.trim()));
  }

  @override
  Future<void> signOut() async => _emit(null);

  String _nameFromEmail(String email) {
    final local = email.split('@').first.replaceAll(RegExp(r'[._]'), ' ');
    return local
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  void dispose() => _controller.close();
}

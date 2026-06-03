import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import 'models/app_user.dart';

/// Typed auth failure with a user-friendly message the UI can show directly.
class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Single point of contact for authentication. UI/logic depend on this
/// interface; [FirebaseAuthRepository] and [DemoAuthRepository] implement it.
abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;
  Future<AppUser> signIn(String email, String password);
  Future<AppUser> signUp(String name, String email, String password);
  Future<AppUser> signInWithGoogle();
  Future<void> sendPasswordReset(String email);
  Future<void> updateProfileName(String name);
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  @override
  Stream<AppUser?> authStateChanges() =>
      _auth.authStateChanges().asyncMap(_toAppUser);

  @override
  AppUser? get currentUser {
    final u = _auth.currentUser;
    if (u == null) return null;
    return AppUser(uid: u.uid, email: u.email ?? '', displayName: u.displayName);
  }

  Future<AppUser?> _toAppUser(User? u) async {
    if (u == null) return null;
    final snap = await _userDoc(u.uid).get();
    if (snap.exists) return AppUser.fromMap(u.uid, snap.data()!);
    return AppUser(
      uid: u.uid,
      email: u.email ?? '',
      displayName: u.displayName,
      photoUrl: u.photoURL,
    );
  }

  Future<AppUser> _ensureUserDoc(User u, {String? name}) async {
    final ref = _userDoc(u.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      final user = AppUser(
        uid: u.uid,
        email: u.email ?? '',
        displayName: name ?? u.displayName,
        photoUrl: u.photoURL,
      );
      await ref.set(user.toMap());
      return user;
    }
    return AppUser.fromMap(u.uid, snap.data()!);
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return _ensureUserDoc(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapError(e));
    }
  }

  @override
  Future<AppUser> signUp(String name, String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      await cred.user!.updateDisplayName(name.trim());
      return _ensureUserDoc(cred.user!, name: name.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapError(e));
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      // Web: google_sign_in v7's interactive authenticate() is not supported in
      // the browser, so use Firebase Auth's native popup (handled via the
      // project's authDomain — no client-ID meta tag needed).
      if (kIsWeb) {
        final cred = await _auth.signInWithPopup(GoogleAuthProvider());
        return _ensureUserDoc(cred.user!);
      }
      // Mobile/desktop: the instance-based google_sign_in flow.
      final google = GoogleSignIn.instance;
      final account = await google.authenticate();
      final auth = account.authentication;
      final credential =
          GoogleAuthProvider.credential(idToken: auth.idToken);
      final cred = await _auth.signInWithCredential(credential);
      return _ensureUserDoc(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapError(e));
    } catch (e) {
      throw AuthFailure('Google sign-in failed. Please try again.');
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapError(e));
    }
  }

  @override
  Future<void> updateProfileName(String name) async {
    final u = _auth.currentUser;
    if (u == null) throw AuthFailure('Not signed in.');
    await u.updateDisplayName(name.trim());
    await _userDoc(u.uid).set(
      {'displayName': name.trim()},
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> signOut() async {
    try { await GoogleSignIn.instance.signOut(); } catch (_) {}
    await _auth.signOut();
  }

  String _mapError(FirebaseAuthException e) => switch (e.code) {
        'invalid-email' => 'That email address looks invalid.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Incorrect email or password.',
        'email-already-in-use' => 'An account already exists for that email.',
        'weak-password' => 'Please choose a stronger password (6+ characters).',
        'network-request-failed' => 'No internet connection.',
        'popup-closed-by-user' ||
        'cancelled-popup-request' =>
          'Google sign-in was cancelled.',
        'popup-blocked' =>
          'Your browser blocked the sign-in popup. Allow popups and try again.',
        _ => e.message ?? 'Authentication failed. Please try again.',
      };
}

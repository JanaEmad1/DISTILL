import 'package:distill/features/auth/data/models/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fixtures.dart';

void main() {
  group('AppUser.initial', () {
    test('uses the display name when present', () {
      expect(Fixtures.user(displayName: 'Bob').initial, 'B');
    });

    test('falls back to email when name is blank', () {
      expect(Fixtures.user(displayName: '  ', email: 'zoe@test.com').initial,
          'Z');
    });

    test('is "?" when both name and email are empty', () {
      const u = AppUser(uid: '1', email: '', displayName: null);
      expect(u.initial, '?');
    });
  });

  group('AppUser serialization', () {
    test('toMap/fromMap roundtrips', () {
      final user = Fixtures.user();
      final restored = AppUser.fromMap(user.uid, user.toMap());

      expect(restored.uid, user.uid);
      expect(restored.email, user.email);
      expect(restored.displayName, user.displayName);
      expect(restored.docCount, user.docCount);
      expect(restored.questionCount, user.questionCount);
      expect(restored.storageBytes, user.storageBytes);
      expect(restored.subscription, user.subscription);
    });

    test('fromMap defaults missing fields', () {
      final user = AppUser.fromMap('uid-9', const {});
      expect(user.email, '');
      expect(user.docCount, 0);
      expect(user.subscription, 'FREE');
    });
  });

  test('copyWith keeps uid/email and overrides counts', () {
    final user = Fixtures.user();
    final updated = user.copyWith(displayName: 'Renamed', docCount: 99);
    expect(updated.uid, user.uid);
    expect(updated.email, user.email);
    expect(updated.displayName, 'Renamed');
    expect(updated.docCount, 99);
  });
}

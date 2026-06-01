import 'package:distill/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email(null), 'Email is required');
      expect(Validators.email('   '), 'Email is required');
    });

    test('rejects malformed addresses', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('missing@domain'), isNotNull);
      expect(Validators.email('@no-local.com'), isNotNull);
    });

    test('accepts well-formed addresses', () {
      expect(Validators.email('alice@test.com'), isNull);
      expect(Validators.email('a.b+tag@sub.example.co'), isNull);
      expect(Validators.email('  alice@test.com  '), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects empty', () {
      expect(Validators.password(''), 'Password is required');
      expect(Validators.password(null), 'Password is required');
    });

    test('rejects fewer than 6 characters', () {
      expect(Validators.password('12345'), 'Use at least 6 characters');
    });

    test('accepts 6 or more characters', () {
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('a-long-password'), isNull);
    });
  });

  group('Validators.required', () {
    test('rejects empty with field name', () {
      expect(Validators.required('', field: 'Name'), 'Name is required');
      expect(Validators.required('   '), 'This field is required');
    });

    test('accepts non-empty', () {
      expect(Validators.required('Alice'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects empty', () {
      expect(Validators.confirmPassword('', 'secret123'),
          'Please confirm your password');
      expect(Validators.confirmPassword(null, 'secret123'),
          'Please confirm your password');
    });

    test('rejects a mismatch', () {
      expect(Validators.confirmPassword('different', 'secret123'),
          'Passwords do not match');
    });

    test('accepts an exact match', () {
      expect(Validators.confirmPassword('secret123', 'secret123'), isNull);
    });
  });
}

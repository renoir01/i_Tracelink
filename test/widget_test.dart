import 'package:flutter_test/flutter_test.dart';
import 'package:itracelink/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('stores a registered user's profile fields', () {
      final user = UserModel(
        id: 'user-123',
        userType: 'farmer',
        name: 'Aline Mukamana',
        email: 'aline@example.com',
        phone: '+250780000000',
        language: 'rw',
        isVerified: false,
      );

      expect(user.id, 'user-123');
      expect(user.userType, 'farmer');
      expect(user.displayName, 'Aline Mukamana');
      expect(user.isVerified, isFalse);
    });

    test('copyWith changes language without changing role or identity', () {
      final user = UserModel(
        id: 'user-123',
        userType: 'farmer',
        name: 'Aline Mukamana',
        email: 'aline@example.com',
        phone: '+250780000000',
        language: 'en',
      );

      final updated = user.copyWith(language: 'rw');

      expect(updated.language, 'rw');
      expect(updated.id, user.id);
      expect(updated.email, user.email);
      expect(updated.userType, user.userType);
    });
  });
}

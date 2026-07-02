import 'package:flutter_test/flutter_test.dart';
import 'package:omniforge_ai/core/security/encryption_service.dart';

void main() {
  final enc = EncryptionService.instance;

  group('EncryptionService', () {
    test('generateKey produces a 256-bit (32-byte) key', () {
      final key = enc.generateKey();
      expect(key.length, 32);
    });

    test('generateSalt produces a 16-byte salt by default', () {
      final salt = enc.generateSalt();
      expect(salt.length, 16);
    });

    test('generateSalt honors a custom length', () {
      final salt = enc.generateSalt(24);
      expect(salt.length, 24);
    });

    test('two calls to generateKey produce different keys', () {
      final k1 = enc.generateKey();
      final k2 = enc.generateKey();
      expect(k1, isNot(equals(k2)));
    });

    test('encrypt then decrypt round-trips the original plaintext', () {
      final key = enc.generateKey();
      const plaintext = 'sk-abc123-my-super-secret-api-key';
      final encrypted = enc.encrypt(plaintext, key);
      final decrypted = enc.decrypt(encrypted, key);
      expect(decrypted, plaintext);
    });

    test('round-trips text containing unicode characters', () {
      final key = enc.generateKey();
      const plaintext = 'API key for 日本語 test 🔑';
      final encrypted = enc.encrypt(plaintext, key);
      expect(enc.decrypt(encrypted, key), plaintext);
    });

    test('encrypted output differs from the plaintext', () {
      final key = enc.generateKey();
      const plaintext = 'test-api-key-12345';
      final encrypted = enc.encrypt(plaintext, key);
      expect(encrypted, isNot(plaintext));
    });

    test('encrypting the same plaintext twice yields different ciphertext '
        '(random IV per call)', () {
      final key = enc.generateKey();
      const plaintext = 'same-plaintext-both-times';
      final enc1 = enc.encrypt(plaintext, key);
      final enc2 = enc.encrypt(plaintext, key);
      expect(enc1, isNot(enc2));
      // But both still decrypt correctly.
      expect(enc.decrypt(enc1, key), plaintext);
      expect(enc.decrypt(enc2, key), plaintext);
    });

    test('decrypting with the wrong key throws instead of returning '
        'corrupted plaintext silently', () {
      final key1 = enc.generateKey();
      final key2 = enc.generateKey();
      const plaintext = 'secret-data';
      final encrypted = enc.encrypt(plaintext, key1);
      expect(() => enc.decrypt(encrypted, key2), throwsA(anything));
    });

    test('deriveKey is deterministic for the same passphrase and salt', () {
      final salt = enc.generateSalt();
      final k1 = enc.deriveKey('correct horse battery staple', salt);
      final k2 = enc.deriveKey('correct horse battery staple', salt);
      expect(k1, equals(k2));
    });

    test('deriveKey produces different keys for different salts', () {
      final k1 = enc.deriveKey('same-passphrase', enc.generateSalt());
      final k2 = enc.deriveKey('same-passphrase', enc.generateSalt());
      expect(k1, isNot(equals(k2)));
    });

    test('hash produces a consistent digest for the same input', () {
      const input = 'hello-world';
      expect(enc.hash(input), enc.hash(input));
    });

    test('hash produces different digests for different inputs', () {
      expect(enc.hash('abc'), isNot(enc.hash('xyz')));
    });
  });
}

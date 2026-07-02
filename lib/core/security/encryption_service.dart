import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// AES-256-GCM encryption service for sensitive data at rest.
class EncryptionService {
  static const int _keyLength = 32;  // 256-bit
  static const int _ivLength = 12;   // 96-bit GCM
  static const int _tagLength = 128; // 128-bit GCM tag

  static EncryptionService? _instance;
  static EncryptionService get instance =>
      _instance ??= EncryptionService._();
  EncryptionService._();

  /// Derives a 256-bit key using PBKDF2-HMAC-SHA256.
  Uint8List deriveKey(String passphrase, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(Pbkdf2Parameters(salt, 100000, _keyLength));
    final key = Uint8List(_keyLength);
    pbkdf2.deriveKey(
      Uint8List.fromList(utf8.encode(passphrase)), 0, key, 0);
    return key;
  }

  /// Encrypts [plaintext] using AES-256-GCM.
  /// Returns base64-encoded [iv || ciphertext+tag].
  String encrypt(String plaintext, Uint8List key) {
    final iv = _secureRandomBytes(_ivLength);
    final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));

    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(true, AEADParameters(KeyParameter(key), _tagLength, iv, Uint8List(0)));

    final ciphertext = Uint8List(cipher.getOutputSize(plaintextBytes.length));
    int len = cipher.processBytes(plaintextBytes, 0, plaintextBytes.length, ciphertext, 0);
    cipher.doFinal(ciphertext, len);

    final combined = Uint8List(_ivLength + ciphertext.length);
    combined.setRange(0, _ivLength, iv);
    combined.setRange(_ivLength, combined.length, ciphertext);
    return base64Encode(combined);
  }

  /// Decrypts a value produced by [encrypt].
  String decrypt(String encryptedData, Uint8List key) {
    final combined = base64Decode(encryptedData);
    final iv = combined.sublist(0, _ivLength);
    final ciphertext = combined.sublist(_ivLength);

    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(false, AEADParameters(KeyParameter(key), _tagLength, iv, Uint8List(0)));

    final plaintext = Uint8List(cipher.getOutputSize(ciphertext.length));
    int len = cipher.processBytes(ciphertext, 0, ciphertext.length, plaintext, 0);
    cipher.doFinal(plaintext, len);
    return utf8.decode(plaintext);
  }

  /// SHA-256 hash of [input].
  String hash(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  /// Generates a cryptographically secure random byte array.
  Uint8List _secureRandomBytes(int length) {
    final rng = math.Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rng.nextInt(256)));
  }

  /// Generates a 256-bit random encryption key.
  Uint8List generateKey() => _secureRandomBytes(_keyLength);

  /// Generates a 16-byte random salt.
  Uint8List generateSalt([int length = 16]) => _secureRandomBytes(length);
}

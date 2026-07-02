import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../error/exceptions.dart';

class SecureStorageService {
  static SecureStorageService? _instance;
  static SecureStorageService get instance =>
      _instance ??= SecureStorageService._();
  SecureStorageService._();

  late final FlutterSecureStorage _storage;

  void init() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        sharedPreferencesName: 'omniforge_secure_prefs',
        preferencesKeyPrefix: 'OF_',
        resetOnError: false,
      ),
    );
  }

  static const String _keyPrefix = 'api_key_';

  Future<void> saveApiKey(String provider, String apiKey) async {
    try {
      await _storage.write(
          key: '$_keyPrefix${provider.toLowerCase()}', value: apiKey.trim());
    } catch (e) {
      throw StorageException.writeError('api_key_$provider');
    }
  }

  Future<String?> getApiKey(String provider) async {
    try {
      return await _storage.read(
          key: '$_keyPrefix${provider.toLowerCase()}');
    } catch (e) {
      throw StorageException.readError('api_key_$provider');
    }
  }

  Future<void> deleteApiKey(String provider) async {
    try {
      await _storage.delete(key: '$_keyPrefix${provider.toLowerCase()}');
    } catch (e) {
      throw StorageException(
          message: 'Failed to delete API key for $provider',
          code: 'DELETE_ERROR');
    }
  }

  Future<bool> hasApiKey(String provider) async {
    final key = await getApiKey(provider);
    return key != null && key.isNotEmpty;
  }

  Future<Map<String, String>> getAllApiKeys() async {
    try {
      final all = await _storage.readAll();
      return Map.fromEntries(all.entries
          .where((e) => e.key.startsWith(_keyPrefix))
          .map((e) =>
              MapEntry(e.key.substring(_keyPrefix.length), e.value)));
    } catch (e) {
      throw StorageException(
          message: 'Failed to read API keys', code: 'READ_ALL_ERROR');
    }
  }

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw StorageException.writeError(key);
    }
  }

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw StorageException.readError(key);
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw StorageException(
          message: 'Failed to delete: $key', code: 'DELETE_ERROR');
    }
  }

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw StorageException(
          message: 'Failed to clear secure storage', code: 'CLEAR_ERROR');
    }
  }

  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (_) {
      return false;
    }
  }
}

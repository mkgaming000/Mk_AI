import 'package:uuid/uuid.dart';
import '../../core/constants/provider_constants.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/storage/database/hive_boxes.dart';
import '../models/api_key_model.dart';

class ProviderRepositoryImpl {
  final SecureStorageService _secure;
  final LocalStorageService _local;
  final _uuid = const Uuid();

  ProviderRepositoryImpl({
    required SecureStorageService secureStorage,
    required LocalStorageService localStorage,
  })  : _secure = secureStorage,
        _local = localStorage;

  Future<void> saveApiKey({
    required String providerId,
    required String apiKey,
    String? baseUrl,
    Map<String, dynamic>? additionalConfig,
  }) async {
    await _secure.saveApiKey(providerId, apiKey);
    final existing = getApiKeyMetadata(providerId);
    final model = ApiKeyModel(
      id: existing?.id ?? _uuid.v4(),
      providerId: providerId,
      providerName: _nameFor(providerId),
      addedAt: existing?.addedAt ?? DateTime.now(),
      isValid: true,
      maskedKey: apiKey.length > 8
          ? '${apiKey.substring(0, 4)}${'*' * (apiKey.length - 8)}${apiKey.substring(apiKey.length - 4)}'
          : '****',
      baseUrl: baseUrl,
      additionalConfig: additionalConfig,
    );
    await HiveBoxes.apiKeys.put(providerId, model);
  }

  Future<String?> getApiKey(String providerId) =>
      _secure.getApiKey(providerId);
  Future<bool> hasApiKey(String providerId) =>
      _secure.hasApiKey(providerId);
  ApiKeyModel? getApiKeyMetadata(String providerId) =>
      HiveBoxes.apiKeys.get(providerId);
  List<ApiKeyModel> getAllApiKeyMetadata() =>
      HiveBoxes.apiKeys.values.toList();

  Future<void> deleteApiKey(String providerId) async {
    await _secure.deleteApiKey(providerId);
    await HiveBoxes.apiKeys.delete(providerId);
  }

  Future<void> markApiKeyUsed(String providerId) async {
    final m = getApiKeyMetadata(providerId);
    if (m != null) {
      m.lastUsed = DateTime.now();
      await HiveBoxes.apiKeys.put(providerId, m);
    }
  }

  String _nameFor(String providerId) {
    try {
      return ProviderConstants.providerNames[ProviderConstants.chatProviders
              .firstWhere((p) => p.name.toLowerCase() == providerId.toLowerCase())] ??
          providerId;
    } catch (_) {
      return providerId;
    }
  }

  String get defaultProvider =>
      _local.getStringOrDefault('default_provider', 'openai');
  String get defaultModel =>
      _local.getStringOrDefault('default_model', 'gpt-4o');

  Future<void> setDefaultProvider(String id) =>
      _local.setString('default_provider', id);
  Future<void> setDefaultModel(String id) =>
      _local.setString('default_model', id);
  Future<void> setDefaultProviderAndModel(String provider, String model) async {
    await setDefaultProvider(provider);
    await setDefaultModel(model);
  }

  List<String> getConfiguredProviders() => HiveBoxes.apiKeys.values
      .where((k) => k.isActive && k.isValid)
      .map((k) => k.providerId)
      .toList();

  String get ollamaBaseUrl =>
      _local.getStringOrDefault('ollama_base_url', 'http://10.0.2.2:11434');
  Future<void> setOllamaBaseUrl(String url) =>
      _local.setString('ollama_base_url', url);
}

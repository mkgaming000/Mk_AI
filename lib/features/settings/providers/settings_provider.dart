import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../data/models/api_key_model.dart';
import '../../../data/repositories/provider_repository_impl.dart';

// ── Theme ─────────────────────────────────────────────────────────────────

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  final storage = ref.read(localStorageProvider);
  switch (storage.themeMode) {
    case 'light': return ThemeMode.light;
    case 'system': return ThemeMode.system;
    default: return ThemeMode.dark;
  }
});

// ── Settings State ────────────────────────────────────────────────────────

class AppSettings {
  final bool streamingEnabled;
  final bool biometricEnabled;
  final bool analyticsEnabled;
  final bool notificationsEnabled;
  final bool usageTrackingEnabled;
  final double messageFontSize;
  final double terminalFontSize;
  final String codeTheme;
  final String defaultProvider;
  final String defaultModel;
  final double defaultTemperature;

  const AppSettings({
    this.streamingEnabled = true,
    this.biometricEnabled = false,
    this.analyticsEnabled = true,
    this.notificationsEnabled = true,
    this.usageTrackingEnabled = true,
    this.messageFontSize = 15.0,
    this.terminalFontSize = 13.0,
    this.codeTheme = 'github-dark',
    this.defaultProvider = 'openai',
    this.defaultModel = 'gpt-4o',
    this.defaultTemperature = 0.7,
  });

  AppSettings copyWith({
    bool? streamingEnabled, bool? biometricEnabled,
    bool? analyticsEnabled, bool? notificationsEnabled,
    bool? usageTrackingEnabled, double? messageFontSize,
    double? terminalFontSize, String? codeTheme,
    String? defaultProvider, String? defaultModel, double? defaultTemperature,
  }) =>
      AppSettings(
        streamingEnabled: streamingEnabled ?? this.streamingEnabled,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        usageTrackingEnabled: usageTrackingEnabled ?? this.usageTrackingEnabled,
        messageFontSize: messageFontSize ?? this.messageFontSize,
        terminalFontSize: terminalFontSize ?? this.terminalFontSize,
        codeTheme: codeTheme ?? this.codeTheme,
        defaultProvider: defaultProvider ?? this.defaultProvider,
        defaultModel: defaultModel ?? this.defaultModel,
        defaultTemperature: defaultTemperature ?? this.defaultTemperature,
      );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final LocalStorageService _storage;
  final ProviderRepositoryImpl _providerRepo;

  SettingsNotifier(this._storage, this._providerRepo)
      : super(AppSettings(
          streamingEnabled: _storage.streamingEnabled,
          biometricEnabled: _storage.biometricEnabled,
          analyticsEnabled: _storage.analyticsEnabled,
          notificationsEnabled: _storage.notificationsEnabled,
          usageTrackingEnabled: _storage.usageTrackingEnabled,
          messageFontSize: _storage.messageFontSize,
          terminalFontSize: _storage.terminalFontSize,
          codeTheme: _storage.codeTheme,
          defaultProvider: _providerRepo.defaultProvider,
          defaultModel: _providerRepo.defaultModel,
          defaultTemperature: _storage.defaultTemperature,
        ));

  Future<void> setStreamingEnabled(bool v) async {
    await _storage.setBool('streaming_enabled', v);
    state = state.copyWith(streamingEnabled: v);
  }

  Future<void> setBiometricEnabled(bool v) async {
    await _storage.setBool('biometric_enabled', v);
    state = state.copyWith(biometricEnabled: v);
  }

  Future<void> setAnalyticsEnabled(bool v) async {
    await _storage.setBool('analytics_enabled', v);
    state = state.copyWith(analyticsEnabled: v);
  }

  Future<void> setNotificationsEnabled(bool v) async {
    await _storage.setBool('notifications_enabled', v);
    state = state.copyWith(notificationsEnabled: v);
  }

  Future<void> setUsageTrackingEnabled(bool v) async {
    await _storage.setBool('usage_tracking_enabled', v);
    state = state.copyWith(usageTrackingEnabled: v);
  }

  Future<void> setMessageFontSize(double v) async {
    await _storage.setDouble('message_font_size', v);
    state = state.copyWith(messageFontSize: v);
  }

  Future<void> setTerminalFontSize(double v) async {
    await _storage.setDouble('terminal_font_size', v);
    state = state.copyWith(terminalFontSize: v);
  }

  Future<void> setCodeTheme(String v) async {
    await _storage.setString('code_theme', v);
    state = state.copyWith(codeTheme: v);
  }

  Future<void> setDefaultTemperature(double v) async {
    await _storage.setDouble('default_temperature', v);
    state = state.copyWith(defaultTemperature: v);
  }

  Future<void> setDefaultProviderAndModel(String provider, String model) async {
    await _providerRepo.setDefaultProviderAndModel(provider, model);
    state = state.copyWith(defaultProvider: provider, defaultModel: model);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(
    ref.read(localStorageProvider),
    ref.read(providerRepositoryProvider),
  );
});

// ── API Keys Provider ─────────────────────────────────────────────────────

class ApiKeysNotifier extends StateNotifier<List<ApiKeyModel>> {
  final ProviderRepositoryImpl _repo;
  ApiKeysNotifier(this._repo) : super(_repo.getAllApiKeyMetadata());

  Future<void> saveKey({
    required String providerId,
    required String apiKey,
    String? baseUrl,
  }) async {
    await _repo.saveApiKey(
        providerId: providerId, apiKey: apiKey, baseUrl: baseUrl);
    state = _repo.getAllApiKeyMetadata();
  }

  Future<void> deleteKey(String providerId) async {
    await _repo.deleteApiKey(providerId);
    state = _repo.getAllApiKeyMetadata();
  }

  bool hasKey(String providerId) =>
      state.any((k) => k.providerId == providerId && k.isActive);

  ApiKeyModel? getKey(String providerId) {
    try {
      return state.firstWhere((k) => k.providerId == providerId);
    } catch (_) {
      return null;
    }
  }

  void refresh() => state = _repo.getAllApiKeyMetadata();
}

final apiKeysProvider =
    StateNotifierProvider<ApiKeysNotifier, List<ApiKeyModel>>(
        (ref) => ApiKeysNotifier(ref.read(providerRepositoryProvider)));

final configuredProvidersProvider = Provider<List<String>>((ref) {
  final keys = ref.watch(apiKeysProvider);
  return keys
      .where((k) => k.isActive && k.isValid)
      .map((k) => k.providerId)
      .toList();
});

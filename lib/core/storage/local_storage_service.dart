import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class LocalStorageService {
  static LocalStorageService? _instance;
  static LocalStorageService get instance =>
      _instance ??= LocalStorageService._();
  LocalStorageService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> initDefaults() async {
    await init();
    if (!_prefs.containsKey(AppConstants.keyStreamingEnabled)) {
      await setBool(AppConstants.keyStreamingEnabled, true);
    }
    if (!_prefs.containsKey(AppConstants.keyMessageFontSize)) {
      await setDouble(AppConstants.keyMessageFontSize, 15.0);
    }
    if (!_prefs.containsKey(AppConstants.keyTerminalFontSize)) {
      await setDouble(AppConstants.keyTerminalFontSize, 13.0);
    }
    if (!_prefs.containsKey(AppConstants.keyCodeTheme)) {
      await setString(AppConstants.keyCodeTheme, 'github-dark');
    }
    if (!_prefs.containsKey(AppConstants.keyDefaultProvider)) {
      await setString(AppConstants.keyDefaultProvider, 'openai');
    }
    if (!_prefs.containsKey(AppConstants.keyDefaultModel)) {
      await setString(AppConstants.keyDefaultModel, 'gpt-4o');
    }
    if (!_prefs.containsKey(AppConstants.keyDefaultTemperature)) {
      await setDouble(AppConstants.keyDefaultTemperature, 0.7);
    }
  }

  // String
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);
  String? getString(String key) => _prefs.getString(key);
  String getStringOrDefault(String key, String def) =>
      _prefs.getString(key) ?? def;

  // Bool
  Future<bool> setBool(String key, bool value) =>
      _prefs.setBool(key, value);
  bool? getBool(String key) => _prefs.getBool(key);
  bool getBoolOrDefault(String key, bool def) =>
      _prefs.getBool(key) ?? def;

  // Int
  Future<bool> setInt(String key, int value) =>
      _prefs.setInt(key, value);
  int? getInt(String key) => _prefs.getInt(key);
  int getIntOrDefault(String key, int def) => _prefs.getInt(key) ?? def;

  // Double
  Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);
  double? getDouble(String key) => _prefs.getDouble(key);
  double getDoubleOrDefault(String key, double def) =>
      _prefs.getDouble(key) ?? def;

  // List
  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);
  List<String>? getStringList(String key) => _prefs.getStringList(key);
  List<String> getStringListOrDefault(String key, List<String> def) =>
      _prefs.getStringList(key) ?? def;

  Future<bool> remove(String key) => _prefs.remove(key);
  bool containsKey(String key) => _prefs.containsKey(key);
  Set<String> get keys => _prefs.getKeys();

  // Convenience getters
  String get themeMode =>
      getStringOrDefault(AppConstants.keyThemeMode, 'dark');
  bool get streamingEnabled =>
      getBoolOrDefault(AppConstants.keyStreamingEnabled, true);
  bool get biometricEnabled =>
      getBoolOrDefault(AppConstants.keyBiometricEnabled, false);
  bool get analyticsEnabled =>
      getBoolOrDefault('analytics_enabled', true);
  bool get notificationsEnabled =>
      getBoolOrDefault('notifications_enabled', true);
  bool get usageTrackingEnabled =>
      getBoolOrDefault('usage_tracking_enabled', true);
  bool get onboardingComplete =>
      getBoolOrDefault(AppConstants.keyOnboardingComplete, false);
  double get messageFontSize =>
      getDoubleOrDefault(AppConstants.keyMessageFontSize, 15.0);
  double get terminalFontSize =>
      getDoubleOrDefault(AppConstants.keyTerminalFontSize, 13.0);
  String get codeTheme =>
      getStringOrDefault(AppConstants.keyCodeTheme, 'github-dark');
  String get defaultProvider =>
      getStringOrDefault(AppConstants.keyDefaultProvider, 'openai');
  String get defaultModel =>
      getStringOrDefault(AppConstants.keyDefaultModel, 'gpt-4o');
  double get defaultTemperature =>
      getDoubleOrDefault(AppConstants.keyDefaultTemperature, 0.7);

  Future<void> setThemeMode(String mode) =>
      setString(AppConstants.keyThemeMode, mode);
}

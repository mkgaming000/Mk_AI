class AppConstants {
  AppConstants._();

  static const String appName = 'OmniForge AI';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyDefaultProvider = 'default_provider';
  static const String keyDefaultModel = 'default_model';
  static const String keyStreamingEnabled = 'streaming_enabled';
  static const String keyMessageFontSize = 'message_font_size';
  static const String keyCodeTheme = 'code_theme';
  static const String keyTerminalFontSize = 'terminal_font_size';
  static const String keyAnalyticsEnabled = 'analytics_enabled';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyUsageTrackingEnabled = 'usage_tracking_enabled';
  static const String keyDefaultTemperature = 'default_temperature';

  // Hive box names
  static const String boxConversations = 'conversations';
  static const String boxMessages = 'messages';
  static const String boxApiKeys = 'api_keys';
  static const String boxImageHistory = 'image_history';
  static const String boxAgents = 'agents';
  static const String boxUsageStats = 'usage_stats';
  static const String boxWorkspaces = 'workspaces';
  static const String boxCodeProjects = 'code_projects';
  static const String boxMcpServers = 'mcp_servers';

  // Limits
  static const int maxMessagesPerConversation = 1000;
  static const int maxFileUploadSizeMB = 25;
  static const int maxTokensDefault = 4096;

  // Timeouts
  static const int connectionTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 120;

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 400);
}

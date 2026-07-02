class RouteNames {
  RouteNames._();

  static const String splash = '/splash';
  static const String home = '/';

  // Chat
  static const String chatList = '/chat';
  static const String newChat = '/chat/new';
  static const String chatDetail = '/chat/:id';
  static const String chatCompare = '/chat/compare';

  // Create
  static const String imageGen = '/create/image';
  static const String imageHistory = '/create/image/history';
  static const String imageGallery = '/create/image/gallery';
  static const String videoGen = '/create/video';
  static const String musicGen = '/create/music';

  // Tools
  static const String codeEditor = '/tools/code';
  static const String codeProjects = '/tools/code/projects';
  static const String terminal = '/tools/terminal';
  static const String documentAI = '/tools/documents';
  static const String workspace = '/tools/workspace';

  // AI
  static const String voiceAI = '/ai/voice';
  static const String search = '/ai/search';
  static const String agents = '/ai/agents';
  static const String agentBuilder = '/ai/agents/builder';
  static const String agentRun = '/ai/agents/run';
  static const String workflowBuilder = '/ai/agents/workflows';

  // Settings
  static const String settings = '/settings';
  static const String apiKeys = '/settings/api-keys';
  static const String appearance = '/settings/appearance';
  static const String usageStats = '/settings/usage';
  static const String mcpServers = '/settings/mcp';
  static const String localModels = '/settings/local-models';
  static const String privacy = '/settings/privacy';
}

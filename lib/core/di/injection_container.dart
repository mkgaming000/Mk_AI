import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage_service.dart';
import '../storage/local_storage_service.dart';
import '../security/encryption_service.dart';
import '../security/biometric_service.dart';
import '../../data/datasources/remote/openai_datasource.dart';
import '../../data/datasources/remote/anthropic_datasource.dart';
import '../../data/datasources/remote/gemini_datasource.dart';
import '../../data/datasources/remote/xai_datasource.dart';
import '../../data/datasources/remote/deepseek_datasource.dart';
import '../../data/datasources/remote/mistral_datasource.dart';
import '../../data/datasources/remote/openrouter_datasource.dart';
import '../../data/datasources/remote/huggingface_datasource.dart';
import '../../data/datasources/remote/together_datasource.dart';
import '../../data/datasources/remote/stability_datasource.dart';
import '../../data/datasources/remote/replicate_datasource.dart';
import '../../data/datasources/remote/elevenlabs_datasource.dart';
import '../../data/datasources/remote/ollama_datasource.dart';
import '../../data/datasources/local/conversation_local_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/provider_repository_impl.dart';
import '../../data/repositories/image_repository_impl.dart';
import '../../data/repositories/voice_repository_impl.dart';
import '../../data/services/ai_router_service.dart';
import '../../data/services/token_counter_service.dart';
import '../../data/services/cost_tracker_service.dart';
import '../../data/services/model_health_monitor.dart';
import '../../data/services/mcp_client_service.dart';
// settings provider imported by consumers directly to avoid circular dep
export '../../features/settings/providers/settings_provider.dart'
    show settingsProvider, AppSettings;

// ── Core Services ──────────────────────────────────────────────────────────

final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService.instance,
);

final localStorageProvider = Provider<LocalStorageService>(
  (ref) => LocalStorageService.instance,
);

final encryptionServiceProvider = Provider<EncryptionService>(
  (ref) => EncryptionService.instance,
);

final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService.instance,
);

// ── Remote Datasources ─────────────────────────────────────────────────────

final openAIDatasourceProvider = Provider<OpenAIDatasource>((ref) =>
    OpenAIDatasource(secureStorage: ref.read(secureStorageProvider)));

final anthropicDatasourceProvider = Provider<AnthropicDatasource>((ref) =>
    AnthropicDatasource(secureStorage: ref.read(secureStorageProvider)));

final geminiDatasourceProvider = Provider<GeminiDatasource>((ref) =>
    GeminiDatasource(secureStorage: ref.read(secureStorageProvider)));

final xAIDatasourceProvider = Provider<XAIDatasource>((ref) =>
    XAIDatasource(secureStorage: ref.read(secureStorageProvider)));

final deepSeekDatasourceProvider = Provider<DeepSeekDatasource>((ref) =>
    DeepSeekDatasource(secureStorage: ref.read(secureStorageProvider)));

final mistralDatasourceProvider = Provider<MistralDatasource>((ref) =>
    MistralDatasource(secureStorage: ref.read(secureStorageProvider)));

final openRouterDatasourceProvider = Provider<OpenRouterDatasource>((ref) =>
    OpenRouterDatasource(secureStorage: ref.read(secureStorageProvider)));

final huggingFaceDatasourceProvider = Provider<HuggingFaceDatasource>((ref) =>
    HuggingFaceDatasource(secureStorage: ref.read(secureStorageProvider)));

final togetherDatasourceProvider = Provider<TogetherDatasource>((ref) =>
    TogetherDatasource(secureStorage: ref.read(secureStorageProvider)));

final stabilityDatasourceProvider = Provider<StabilityDatasource>((ref) =>
    StabilityDatasource(secureStorage: ref.read(secureStorageProvider)));

final replicateDatasourceProvider = Provider<ReplicateDatasource>((ref) =>
    ReplicateDatasource(secureStorage: ref.read(secureStorageProvider)));

final elevenLabsDatasourceProvider = Provider<ElevenLabsDatasource>((ref) =>
    ElevenLabsDatasource(secureStorage: ref.read(secureStorageProvider)));

final ollamaDatasourceProvider = Provider<OllamaDatasource>((ref) =>
    OllamaDatasource(localStorage: ref.read(localStorageProvider)));

// ── Local Datasources ──────────────────────────────────────────────────────

final conversationLocalDatasourceProvider =
    Provider<ConversationLocalDatasource>((ref) => ConversationLocalDatasource());

// ── Services ───────────────────────────────────────────────────────────────

final tokenCounterServiceProvider =
    Provider<TokenCounterService>((ref) => TokenCounterService());

final costTrackerServiceProvider = Provider<CostTrackerService>((ref) =>
    CostTrackerService(localStorage: ref.read(localStorageProvider)));

final modelHealthMonitorProvider =
    Provider<ModelHealthMonitor>((ref) => ModelHealthMonitor());

final mcpClientServiceProvider =
    Provider<McpClientService>((ref) => McpClientService());

final aiRouterServiceProvider = Provider<AiRouterService>((ref) {
  return AiRouterService(
    openAI: ref.read(openAIDatasourceProvider),
    anthropic: ref.read(anthropicDatasourceProvider),
    gemini: ref.read(geminiDatasourceProvider),
    xAI: ref.read(xAIDatasourceProvider),
    deepSeek: ref.read(deepSeekDatasourceProvider),
    mistral: ref.read(mistralDatasourceProvider),
    openRouter: ref.read(openRouterDatasourceProvider),
    huggingFace: ref.read(huggingFaceDatasourceProvider),
    together: ref.read(togetherDatasourceProvider),
    ollama: ref.read(ollamaDatasourceProvider),
    healthMonitor: ref.read(modelHealthMonitorProvider),
    tokenCounter: ref.read(tokenCounterServiceProvider),
    costTracker: ref.read(costTrackerServiceProvider),
  );
});

// ── Repositories ───────────────────────────────────────────────────────────

final chatRepositoryProvider = Provider<ChatRepositoryImpl>((ref) {
  return ChatRepositoryImpl(
    aiRouter: ref.read(aiRouterServiceProvider),
    localDatasource: ref.read(conversationLocalDatasourceProvider),
    localStorage: ref.read(localStorageProvider),
    tokenCounter: ref.read(tokenCounterServiceProvider),
    costTracker: ref.read(costTrackerServiceProvider),
  );
});

final providerRepositoryProvider = Provider<ProviderRepositoryImpl>((ref) {
  return ProviderRepositoryImpl(
    secureStorage: ref.read(secureStorageProvider),
    localStorage: ref.read(localStorageProvider),
  );
});

final imageRepositoryProvider = Provider<ImageRepositoryImpl>((ref) {
  return ImageRepositoryImpl(
    openAI: ref.read(openAIDatasourceProvider),
    stability: ref.read(stabilityDatasourceProvider),
    replicate: ref.read(replicateDatasourceProvider),
  );
});

final voiceRepositoryProvider = Provider<VoiceRepositoryImpl>((ref) {
  return VoiceRepositoryImpl(
    elevenLabs: ref.read(elevenLabsDatasourceProvider),
    openAI: ref.read(openAIDatasourceProvider),
  );
});

Future<void> initDependencies() async {
  SecureStorageService.instance.init();
}

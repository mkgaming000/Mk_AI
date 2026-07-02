import '../datasources/remote/openai_datasource.dart';
import '../datasources/remote/anthropic_datasource.dart';
import '../datasources/remote/gemini_datasource.dart';
import '../datasources/remote/xai_datasource.dart';
import '../datasources/remote/deepseek_datasource.dart';
import '../datasources/remote/mistral_datasource.dart';
import '../datasources/remote/openrouter_datasource.dart';
import '../datasources/remote/huggingface_datasource.dart';
import '../datasources/remote/together_datasource.dart';
import '../datasources/remote/ollama_datasource.dart';
import '../models/message_model.dart';
import 'model_health_monitor.dart';
import 'token_counter_service.dart';
import 'cost_tracker_service.dart';

class AiRouterService {
  final OpenAIDatasource _openAI;
  final AnthropicDatasource _anthropic;
  final GeminiDatasource _gemini;
  final XAIDatasource _xAI;
  final DeepSeekDatasource _deepSeek;
  final MistralDatasource _mistral;
  final OpenRouterDatasource _openRouter;
  final HuggingFaceDatasource _huggingFace;
  final TogetherDatasource _together;
  final OllamaDatasource _ollama;
  final ModelHealthMonitor _healthMonitor;
  final TokenCounterService _tokenCounter;
  final CostTrackerService _costTracker;

  AiRouterService({
    required OpenAIDatasource openAI,
    required AnthropicDatasource anthropic,
    required GeminiDatasource gemini,
    required XAIDatasource xAI,
    required DeepSeekDatasource deepSeek,
    required MistralDatasource mistral,
    required OpenRouterDatasource openRouter,
    required HuggingFaceDatasource huggingFace,
    required TogetherDatasource together,
    required OllamaDatasource ollama,
    required ModelHealthMonitor healthMonitor,
    required TokenCounterService tokenCounter,
    required CostTrackerService costTracker,
  })  : _openAI = openAI,
        _anthropic = anthropic,
        _gemini = gemini,
        _xAI = xAI,
        _deepSeek = deepSeek,
        _mistral = mistral,
        _openRouter = openRouter,
        _huggingFace = huggingFace,
        _together = together,
        _ollama = ollama,
        _healthMonitor = healthMonitor,
        _tokenCounter = tokenCounter,
        _costTracker = costTracker;

  Stream<String> streamChat({
    required String providerId,
    required String modelId,
    required List<MessageModel> messages,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    double? topP,
    Map<String, dynamic>? providerOptions,
  }) async* {
    final stopwatch = Stopwatch()..start();
    _healthMonitor.recordRequestStart(providerId, modelId);

    try {
      switch (providerId.toLowerCase()) {
        case 'openai':
          yield* _openAI.streamChat(OpenAIChatRequest(
            messages: messages, model: modelId,
            systemPrompt: systemPrompt, temperature: temperature,
            maxTokens: maxTokens, topP: topP,
          ));
          break;
        case 'anthropic':
          yield* _anthropic.streamChat(
            messages: messages, model: modelId,
            systemPrompt: systemPrompt, temperature: temperature,
            maxTokens: maxTokens ?? 8192, topP: topP,
            extendedThinking: providerOptions?['extended_thinking'] == true,
            thinkingBudget: providerOptions?['thinking_budget'] as int?,
          );
          break;
        case 'google':
          yield* _gemini.streamChat(
            messages: messages, model: modelId,
            systemPrompt: systemPrompt, temperature: temperature,
            maxOutputTokens: maxTokens,
          );
          break;
        case 'xai':
          yield* _xAI.streamChat(
            messages: messages, model: modelId,
            systemPrompt: systemPrompt, temperature: temperature,
            maxTokens: maxTokens,
          );
          break;
        case 'deepseek':
          yield* _deepSeek.streamChat(
            messages: messages, model: modelId,
            systemPrompt: systemPrompt, temperature: temperature,
            maxTokens: maxTokens,
          );
          break;
        case 'mistral':
          yield* _mistral.streamChat(
            messages: messages, model: modelId,
            systemPrompt: systemPrompt, temperature: temperature,
            maxTokens: maxTokens, topP: topP,
          );
          break;
        case 'openrouter':
          yield* _openRouter.streamChat(
            messages: messages, model: modelId,
            systemPrompt: systemPrompt, temperature: temperature,
            maxTokens: maxTokens, topP: topP,
          );
          break;
        case 'huggingface':
          yield* _huggingFace.streamChat(
            messages: messages, model: modelId,
            systemPrompt: systemPrompt, temperature: temperature,
            maxNewTokens: maxTokens,
          );
          break;
        case 'together':
          yield* _together.streamChat(
            messages: messages, model: modelId,
            systemPrompt: systemPrompt, temperature: temperature,
            maxTokens: maxTokens, topP: topP,
          );
          break;
        case 'ollama':
        case 'lmstudio':
          yield* _ollama.streamChat(
            messages: messages, model: modelId,
            systemPrompt: systemPrompt, temperature: temperature,
            numPredict: maxTokens, topP: topP,
          );
          break;
        default:
          // Fallback: route through OpenRouter
          yield* _openRouter.streamChat(
            messages: messages, model: '$providerId/$modelId',
            systemPrompt: systemPrompt, temperature: temperature,
            maxTokens: maxTokens,
          );
      }

      stopwatch.stop();
      _healthMonitor.recordRequestSuccess(
          providerId, modelId, stopwatch.elapsedMilliseconds);
    } catch (e) {
      stopwatch.stop();
      _healthMonitor.recordRequestFailure(providerId, modelId);
      rethrow;
    }
  }

  void invalidateProvider(String providerId) {
    switch (providerId.toLowerCase()) {
      case 'openai': _openAI.invalidateClient(); break;
      case 'anthropic': _anthropic.invalidateClient(); break;
      case 'google': _gemini.invalidateClient(); break;
      case 'xai': _xAI.invalidateClient(); break;
      case 'deepseek': _deepSeek.invalidateClient(); break;
      case 'mistral': _mistral.invalidateClient(); break;
      case 'openrouter': _openRouter.invalidateClient(); break;
      case 'huggingface': _huggingFace.invalidateClient(); break;
      case 'together': _together.invalidateClient(); break;
      case 'ollama':
      case 'lmstudio': _ollama.invalidateClient(); break;
    }
  }

  Future<String?> getBestProvider(List<String> configured) =>
      _healthMonitor.getBestProvider(configured);

  Future<List<String>> getModelsForProvider(String providerId) async {
    switch (providerId.toLowerCase()) {
      case 'openai': return _openAI.getAvailableModels();
      case 'anthropic': return _anthropic.getAvailableModels();
      case 'google': return _gemini.getAvailableModels();
      case 'xai': return _xAI.getAvailableModels();
      case 'deepseek': return _deepSeek.getAvailableModels();
      case 'mistral': return _mistral.getAvailableModels();
      case 'openrouter':
        final m = await _openRouter.getAvailableModels();
        return m.map((e) => e.id).toList();
      case 'huggingface': return _huggingFace.getPopularModels();
      case 'together': return _together.getAvailableModels();
      case 'ollama':
      case 'lmstudio':
        try { return (await _ollama.listModels()).map((m) => m.name).toList(); }
        catch (_) { return []; }
      default: return [];
    }
  }
}

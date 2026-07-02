import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/error/exceptions.dart';
import '../../models/message_model.dart';

class AnthropicDatasource {
  final SecureStorageService _secureStorage;
  Dio? _dio;
  AnthropicDatasource({required SecureStorageService secureStorage}) : _secureStorage = secureStorage;
  Future<Dio> get _client async {
    if (_dio != null) return _dio!;
    final key = await _secureStorage.getApiKey('anthropic');
    if (key == null || key.isEmpty) throw AiProviderException.noApiKey('Anthropic');
    _dio = ApiClient.create(
      baseUrl: ApiConstants.anthropicBaseUrl,
      defaultHeaders: {
        'x-api-key': key,
        'anthropic-version': ApiConstants.anthropicVersion,
        'anthropic-beta': 'messages-2023-12-15',
      },
    );
    return _dio!;
  }
  void invalidateClient() => _dio = null;

  Stream<String> streamChat({
    required List<MessageModel> messages, required String model,
    String? systemPrompt, int maxTokens = 8192,
    double? temperature, double? topP,
    bool extendedThinking = false, int? thinkingBudget,
  }) async* {
    final client = await _client;
    final convoMsgs = messages.where((m) => m.role != MessageRole.system)
        .map((m) => m.toAnthropicMessage()).toList();

    String? finalSystem = systemPrompt;
    for (final m in messages.where((m) => m.role == MessageRole.system)) {
      finalSystem = finalSystem != null ? '$finalSystem\n\n${m.content}' : m.content;
    }

    final body = <String, dynamic>{
      'model': model, 'messages': convoMsgs, 'max_tokens': maxTokens, 'stream': true,
      if (finalSystem != null && finalSystem.isNotEmpty) 'system': finalSystem,
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'top_p': topP,
    };
    if (extendedThinking && thinkingBudget != null) {
      body['thinking'] = {'type': 'enabled', 'budget_tokens': thinkingBudget};
    }

    bool inText = false; bool inThink = false;
    final thinkBuf = StringBuffer();

    await for (final event in ApiClient.streamAnthropicSSE(
        dio: client, path: ApiConstants.anthropicMessagesEndpoint, body: body)) {
      final et = event['_event_type'] as String?;
      switch (et) {
        case 'content_block_start':
          final block = event['content_block'] as Map<String,dynamic>?;
          inText = block?['type'] == 'text';
          inThink = block?['type'] == 'thinking';
          break;
        case 'content_block_delta':
          final delta = event['delta'] as Map<String,dynamic>?;
          if (delta?['type'] == 'text_delta' && inText) {
            final text = delta?['text'] as String?;
            if (text != null && text.isNotEmpty) yield text;
          } else if (delta?['type'] == 'thinking_delta' && inThink) {
            thinkBuf.write(delta?['thinking'] as String? ?? '');
          }
          break;
        case 'content_block_stop':
          if (inThink && thinkBuf.isNotEmpty) {
            yield '\x00THINKING\x00${thinkBuf.toString()}\x00/THINKING\x00';
            thinkBuf.clear();
          }
          inText = false; inThink = false;
          break;
        case 'message_stop': return;
        case 'error':
          final err = event['error'] as Map<String,dynamic>?;
          throw AiProviderException(
            message: err?['message'] as String? ?? 'Anthropic stream error',
            providerId: 'anthropic', code: err?['type'] as String?);
      }
    }
  }

  Future<List<String>> getAvailableModels() async => ApiConstants.anthropicModels;
}
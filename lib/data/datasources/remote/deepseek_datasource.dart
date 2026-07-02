import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/error/exceptions.dart';
import '../../models/message_model.dart';

class DeepSeekDatasource {
  final SecureStorageService _secureStorage;
  Dio? _dio;
  DeepSeekDatasource({required SecureStorageService secureStorage}) : _secureStorage = secureStorage;
  Future<Dio> get _client async {
    if (_dio != null) return _dio!;
    final k = await _secureStorage.getApiKey('deepseek');
    if (k == null || k.isEmpty) throw AiProviderException.noApiKey('DeepSeek');
    _dio = ApiClient.create(baseUrl: ApiConstants.deepSeekBaseUrl, defaultHeaders: {'Authorization': 'Bearer $k'});
    return _dio!;
  }
  void invalidateClient() => _dio = null;

  Stream<String> streamChat({required List<MessageModel> messages, required String model,
    String? systemPrompt, double? temperature, int? maxTokens}) async* {
    final client = await _client;
    final allMsgs = <Map<String,dynamic>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) allMsgs.add({'role':'system','content':systemPrompt});
    allMsgs.addAll(messages.where((m) => m.role != MessageRole.system).map((m) => m.toOpenAIMessage()));
    final body = {'model': model, 'messages': allMsgs, 'stream': true,
      if (temperature != null) 'temperature': temperature,
      if (maxTokens != null) 'max_tokens': maxTokens};
    bool inThink = false; final thinkBuf = StringBuffer();
    await for (final data in ApiClient.streamSSE(dio: client, path: '/chat/completions', body: body)) {
      try {
        final json = jsonDecode(data) as Map<String,dynamic>;
        final choices = json['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) continue;
        final delta = choices[0]['delta'] as Map<String,dynamic>?;
        if (delta == null) continue;
        final reasoning = delta['reasoning_content'] as String?;
        if (reasoning != null && reasoning.isNotEmpty) {
          if (!inThink) { inThink = true; thinkBuf.clear(); }
          thinkBuf.write(reasoning); continue;
        }
        if (inThink && thinkBuf.isNotEmpty) {
          yield '\x00THINKING\x00${thinkBuf.toString()}\x00/THINKING\x00';
          thinkBuf.clear(); inThink = false;
        }
        final content = delta['content'] as String?;
        if (content != null && content.isNotEmpty) yield content;
      } catch (_) { continue; }
    }
    if (thinkBuf.isNotEmpty) yield '\x00THINKING\x00${thinkBuf.toString()}\x00/THINKING\x00';
  }
  Future<List<String>> getAvailableModels() => Future.value(ApiConstants.deepSeekModels);
}
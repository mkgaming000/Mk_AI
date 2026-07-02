import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/error/exceptions.dart';
import '../../models/message_model.dart';

class MistralDatasource {
  final SecureStorageService _secureStorage;
  Dio? _dio;
  MistralDatasource({required SecureStorageService secureStorage}) : _secureStorage = secureStorage;
  Future<Dio> get _client async {
    if (_dio != null) return _dio!;
    final k = await _secureStorage.getApiKey('mistral');
    if (k == null || k.isEmpty) throw AiProviderException.noApiKey('Mistral AI');
    _dio = ApiClient.create(baseUrl: ApiConstants.mistralBaseUrl, defaultHeaders: {'Authorization': 'Bearer $k'});
    return _dio!;
  }
  void invalidateClient() => _dio = null;

  Stream<String> streamChat({required List<MessageModel> messages, required String model,
    String? systemPrompt, double? temperature, int? maxTokens, double? topP}) async* {
    final client = await _client;
    final allMsgs = <Map<String,dynamic>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) allMsgs.add({'role':'system','content':systemPrompt});
    allMsgs.addAll(messages.where((m) => m.role != MessageRole.system).map((m) => m.toOpenAIMessage()));
    final body = {'model': model, 'messages': allMsgs, 'stream': true,
      if (temperature != null) 'temperature': temperature,
      if (maxTokens != null) 'max_tokens': maxTokens,
      if (topP != null) 'top_p': topP};
    yield* ApiClient.streamSSE(dio: client, path: '/chat/completions', body: body).map((data) {
      try {
        final json = jsonDecode(data) as Map<String,dynamic>;
        final choices = json['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) return '';
        return choices[0]['delta']?['content'] as String? ?? '';
      } catch (_) { return ''; }
    }).where((c) => c.isNotEmpty);
  }
  Future<List<String>> getAvailableModels() async {
    try {
      final client = await _client;
      final response = await client.get('/models');
      final models = (response.data as Map<String,dynamic>)['data'] as List<dynamic>;
      return models.map((m) => m['id'] as String).toList()..sort();
    } catch (_) { return ApiConstants.mistralModels; }
  }
}
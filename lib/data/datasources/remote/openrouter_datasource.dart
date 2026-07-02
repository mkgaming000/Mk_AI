import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/error/exceptions.dart';
import '../../models/message_model.dart';

class OpenRouterModel {
  final String id; final String name; final String? description;
  final int? contextLength; final double? inputPrice; final double? outputPrice;
  const OpenRouterModel({required this.id, required this.name,
    this.description, this.contextLength, this.inputPrice, this.outputPrice});
  factory OpenRouterModel.fromJson(Map<String,dynamic> j) {
    final pricing = j['pricing'] as Map<String,dynamic>?;
    return OpenRouterModel(id: j['id'] as String, name: j['name'] as String? ?? j['id'] as String,
      description: j['description'] as String?, contextLength: j['context_length'] as int?,
      inputPrice: pricing != null ? double.tryParse(pricing['prompt'].toString()) : null,
      outputPrice: pricing != null ? double.tryParse(pricing['completion'].toString()) : null);
  }
}

class OpenRouterDatasource {
  final SecureStorageService _secureStorage;
  Dio? _dio; List<OpenRouterModel>? _cachedModels;
  OpenRouterDatasource({required SecureStorageService secureStorage}) : _secureStorage = secureStorage;
  Future<Dio> get _client async {
    if (_dio != null) return _dio!;
    final k = await _secureStorage.getApiKey('openrouter');
    if (k == null || k.isEmpty) throw AiProviderException.noApiKey('OpenRouter');
    _dio = ApiClient.create(
      baseUrl: ApiConstants.openRouterBaseUrl,
      defaultHeaders: {'Authorization': 'Bearer $k',
        'HTTP-Referer': ApiConstants.openRouterAppUrl,
        'X-Title': ApiConstants.openRouterAppName});
    return _dio!;
  }
  void invalidateClient() { _dio = null; _cachedModels = null; }

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
  Future<List<OpenRouterModel>> getAvailableModels() async {
    if (_cachedModels != null) return _cachedModels!;
    try {
      final client = await _client;
      final response = await client.get(ApiConstants.openRouterModelsEndpoint);
      final rawList = (response.data as Map<String,dynamic>)['data'] as List<dynamic>? ?? [];
      _cachedModels = rawList.whereType<Map<String,dynamic>>().map((m) => OpenRouterModel.fromJson(m)).toList();
      return _cachedModels ?? [];
    } catch (_) { return []; }
  }
}
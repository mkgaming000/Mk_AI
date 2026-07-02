import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/error/exceptions.dart';
import '../../models/message_model.dart';

class OpenAIChatRequest {
  final List<MessageModel> messages;
  final String model;
  final bool stream;
  final double? temperature;
  final int? maxTokens;
  final String? systemPrompt;
  final double? topP;

  const OpenAIChatRequest({
    required this.messages,
    required this.model,
    this.stream = true,
    this.temperature,
    this.maxTokens,
    this.systemPrompt,
    this.topP,
  });

  Map<String, dynamic> toJson() {
    final allMessages = <Map<String, dynamic>>[];
    if (systemPrompt != null && systemPrompt!.isNotEmpty) {
      allMessages.add({'role': 'system', 'content': systemPrompt});
    }
    allMessages.addAll(
      messages
          .where((m) => m.role != MessageRole.system)
          .map((m) => m.toOpenAIMessage()),
    );
    return {
      'model': model,
      'messages': allMessages,
      'stream': stream,
      if (temperature != null) 'temperature': temperature,
      if (maxTokens != null) 'max_tokens': maxTokens,
      if (topP != null) 'top_p': topP,
    };
  }

  OpenAIChatRequest copyWith({bool? stream}) => OpenAIChatRequest(
        messages: messages,
        model: model,
        stream: stream ?? this.stream,
        temperature: temperature,
        maxTokens: maxTokens,
        systemPrompt: systemPrompt,
        topP: topP,
      );
}

class OpenAIDatasource {
  final SecureStorageService _secureStorage;
  Dio? _dio;

  OpenAIDatasource({required SecureStorageService secureStorage})
      : _secureStorage = secureStorage;

  Future<Dio> get _client async {
    if (_dio != null) return _dio!;
    final apiKey = await _secureStorage.getApiKey('openai');
    if (apiKey == null || apiKey.isEmpty) {
      throw AiProviderException.noApiKey('OpenAI');
    }
    _dio = ApiClient.create(
      baseUrl: ApiConstants.openAIBaseUrl,
      defaultHeaders: {'Authorization': 'Bearer $apiKey'},
    );
    return _dio!;
  }

  void invalidateClient() => _dio = null;

  Stream<String> streamChat(OpenAIChatRequest request) async* {
    final client = await _client;
    yield* ApiClient.streamSSE(
      dio: client,
      path: ApiConstants.openAIChatEndpoint,
      body: request.toJson(),
    ).map((data) {
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        final choices = json['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) return '';
        return choices[0]['delta']?['content'] as String? ?? '';
      } catch (_) {
        return '';
      }
    }).where((c) => c.isNotEmpty);
  }

  Future<List<String>> generateImages({
    required String prompt,
    String model = 'dall-e-3',
    int n = 1,
    String size = '1024x1024',
    String? style,
    String? quality,
  }) async {
    final client = await _client;
    final response = await client.post(
      ApiConstants.openAIImagesEndpoint,
      data: {
        'prompt': prompt,
        'model': model,
        'n': n,
        'size': size,
        'response_format': 'url',
        if (style == 'vivid' || style == 'natural') 'style': style,
        if (quality != null) 'quality': quality,
      },
    );
    final images =
        (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return images
        .map((i) => i['url'] as String? ?? '')
        .where((u) => u.isNotEmpty)
        .toList();
  }

  Future<String> transcribeAudio({
    required List<int> audioBytes,
    required String filename,
    String? language,
  }) async {
    final client = await _client;
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(audioBytes, filename: filename),
      'model': 'whisper-1',
      if (language != null) 'language': language,
    });
    final response = await client.post(
      ApiConstants.openAITranscriptionEndpoint,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return (response.data as Map<String, dynamic>)['text'] as String? ?? '';
  }

  Future<List<int>> textToSpeech({
    required String text,
    String model = 'tts-1-hd',
    String voice = 'alloy',
    double speed = 1.0,
  }) async {
    final client = await _client;
    final response = await client.post<List<int>>(
      ApiConstants.openAISpeechEndpoint,
      data: {
        'model': model,
        'input': text,
        'voice': voice,
        'speed': speed,
        'response_format': 'mp3',
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? [];
  }

  Future<List<String>> getAvailableModels() async {
    try {
      final client = await _client;
      final response = await client.get(ApiConstants.openAIModelsEndpoint);
      final models =
          (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
      return models
          .map((m) => m['id'] as String)
          .where((id) => id.startsWith('gpt-') || id.startsWith('o'))
          .toList()
        ..sort();
    } catch (_) {
      return ApiConstants.openAIModels;
    }
  }
}

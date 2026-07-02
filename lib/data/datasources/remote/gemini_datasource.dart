import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/error/exceptions.dart';
import '../../models/message_model.dart';

class GeminiDatasource {
  final SecureStorageService _secureStorage;
  Dio? _dio;
  GeminiDatasource({required SecureStorageService secureStorage}) : _secureStorage = secureStorage;
  Future<Dio> get _client async {
    _dio ??= ApiClient.create(baseUrl: ApiConstants.geminiBaseUrl);
    return _dio!;
  }
  void invalidateClient() => _dio = null;

  Future<String> _getKey() async {
    final k = await _secureStorage.getApiKey('google');
    if (k == null || k.isEmpty) throw AiProviderException.noApiKey('Google Gemini');
    return k;
  }

  List<Map<String,dynamic>> _toContents(List<MessageModel> msgs) =>
    msgs.where((m) => m.role != MessageRole.system).map((m) {
      final role = m.role == MessageRole.user ? 'user' : 'model';
      final parts = <Map<String,dynamic>>[{'text': m.content}];
      if (m.attachments != null) {
        for (final a in m.attachments!) {
          if (a['type'] == 'image') {
            parts.add({'inline_data': {'mime_type': a['mediaType'], 'data': a['data']}});
          }
        }
      }
      return {'role': role, 'parts': parts};
    }).toList();

  Stream<String> streamChat({
    required List<MessageModel> messages, required String model,
    String? systemPrompt, double? temperature, int? maxOutputTokens,
  }) async* {
    final client = await _client;
    final apiKey = await _getKey();
    final body = <String,dynamic>{
      'contents': _toContents(messages),
      'generationConfig': {
        if (temperature != null) 'temperature': temperature,
        if (maxOutputTokens != null) 'maxOutputTokens': maxOutputTokens,
      },
      if (systemPrompt != null && systemPrompt.isNotEmpty)
        'systemInstruction': {'parts': [{'text': systemPrompt}]},
    };

    final response = await client.post<ResponseBody>(
      '/models/$model:streamGenerateContent',
      queryParameters: {'key': apiKey, 'alt': 'sse'},
      data: body,
      options: Options(responseType: ResponseType.stream),
    );

    final buffer = StringBuffer();
    await for (final chunk in response.data!.stream) {
      buffer.write(utf8.decode(chunk, allowMalformed: true));
      final content = buffer.toString();
      final events = content.split('\n\n');
      for (int i = 0; i < events.length - 1; i++) {
        final event = events[i].trim();
        if (!event.startsWith('data: ')) continue;
        final data = event.substring(6).trim();
        if (data == '[DONE]') return;
        try {
          final json = jsonDecode(data) as Map<String,dynamic>;
          final candidates = json['candidates'] as List<dynamic>?;
          if (candidates == null || candidates.isEmpty) continue;
          final parts = (candidates[0]['content'] as Map<String,dynamic>?)?['parts'] as List<dynamic>?;
          if (parts == null || parts.isEmpty) continue;
          final text = parts[0]['text'] as String?;
          if (text != null && text.isNotEmpty) yield text;
        } catch (_) {}
      }
      buffer.clear();
      if (events.isNotEmpty) buffer.write(events.last);
    }
  }

  Future<List<String>> getAvailableModels() async => ApiConstants.geminiModels;
}
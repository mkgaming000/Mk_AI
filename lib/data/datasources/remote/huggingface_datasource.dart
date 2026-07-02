import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/error/exceptions.dart';
import '../../models/message_model.dart';

class HuggingFaceDatasource {
  final SecureStorageService _secureStorage;
  Dio? _dio;
  HuggingFaceDatasource({required SecureStorageService secureStorage}) : _secureStorage = secureStorage;
  Future<Dio> get _client async {
    if (_dio != null) return _dio!;
    final k = await _secureStorage.getApiKey('huggingface');
    if (k == null || k.isEmpty) throw AiProviderException.noApiKey('HuggingFace');
    _dio = ApiClient.create(baseUrl: ApiConstants.huggingFaceBaseUrl,
      defaultHeaders: {'Authorization': 'Bearer $k'}, receiveTimeoutSeconds: 120);
    return _dio!;
  }
  void invalidateClient() => _dio = null;

  Stream<String> streamChat({required List<MessageModel> messages, required String model,
    String? systemPrompt, double? temperature, int? maxNewTokens}) async* {
    final client = await _client;
    final sb = StringBuffer();
    if (systemPrompt != null && systemPrompt.isNotEmpty) sb.write('System: $systemPrompt\n\n');
    for (final m in messages.where((m) => m.role != MessageRole.system)) {
      sb.write('${m.isUser ? 'User' : 'Assistant'}: ${m.content}\n\n');
    }
    sb.write('Assistant: ');
    final body = {'inputs': sb.toString(), 'parameters': {
      'max_new_tokens': maxNewTokens ?? 512,
      if (temperature != null) 'temperature': temperature,
      'return_full_text': false, 'stream': true,
    }};
    try {
      final response = await client.post<ResponseBody>('/models/$model', data: body,
        options: Options(responseType: ResponseType.stream));
      final buf = StringBuffer();
      await for (final chunk in response.data!.stream) {
        buf.write(utf8.decode(chunk, allowMalformed: true));
        final content = buf.toString();
        final lines = content.split('\n\n');
        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (!line.startsWith('data:')) continue;
          final data = line.substring(5).trim();
          if (data == '[DONE]') return;
          try {
            final json = jsonDecode(data);
            if (json is List && json.isNotEmpty) {
              final gen = json[0]['generated_text'] as String?;
              if (gen != null) yield gen;
            } else if (json is Map) {
              final token = json['token']?['text'] as String?;
              if (token != null) yield token;
            }
          } catch (_) {}
        }
        buf.clear();
        if (lines.isNotEmpty) buf.write(lines.last);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 503) {
        throw AiProviderException(message: 'Model is loading. Try again in a moment.',
          providerId: 'huggingface', code: 'MODEL_LOADING');
      }
      rethrow;
    }
  }
  List<String> getPopularModels() => ApiConstants.huggingFacePopularModels;
}
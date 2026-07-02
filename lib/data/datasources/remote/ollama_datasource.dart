import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/error/exceptions.dart';
import '../../models/message_model.dart';

class OllamaModel {
  final String name; final String? digest; final int? size; final DateTime? modifiedAt;
  const OllamaModel({required this.name, this.digest, this.size, this.modifiedAt});
  factory OllamaModel.fromJson(Map<String,dynamic> j) => OllamaModel(
    name: j['name'] as String, digest: j['digest'] as String?,
    size: j['size'] as int?,
    modifiedAt: j['modified_at'] != null ? DateTime.tryParse(j['modified_at'] as String) : null);
  String get displayName => name.split(':').first;
  String get tag => name.contains(':') ? name.split(':').last : 'latest';
  String get formattedSize {
    if (size == null) return '';
    final gb = size! / (1024 * 1024 * 1024);
    if (gb >= 1) return '${gb.toStringAsFixed(1)} GB';
    return '${(size! / (1024 * 1024)).toStringAsFixed(0)} MB';
  }
}

class OllamaDatasource {
  final LocalStorageService _localStorage;
  Dio? _dio;
  OllamaDatasource({required LocalStorageService localStorage}) : _localStorage = localStorage;
  String get _baseUrl => _localStorage.getStringOrDefault('ollama_base_url', 'http://10.0.2.2:11434');
  Dio get _client { _dio ??= ApiClient.create(baseUrl: _baseUrl, connectionTimeoutSeconds: 5, receiveTimeoutSeconds: 120); return _dio!; }
  void invalidateClient() => _dio = null;
  void setBaseUrl(String url) { _localStorage.setString('ollama_base_url', url); invalidateClient(); }

  Future<bool> isAvailable() async {
    try {
      final r = await _client.get('/', options: Options(sendTimeout: const Duration(seconds: 3), receiveTimeout: const Duration(seconds: 3)));
      return r.statusCode == 200;
    } catch (_) { return false; }
  }

  Future<List<OllamaModel>> listModels() async {
    try {
      final r = await _client.get('/api/tags');
      final models = (r.data as Map<String,dynamic>)['models'] as List<dynamic>? ?? [];
      return models.map((m) => OllamaModel.fromJson(m as Map<String,dynamic>)).toList();
    } catch (e) { throw AiProviderException(message: 'Failed to list Ollama models: $e', providerId: 'ollama'); }
  }

  Future<void> pullModel(String name, {void Function(double)? onProgress}) async {
    final r = await _client.post<ResponseBody>('/api/pull',
      data: {'name': name, 'stream': true}, options: Options(responseType: ResponseType.stream));
    await for (final chunk in r.data!.stream) {
      final text = utf8.decode(chunk, allowMalformed: true);
      for (final line in text.split('\n')) {
        if (line.trim().isEmpty) continue;
        try {
          final j = jsonDecode(line) as Map<String,dynamic>;
          final total = j['total'] as int?; final completed = j['completed'] as int?;
          if (total != null && completed != null && total > 0) onProgress?.call(completed / total);
        } catch (_) {}
      }
    }
  }

  Future<void> deleteModel(String name) async => _client.delete('/api/delete', data: {'name': name});

  Stream<String> streamChat({required List<MessageModel> messages, required String model,
    String? systemPrompt, double? temperature, int? numPredict, double? topP}) async* {
    final ollamaMsgs = <Map<String,dynamic>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) ollamaMsgs.add({'role':'system','content':systemPrompt});
    for (final m in messages.where((m) => m.role != MessageRole.system)) {
      ollamaMsgs.add({'role': m.isUser ? 'user' : 'assistant', 'content': m.content});
    }
    final opts = <String,dynamic>{
      if (temperature != null) 'temperature': temperature,
      if (numPredict != null) 'num_predict': numPredict,
      if (topP != null) 'top_p': topP,
    };
    final body = {'model': model, 'messages': ollamaMsgs, 'stream': true, if (opts.isNotEmpty) 'options': opts};
    final r = await _client.post<ResponseBody>('/api/chat', data: body, options: Options(responseType: ResponseType.stream));
    final buf = StringBuffer();
    await for (final chunk in r.data!.stream) {
      buf.write(utf8.decode(chunk, allowMalformed: true));
      final lines = buf.toString().split('\n');
      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        try {
          final j = jsonDecode(line) as Map<String,dynamic>;
          final token = (j['message'] as Map<String,dynamic>?)?['content'] as String?;
          if (token != null && token.isNotEmpty) yield token;
          if (j['done'] == true) return;
        } catch (_) {}
      }
      buf.clear();
      if (lines.isNotEmpty) buf.write(lines.last);
    }
  }
}
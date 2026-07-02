import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/error/exceptions.dart';

class ElevenLabsVoice {
  final String voiceId; final String name;
  final String? description; final String? previewUrl;
  const ElevenLabsVoice({required this.voiceId, required this.name,
    this.description, this.previewUrl});
  factory ElevenLabsVoice.fromJson(Map<String,dynamic> j) =>
    ElevenLabsVoice(voiceId: j['voice_id'] as String, name: j['name'] as String,
      description: j['description'] as String?, previewUrl: j['preview_url'] as String?);
}

class ElevenLabsDatasource {
  final SecureStorageService _secureStorage;
  Dio? _dio;
  ElevenLabsDatasource({required SecureStorageService secureStorage}) : _secureStorage = secureStorage;
  Future<Dio> get _client async {
    if (_dio != null) return _dio!;
    final k = await _secureStorage.getApiKey('elevenlabs');
    if (k == null || k.isEmpty) throw AiProviderException.noApiKey('ElevenLabs');
    _dio = ApiClient.create(baseUrl: ApiConstants.elevenLabsBaseUrl, defaultHeaders: {'xi-api-key': k});
    return _dio!;
  }
  void invalidateClient() => _dio = null;

  Future<List<int>> textToSpeech({required String text, required String voiceId,
    String modelId = 'eleven_multilingual_v2',
    double stability = 0.5, double similarityBoost = 0.75}) async {
    final client = await _client;
    final response = await client.post<List<int>>(
      '${ApiConstants.elevenLabsTTSEndpoint}/$voiceId',
      data: {'text': text, 'model_id': modelId,
        'voice_settings': {'stability': stability, 'similarity_boost': similarityBoost}},
      options: Options(responseType: ResponseType.bytes));
    return response.data ?? [];
  }

  Stream<List<int>> streamTextToSpeech({required String text, required String voiceId,
    String modelId = 'eleven_turbo_v2_5'}) async* {
    final client = await _client;
    final response = await client.post<ResponseBody>(
      '${ApiConstants.elevenLabsTTSEndpoint}/$voiceId/stream',
      data: {'text': text, 'model_id': modelId, 'voice_settings': {'stability': 0.5, 'similarity_boost': 0.75}},
      options: Options(responseType: ResponseType.stream));
    await for (final chunk in response.data!.stream) { yield chunk; }
  }

  Future<List<ElevenLabsVoice>> getVoices() async {
    final client = await _client;
    final response = await client.get(ApiConstants.elevenLabsVoicesEndpoint);
    final voices = (response.data as Map<String,dynamic>)['voices'] as List<dynamic>;
    return voices.map((v) => ElevenLabsVoice.fromJson(v as Map<String,dynamic>)).toList();
  }

  Future<ElevenLabsVoice> cloneVoice({required String name,
    required List<List<int>> audioSamples, required List<String> filenames,
    String? description}) async {
    final client = await _client;
    final fields = <String,dynamic>{'name': name, if (description != null) 'description': description};
    for (int i = 0; i < audioSamples.length; i++) {
      fields['files[$i]'] = MultipartFile.fromBytes(audioSamples[i], filename: filenames[i]);
    }
    final response = await client.post(ApiConstants.elevenLabsVoiceCloneEndpoint,
      data: FormData.fromMap(fields), options: Options(contentType: 'multipart/form-data'));
    return ElevenLabsVoice.fromJson(response.data as Map<String,dynamic>);
  }
}
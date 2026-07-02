import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/error/exceptions.dart';

class StabilityDatasource {
  final SecureStorageService _secureStorage;
  Dio? _dio;
  StabilityDatasource({required SecureStorageService secureStorage}) : _secureStorage = secureStorage;
  Future<Dio> get _client async {
    if (_dio != null) return _dio!;
    final k = await _secureStorage.getApiKey('stability');
    if (k == null || k.isEmpty) throw AiProviderException.noApiKey('Stability AI');
    _dio = ApiClient.create(baseUrl: ApiConstants.stabilityBaseUrl,
      defaultHeaders: {'Authorization': 'Bearer $k', 'Accept': 'image/*'});
    return _dio!;
  }
  void invalidateClient() => _dio = null;

  Future<List<int>> generateImage({required String prompt, String? negativePrompt,
    String model = 'sd3-large-turbo', int width = 1024, int height = 1024,
    int steps = 28, double cfgScale = 7.0, String? style,
    String outputFormat = 'png'}) async {
    final client = await _client;
    final formData = FormData.fromMap({
      'prompt': prompt,
      if (negativePrompt != null) 'negative_prompt': negativePrompt,
      'width': width.toString(), 'height': height.toString(),
      'steps': steps.toString(), 'cfg_scale': cfgScale.toString(),
      'output_format': outputFormat,
      if (style != null) 'style_preset': style,
    });
    final response = await client.post<List<int>>('/stable-image/generate/sd3',
      data: formData,
      options: Options(contentType: 'multipart/form-data', responseType: ResponseType.bytes));
    return response.data ?? [];
  }

  Future<List<int>> removeBackground({required List<int> imageBytes, required String filename}) async {
    final client = await _client;
    final formData = FormData.fromMap({'image': MultipartFile.fromBytes(imageBytes, filename: filename)});
    final response = await client.post<List<int>>('/stable-image/edit/remove-background',
      data: formData,
      options: Options(contentType: 'multipart/form-data', responseType: ResponseType.bytes));
    return response.data ?? [];
  }

  Future<List<int>> upscaleImage({required List<int> imageBytes, required String filename}) async {
    final client = await _client;
    final formData = FormData.fromMap({'image': MultipartFile.fromBytes(imageBytes, filename: filename)});
    final response = await client.post<List<int>>('/stable-image/upscale/conservative',
      data: formData,
      options: Options(contentType: 'multipart/form-data', responseType: ResponseType.bytes));
    return response.data ?? [];
  }
}
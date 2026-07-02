import 'dart:async';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/error/exceptions.dart';

class ReplicatePrediction {
  final String id; final String status;
  final List<String>? output; final String? error;
  const ReplicatePrediction({required this.id, required this.status, this.output, this.error});
  bool get isComplete => status == 'succeeded' || status == 'failed' || status == 'canceled';
  bool get isSuccessful => status == 'succeeded';
  factory ReplicatePrediction.fromJson(Map<String,dynamic> j) =>
    ReplicatePrediction(id: j['id'] as String, status: j['status'] as String,
      output: (j['output'] as List<dynamic>?)?.cast<String>(), error: j['error'] as String?);
}

class ReplicateDatasource {
  final SecureStorageService _secureStorage;
  Dio? _dio;
  ReplicateDatasource({required SecureStorageService secureStorage}) : _secureStorage = secureStorage;
  Future<Dio> get _client async {
    if (_dio != null) return _dio!;
    final k = await _secureStorage.getApiKey('replicate');
    if (k == null || k.isEmpty) throw AiProviderException.noApiKey('Replicate');
    _dio = ApiClient.create(baseUrl: ApiConstants.replicateBaseUrl, defaultHeaders: {'Authorization': 'Token $k'});
    return _dio!;
  }
  void invalidateClient() => _dio = null;

  Future<ReplicatePrediction> createPrediction({required String modelVersion, required Map<String,dynamic> input}) async {
    final client = await _client;
    final response = await client.post(ApiConstants.replicatePredictionsEndpoint,
      data: {'version': modelVersion, 'input': input});
    return ReplicatePrediction.fromJson(response.data as Map<String,dynamic>);
  }

  Future<ReplicatePrediction> getPrediction(String id) async {
    final client = await _client;
    final response = await client.get('${ApiConstants.replicatePredictionsEndpoint}/$id');
    return ReplicatePrediction.fromJson(response.data as Map<String,dynamic>);
  }

  Future<List<String>> generateFluxImage({required String prompt,
    String aspectRatio = '1:1', int numOutputs = 1}) async {
    const model = 'black-forest-labs/flux-1.1-pro';
    final pred = await createPrediction(modelVersion: model,
      input: {'prompt': prompt, 'aspect_ratio': aspectRatio, 'num_outputs': numOutputs});
    final deadline = DateTime.now().add(const Duration(minutes: 5));
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(seconds: 2));
      final p = await getPrediction(pred.id);
      if (p.isComplete) {
        if (p.isSuccessful) return p.output ?? [];
        throw ImageGenException.generationFailed(p.error ?? 'Unknown error');
      }
    }
    throw ImageGenException.generationFailed('Timed out');
  }
}
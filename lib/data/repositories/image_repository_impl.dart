import 'dart:convert';
import '../datasources/remote/openai_datasource.dart';
import '../datasources/remote/stability_datasource.dart';
import '../datasources/remote/replicate_datasource.dart';
import '../../core/error/exceptions.dart';

class ImageRepositoryImpl {
  final OpenAIDatasource _openAI;
  final StabilityDatasource _stability;
  final ReplicateDatasource _replicate;

  ImageRepositoryImpl({
    required OpenAIDatasource openAI,
    required StabilityDatasource stability,
    required ReplicateDatasource replicate,
  })  : _openAI = openAI,
        _stability = stability,
        _replicate = replicate;

  Future<List<String>> generateImages({
    required String provider,
    required String model,
    required String prompt,
    String? negativePrompt,
    int numImages = 1,
    String aspectRatio = '1:1',
    String? style,
    int steps = 28,
    double guidanceScale = 7.0,
  }) async {
    switch (provider.toLowerCase()) {
      case 'openai':
        return _openAI.generateImages(
          prompt: prompt,
          model: model,
          n: numImages,
          size: _ratioToDALLESize(aspectRatio),
          style: style,
          quality: model == 'dall-e-3' ? 'hd' : null,
        );

      case 'stability':
        final dims = _ratioToDims(aspectRatio);
        final bytes = await _stability.generateImage(
          prompt: prompt,
          negativePrompt: negativePrompt,
          model: model,
          width: dims.$1,
          height: dims.$2,
          steps: steps,
          cfgScale: guidanceScale,
          style: style,
        );
        return ['data:image/png;base64,${base64Encode(bytes)}'];

      case 'replicate':
        return _replicate.generateFluxImage(
          prompt: prompt,
          aspectRatio: aspectRatio,
          numOutputs: numImages,
        );

      default:
        throw AiProviderException(
          message: 'Unsupported image provider: $provider',
          providerId: provider,
        );
    }
  }

  String _ratioToDALLESize(String ratio) {
    switch (ratio) {
      case '16:9': return '1792x1024';
      case '9:16': return '1024x1792';
      default: return '1024x1024';
    }
  }

  (int, int) _ratioToDims(String ratio) {
    switch (ratio) {
      case '16:9': return (1344, 768);
      case '9:16': return (768, 1344);
      case '4:3': return (1152, 896);
      case '3:4': return (896, 1152);
      default: return (1024, 1024);
    }
  }

  Future<List<int>> removeBackground(List<int> bytes) =>
      _stability.removeBackground(imageBytes: bytes, filename: 'image.png');

  Future<List<int>> upscaleImage(List<int> bytes) =>
      _stability.upscaleImage(imageBytes: bytes, filename: 'image.png');
}

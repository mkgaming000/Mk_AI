import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/storage/database/hive_boxes.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/models/image_result_model.dart';

enum ImageGenStatus { idle, generating, error }

class ImageGenState {
  final ImageGenStatus status;
  final String prompt, negativePrompt, provider, model, aspectRatio;
  final String? style; final int numImages, steps; final double guidance;
  final List<String> generatedUrls; final String? error;
  const ImageGenState({
    this.status = ImageGenStatus.idle, this.prompt = '', this.negativePrompt = '',
    this.provider = 'openai', this.model = 'dall-e-3', this.aspectRatio = '1:1',
    this.style, this.numImages = 1, this.steps = 28, this.guidance = 7.0,
    this.generatedUrls = const [], this.error,
  });
  bool get isGenerating => status == ImageGenStatus.generating;
  ImageGenState copyWith({ImageGenStatus? status, String? prompt, String? negativePrompt,
    String? provider, String? model, String? aspectRatio, String? style,
    int? numImages, int? steps, double? guidance, List<String>? generatedUrls, String? error}) =>
    ImageGenState(status: status ?? this.status, prompt: prompt ?? this.prompt,
      negativePrompt: negativePrompt ?? this.negativePrompt, provider: provider ?? this.provider,
      model: model ?? this.model, aspectRatio: aspectRatio ?? this.aspectRatio,
      style: style ?? this.style, numImages: numImages ?? this.numImages,
      steps: steps ?? this.steps, guidance: guidance ?? this.guidance,
      generatedUrls: generatedUrls ?? this.generatedUrls, error: error);
}

class ImageGenNotifier extends StateNotifier<ImageGenState> {
  final Ref _ref; final _uuid = const Uuid();
  ImageGenNotifier(this._ref) : super(const ImageGenState());

  void setPrompt(String v) => state = state.copyWith(prompt: v);
  void setNegativePrompt(String v) => state = state.copyWith(negativePrompt: v);
  void setProvider(String v) => state = state.copyWith(provider: v);
  void setModel(String v) => state = state.copyWith(model: v);
  void setAspectRatio(String v) => state = state.copyWith(aspectRatio: v);
  void setStyle(String? v) => state = state.copyWith(style: v);
  void setNumImages(int v) => state = state.copyWith(numImages: v);
  void setSteps(int v) => state = state.copyWith(steps: v);
  void setGuidance(double v) => state = state.copyWith(guidance: v);

  Future<void> generate() async {
    if (state.prompt.trim().isEmpty) return;
    state = state.copyWith(status: ImageGenStatus.generating, error: null, generatedUrls: []);
    try {
      final urls = await _ref.read(imageRepositoryProvider).generateImages(
        provider: state.provider, model: state.model, prompt: state.prompt,
        negativePrompt: state.negativePrompt.isEmpty ? null : state.negativePrompt,
        numImages: state.numImages, aspectRatio: state.aspectRatio,
        style: state.style, steps: state.steps, guidanceScale: state.guidance,
      );
      final result = ImageResultModel(
        id: _uuid.v4(), prompt: state.prompt, negativePrompt: state.negativePrompt.isEmpty ? null : state.negativePrompt,
        providerId: state.provider, modelId: state.model, imageUrls: urls,
        createdAt: DateTime.now(), style: state.style, aspectRatio: state.aspectRatio,
      );
      await HiveBoxes.imageHistory.put(result.id, result);
      state = state.copyWith(status: ImageGenStatus.idle, generatedUrls: urls);
      NotificationService.instance.notifyGenerationComplete(
        feature: 'Image generation',
        summary: state.prompt.length > 60
            ? '${state.prompt.substring(0, 60)}...'
            : state.prompt,
      );
    } catch (e) {
      state = state.copyWith(status: ImageGenStatus.error, error: e.toString());
    }
  }

  Future<void> toggleFavorite(String id) async {
    final r = HiveBoxes.imageHistory.get(id);
    if (r == null) return;
    r.isFavorited = !r.isFavorited;
    await HiveBoxes.imageHistory.put(id, r);
  }
}

final imageGenProvider = StateNotifierProvider<ImageGenNotifier, ImageGenState>(
    (ref) => ImageGenNotifier(ref));
final imageHistoryProvider = Provider<List<ImageResultModel>>((_) =>
    HiveBoxes.imageHistory.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

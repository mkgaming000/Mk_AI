import 'package:hive/hive.dart';

class ImageResultModel extends HiveObject {
  static const int hiveTypeId = 4;
  String id;
  String prompt;
  String? negativePrompt;
  String providerId;
  String modelId;
  List<String> imageUrls;
  List<String>? localPaths;
  DateTime createdAt;
  int width;
  int height;
  double? cost;
  String? style;
  int? steps;
  double? guidanceScale;
  String? seed;
  String? aspectRatio;
  bool isFavorited;
  String? collectionId;

  ImageResultModel({
    required this.id, required this.prompt, this.negativePrompt,
    required this.providerId, required this.modelId, required this.imageUrls,
    this.localPaths, required this.createdAt, this.width = 1024,
    this.height = 1024, this.cost, this.style, this.steps,
    this.guidanceScale, this.seed, this.aspectRatio,
    this.isFavorited = false, this.collectionId,
  });

  ImageResultModel copyWith({
    String? id, String? prompt, String? negativePrompt, String? providerId,
    String? modelId, List<String>? imageUrls, DateTime? createdAt,
    int? width, int? height, double? cost, String? style, int? steps,
    double? guidanceScale, String? seed, String? aspectRatio,
    bool? isFavorited, String? collectionId}) =>
      ImageResultModel(
        id: id ?? this.id, prompt: prompt ?? this.prompt,
        negativePrompt: negativePrompt ?? this.negativePrompt,
        providerId: providerId ?? this.providerId,
        modelId: modelId ?? this.modelId,
        imageUrls: imageUrls ?? this.imageUrls,
        createdAt: createdAt ?? this.createdAt,
        width: width ?? this.width, height: height ?? this.height,
        cost: cost ?? this.cost, style: style ?? this.style,
        steps: steps ?? this.steps,
        guidanceScale: guidanceScale ?? this.guidanceScale,
        seed: seed ?? this.seed, aspectRatio: aspectRatio ?? this.aspectRatio,
        isFavorited: isFavorited ?? this.isFavorited,
        collectionId: collectionId ?? this.collectionId,
      );

  String get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
}

class ImageResultModelAdapter extends TypeAdapter<ImageResultModel> {
  @override
  final int typeId = ImageResultModel.hiveTypeId;
  @override
  ImageResultModel read(BinaryReader r) {
    final n = r.readByte();
    final f = <int,dynamic>{for(int i=0;i<n;i++) r.readByte():r.read()};
    return ImageResultModel(
      id: f[0] as String, prompt: f[1] as String,
      negativePrompt: f[2] as String?, providerId: f[3] as String,
      modelId: f[4] as String, imageUrls: (f[5] as List).cast<String>(),
      localPaths: (f[6] as List?)?.cast<String>(), createdAt: f[7] as DateTime,
      width: f[8] as int? ?? 1024, height: f[9] as int? ?? 1024,
      cost: (f[10] as num?)?.toDouble(), style: f[11] as String?,
      steps: f[12] as int?, guidanceScale: (f[13] as num?)?.toDouble(),
      seed: f[14] as String?, aspectRatio: f[15] as String?,
      isFavorited: f[16] as bool? ?? false, collectionId: f[17] as String?,
    );
  }
  @override
  void write(BinaryWriter w, ImageResultModel o) {
    w.writeByte(18);
    w..writeByte(0)..write(o.id)..writeByte(1)..write(o.prompt)
     ..writeByte(2)..write(o.negativePrompt)..writeByte(3)..write(o.providerId)
     ..writeByte(4)..write(o.modelId)..writeByte(5)..write(o.imageUrls)
     ..writeByte(6)..write(o.localPaths)..writeByte(7)..write(o.createdAt)
     ..writeByte(8)..write(o.width)..writeByte(9)..write(o.height)
     ..writeByte(10)..write(o.cost)..writeByte(11)..write(o.style)
     ..writeByte(12)..write(o.steps)..writeByte(13)..write(o.guidanceScale)
     ..writeByte(14)..write(o.seed)..writeByte(15)..write(o.aspectRatio)
     ..writeByte(16)..write(o.isFavorited)..writeByte(17)..write(o.collectionId);
  }
}

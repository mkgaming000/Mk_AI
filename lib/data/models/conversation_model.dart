import 'package:hive/hive.dart';

class ConversationModel extends HiveObject {
  static const int hiveTypeId = 1;

  String id;
  String title;
  String providerId;
  String modelId;
  DateTime createdAt;
  DateTime updatedAt;
  int totalTokens;
  double totalCost;
  int messageCount;
  String? systemPrompt;
  Map<String, dynamic>? metadata;
  bool isPinned;
  String? folderId;
  List<String> tags;
  double? temperature;
  int? maxTokens;

  ConversationModel({
    required this.id,
    required this.title,
    required this.providerId,
    required this.modelId,
    required this.createdAt,
    required this.updatedAt,
    this.totalTokens = 0,
    this.totalCost = 0.0,
    this.messageCount = 0,
    this.systemPrompt,
    this.metadata,
    this.isPinned = false,
    this.folderId,
    this.tags = const [],
    this.temperature,
    this.maxTokens,
  });

  ConversationModel copyWith({
    String? id, String? title, String? providerId, String? modelId,
    DateTime? createdAt, DateTime? updatedAt, int? totalTokens,
    double? totalCost, int? messageCount, String? systemPrompt,
    bool? isPinned, List<String>? tags, double? temperature, int? maxTokens,
  }) =>
      ConversationModel(
        id: id ?? this.id, title: title ?? this.title,
        providerId: providerId ?? this.providerId,
        modelId: modelId ?? this.modelId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        totalTokens: totalTokens ?? this.totalTokens,
        totalCost: totalCost ?? this.totalCost,
        messageCount: messageCount ?? this.messageCount,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        isPinned: isPinned ?? this.isPinned,
        tags: tags ?? this.tags,
        temperature: temperature ?? this.temperature,
        maxTokens: maxTokens ?? this.maxTokens,
      );
}

class ConversationModelAdapter extends TypeAdapter<ConversationModel> {
  @override
  final int typeId = ConversationModel.hiveTypeId;
  @override
  ConversationModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return ConversationModel(
      id: f[0] as String, title: f[1] as String,
      providerId: f[2] as String, modelId: f[3] as String,
      createdAt: f[4] as DateTime, updatedAt: f[5] as DateTime,
      totalTokens: f[6] as int? ?? 0,
      totalCost: (f[7] as num?)?.toDouble() ?? 0.0,
      messageCount: f[8] as int? ?? 0,
      systemPrompt: f[9] as String?,
      metadata: (f[10] as Map?)?.cast<String, dynamic>(),
      isPinned: f[11] as bool? ?? false,
      folderId: f[12] as String?,
      tags: (f[13] as List?)?.cast<String>() ?? [],
      temperature: (f[14] as num?)?.toDouble(),
      maxTokens: f[15] as int?,
    );
  }
  @override
  void write(BinaryWriter writer, ConversationModel o) {
    writer.writeByte(16);
    writer..writeByte(0)..write(o.id)..writeByte(1)..write(o.title)
      ..writeByte(2)..write(o.providerId)..writeByte(3)..write(o.modelId)
      ..writeByte(4)..write(o.createdAt)..writeByte(5)..write(o.updatedAt)
      ..writeByte(6)..write(o.totalTokens)..writeByte(7)..write(o.totalCost)
      ..writeByte(8)..write(o.messageCount)..writeByte(9)..write(o.systemPrompt)
      ..writeByte(10)..write(o.metadata)..writeByte(11)..write(o.isPinned)
      ..writeByte(12)..write(o.folderId)..writeByte(13)..write(o.tags)
      ..writeByte(14)..write(o.temperature)..writeByte(15)..write(o.maxTokens);
  }
}

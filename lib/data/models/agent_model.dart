import 'package:hive/hive.dart';

class AgentModel extends HiveObject {
  static const int hiveTypeId = 5;
  String id; String name; String description; String systemPrompt;
  String providerId; String modelId; List<String> tools;
  List<String> mcpServerIds; Map<String, dynamic> config; bool isActive;
  DateTime createdAt; DateTime updatedAt; String? iconEmoji; int? color;
  List<String> knowledgeBaseIds; double? temperature; int? maxIterations;
  bool enableMemory; bool enableWebSearch; bool enableCodeExecution;

  AgentModel({
    required this.id, required this.name, required this.description,
    required this.systemPrompt, required this.providerId, required this.modelId,
    this.tools = const [], this.mcpServerIds = const [],
    this.config = const {}, this.isActive = true,
    required this.createdAt, required this.updatedAt,
    this.iconEmoji, this.color, this.knowledgeBaseIds = const [],
    this.temperature, this.maxIterations,
    this.enableMemory = false, this.enableWebSearch = false,
    this.enableCodeExecution = false,
  });

  AgentModel copyWith({
    String? id, String? name, String? description, String? systemPrompt,
    String? providerId, String? modelId, List<String>? tools,
    List<String>? mcpServerIds, bool? isActive, DateTime? createdAt,
    DateTime? updatedAt, String? iconEmoji, int? color,
    double? temperature, int? maxIterations,
    bool? enableMemory, bool? enableWebSearch, bool? enableCodeExecution}) =>
      AgentModel(
        id: id ?? this.id, name: name ?? this.name,
        description: description ?? this.description,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        providerId: providerId ?? this.providerId,
        modelId: modelId ?? this.modelId,
        tools: tools ?? this.tools,
        mcpServerIds: mcpServerIds ?? this.mcpServerIds,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        iconEmoji: iconEmoji ?? this.iconEmoji,
        color: color ?? this.color,
        temperature: temperature ?? this.temperature,
        maxIterations: maxIterations ?? this.maxIterations,
        enableMemory: enableMemory ?? this.enableMemory,
        enableWebSearch: enableWebSearch ?? this.enableWebSearch,
        enableCodeExecution: enableCodeExecution ?? this.enableCodeExecution,
      );
}

class AgentModelAdapter extends TypeAdapter<AgentModel> {
  @override
  final int typeId = AgentModel.hiveTypeId;
  @override
  AgentModel read(BinaryReader r) {
    final n = r.readByte();
    final f = <int,dynamic>{for(int i=0;i<n;i++) r.readByte():r.read()};
    return AgentModel(
      id: f[0] as String, name: f[1] as String,
      description: f[2] as String, systemPrompt: f[3] as String,
      providerId: f[4] as String, modelId: f[5] as String,
      tools: (f[6] as List?)?.cast<String>() ?? [],
      mcpServerIds: (f[7] as List?)?.cast<String>() ?? [],
      config: (f[8] as Map?)?.cast<String,dynamic>() ?? {},
      isActive: f[9] as bool? ?? true,
      createdAt: f[10] as DateTime, updatedAt: f[11] as DateTime,
      iconEmoji: f[12] as String?, color: f[13] as int?,
      knowledgeBaseIds: (f[14] as List?)?.cast<String>() ?? [],
      temperature: (f[15] as num?)?.toDouble(),
      maxIterations: f[16] as int?,
      enableMemory: f[17] as bool? ?? false,
      enableWebSearch: f[18] as bool? ?? false,
      enableCodeExecution: f[19] as bool? ?? false,
    );
  }
  @override
  void write(BinaryWriter w, AgentModel o) {
    w.writeByte(20);
    w..writeByte(0)..write(o.id)..writeByte(1)..write(o.name)
     ..writeByte(2)..write(o.description)..writeByte(3)..write(o.systemPrompt)
     ..writeByte(4)..write(o.providerId)..writeByte(5)..write(o.modelId)
     ..writeByte(6)..write(o.tools)..writeByte(7)..write(o.mcpServerIds)
     ..writeByte(8)..write(o.config)..writeByte(9)..write(o.isActive)
     ..writeByte(10)..write(o.createdAt)..writeByte(11)..write(o.updatedAt)
     ..writeByte(12)..write(o.iconEmoji)..writeByte(13)..write(o.color)
     ..writeByte(14)..write(o.knowledgeBaseIds)..writeByte(15)..write(o.temperature)
     ..writeByte(16)..write(o.maxIterations)..writeByte(17)..write(o.enableMemory)
     ..writeByte(18)..write(o.enableWebSearch)..writeByte(19)..write(o.enableCodeExecution);
  }
}

// ignore_for_file: constant_identifier_names
import 'package:hive/hive.dart';

// TypeIds: MessageRole=20, MessageContentType=21, MessageModel=2

part 'message_model.g.dart';

@HiveType(typeId: 20)
enum MessageRole {
  @HiveField(0)
  user,
  @HiveField(1)
  assistant,
  @HiveField(2)
  system,
  @HiveField(3)
  tool,
}

@HiveType(typeId: 21)
enum MessageContentType {
  @HiveField(0)
  text,
  @HiveField(1)
  image,
  @HiveField(2)
  file,
  @HiveField(3)
  audio,
  @HiveField(4)
  code,
  @HiveField(5)
  thinking,
  @HiveField(6)
  toolUse,
  @HiveField(7)
  toolResult,
  @HiveField(8)
  error,
}

@HiveType(typeId: 2)
class MessageModel extends HiveObject {
  static const int hiveTypeId = 2;

  @HiveField(0)
  String id;
  @HiveField(1)
  String conversationId;
  @HiveField(2)
  MessageRole role;
  @HiveField(3)
  String content;
  @HiveField(4)
  DateTime createdAt;
  @HiveField(5)
  String? modelId;
  @HiveField(6)
  String? providerId;
  @HiveField(7)
  int? inputTokens;
  @HiveField(8)
  int? outputTokens;
  @HiveField(9)
  double? cost;
  @HiveField(10)
  int? durationMs;
  @HiveField(11)
  MessageContentType contentType;
  @HiveField(12)
  List<Map<String, dynamic>>? attachments;
  @HiveField(13)
  String? thinking;
  @HiveField(14)
  bool isStreaming;
  @HiveField(15)
  bool hasError;
  @HiveField(16)
  String? errorMessage;
  @HiveField(17)
  Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.modelId,
    this.providerId,
    this.inputTokens,
    this.outputTokens,
    this.cost,
    this.durationMs,
    this.contentType = MessageContentType.text,
    this.attachments,
    this.thinking,
    this.isStreaming = false,
    this.hasError = false,
    this.errorMessage,
    this.metadata,
  });

  MessageModel copyWith({
    String? id,
    String? conversationId,
    MessageRole? role,
    String? content,
    DateTime? createdAt,
    String? modelId,
    String? providerId,
    int? inputTokens,
    int? outputTokens,
    double? cost,
    int? durationMs,
    MessageContentType? contentType,
    List<Map<String, dynamic>>? attachments,
    String? thinking,
    bool? isStreaming,
    bool? hasError,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      modelId: modelId ?? this.modelId,
      providerId: providerId ?? this.providerId,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      cost: cost ?? this.cost,
      durationMs: durationMs ?? this.durationMs,
      contentType: contentType ?? this.contentType,
      attachments: attachments ?? this.attachments,
      thinking: thinking ?? this.thinking,
      isStreaming: isStreaming ?? this.isStreaming,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toOpenAIMessage() {
    final Map<String, dynamic> msg = {'role': role.name};
    if (attachments != null && attachments!.isNotEmpty) {
      msg['content'] = [
        {'type': 'text', 'text': content},
        ...attachments!.map((a) {
          if (a['type'] == 'image') {
            return {
              'type': 'image_url',
              'image_url': {'url': 'data:${a['mediaType']};base64,${a['data']}'},
            };
          }
          return a;
        }),
      ];
    } else {
      msg['content'] = content;
    }
    return msg;
  }

  Map<String, dynamic> toAnthropicMessage() {
    if (attachments != null && attachments!.isNotEmpty) {
      final contentBlocks = <Map<String, dynamic>>[
        {'type': 'text', 'text': content},
        ...attachments!.map((a) {
          if (a['type'] == 'image') {
            return {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': a['mediaType'],
                'data': a['data'],
              },
            };
          }
          return a;
        }),
      ];
      return {
        'role': role == MessageRole.user ? 'user' : 'assistant',
        'content': contentBlocks,
      };
    }
    return {
      'role': role == MessageRole.user ? 'user' : 'assistant',
      'content': content,
    };
  }

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isSystem => role == MessageRole.system;
  int get totalTokens => (inputTokens ?? 0) + (outputTokens ?? 0);
}

// ── Manual Hive Adapters (no build_runner needed) ─────────────────────────

class MessageModelAdapter extends TypeAdapter<MessageModel> {
  @override
  final int typeId = 2;

  @override
  MessageModel read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return MessageModel(
      id: fields[0] as String,
      conversationId: fields[1] as String,
      role: fields[2] as MessageRole,
      content: fields[3] as String,
      createdAt: fields[4] as DateTime,
      modelId: fields[5] as String?,
      providerId: fields[6] as String?,
      inputTokens: fields[7] as int?,
      outputTokens: fields[8] as int?,
      cost: (fields[9] as num?)?.toDouble(),
      durationMs: fields[10] as int?,
      contentType:
          fields[11] as MessageContentType? ?? MessageContentType.text,
      attachments: (fields[12] as List?)
          ?.map((e) => (e as Map).cast<String, dynamic>())
          .toList(),
      thinking: fields[13] as String?,
      isStreaming: fields[14] as bool? ?? false,
      hasError: fields[15] as bool? ?? false,
      errorMessage: fields[16] as String?,
      metadata: (fields[17] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, MessageModel obj) {
    writer.writeByte(18);
    writer
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.conversationId)
      ..writeByte(2)..write(obj.role)
      ..writeByte(3)..write(obj.content)
      ..writeByte(4)..write(obj.createdAt)
      ..writeByte(5)..write(obj.modelId)
      ..writeByte(6)..write(obj.providerId)
      ..writeByte(7)..write(obj.inputTokens)
      ..writeByte(8)..write(obj.outputTokens)
      ..writeByte(9)..write(obj.cost)
      ..writeByte(10)..write(obj.durationMs)
      ..writeByte(11)..write(obj.contentType)
      ..writeByte(12)..write(obj.attachments)
      ..writeByte(13)..write(obj.thinking)
      ..writeByte(14)..write(obj.isStreaming)
      ..writeByte(15)..write(obj.hasError)
      ..writeByte(16)..write(obj.errorMessage)
      ..writeByte(17)..write(obj.metadata);
  }
}

class MessageRoleAdapter extends TypeAdapter<MessageRole> {
  @override
  final int typeId = 20;
  @override
  MessageRole read(BinaryReader reader) =>
      MessageRole.values[reader.readByte()];
  @override
  void write(BinaryWriter writer, MessageRole obj) =>
      writer.writeByte(obj.index);
}

class MessageContentTypeAdapter extends TypeAdapter<MessageContentType> {
  @override
  final int typeId = 21;
  @override
  MessageContentType read(BinaryReader reader) =>
      MessageContentType.values[reader.readByte()];
  @override
  void write(BinaryWriter writer, MessageContentType obj) =>
      writer.writeByte(obj.index);
}

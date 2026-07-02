import 'package:hive/hive.dart';

class ApiKeyModel extends HiveObject {
  static const int hiveTypeId = 3;
  String id;
  String providerId;
  String providerName;
  bool isActive;
  DateTime addedAt;
  DateTime? lastUsed;
  bool isValid;
  String? maskedKey;
  String? baseUrl;
  Map<String, dynamic>? additionalConfig;

  ApiKeyModel({
    required this.id, required this.providerId, required this.providerName,
    this.isActive = true, required this.addedAt, this.lastUsed,
    this.isValid = true, this.maskedKey, this.baseUrl, this.additionalConfig,
  });

  ApiKeyModel copyWith({String? id, String? providerId, String? providerName,
    bool? isActive, DateTime? addedAt, DateTime? lastUsed, bool? isValid,
    String? maskedKey, String? baseUrl}) =>
      ApiKeyModel(
        id: id ?? this.id, providerId: providerId ?? this.providerId,
        providerName: providerName ?? this.providerName,
        isActive: isActive ?? this.isActive,
        addedAt: addedAt ?? this.addedAt, lastUsed: lastUsed ?? this.lastUsed,
        isValid: isValid ?? this.isValid,
        maskedKey: maskedKey ?? this.maskedKey, baseUrl: baseUrl ?? this.baseUrl,
      );
}

class ApiKeyModelAdapter extends TypeAdapter<ApiKeyModel> {
  @override
  final int typeId = ApiKeyModel.hiveTypeId;
  @override
  ApiKeyModel read(BinaryReader r) {
    final n = r.readByte();
    final f = <int,dynamic>{for(int i=0;i<n;i++) r.readByte():r.read()};
    return ApiKeyModel(
      id: f[0] as String, providerId: f[1] as String,
      providerName: f[2] as String, isActive: f[3] as bool? ?? true,
      addedAt: f[4] as DateTime, lastUsed: f[5] as DateTime?,
      isValid: f[6] as bool? ?? true, maskedKey: f[7] as String?,
      baseUrl: f[8] as String?,
      additionalConfig: (f[9] as Map?)?.cast<String,dynamic>(),
    );
  }
  @override
  void write(BinaryWriter w, ApiKeyModel o) {
    w.writeByte(10);
    w..writeByte(0)..write(o.id)..writeByte(1)..write(o.providerId)
     ..writeByte(2)..write(o.providerName)..writeByte(3)..write(o.isActive)
     ..writeByte(4)..write(o.addedAt)..writeByte(5)..write(o.lastUsed)
     ..writeByte(6)..write(o.isValid)..writeByte(7)..write(o.maskedKey)
     ..writeByte(8)..write(o.baseUrl)..writeByte(9)..write(o.additionalConfig);
  }
}

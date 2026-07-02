import 'package:hive/hive.dart';

class UsageStatModel extends HiveObject {
  static const int hiveTypeId = 6;
  String id; String providerId; String modelId; String featureType;
  int inputTokens; int outputTokens; double cost; int requestCount;
  DateTime date; int durationMs;

  UsageStatModel({
    required this.id, required this.providerId, required this.modelId,
    required this.featureType, this.inputTokens = 0, this.outputTokens = 0,
    this.cost = 0.0, this.requestCount = 0, required this.date,
    this.durationMs = 0,
  });

  int get totalTokens => inputTokens + outputTokens;
}

class UsageStatModelAdapter extends TypeAdapter<UsageStatModel> {
  @override
  final int typeId = UsageStatModel.hiveTypeId;
  @override
  UsageStatModel read(BinaryReader r) {
    final n = r.readByte();
    final f = <int,dynamic>{for(int i=0;i<n;i++) r.readByte():r.read()};
    return UsageStatModel(
      id: f[0] as String, providerId: f[1] as String,
      modelId: f[2] as String, featureType: f[3] as String,
      inputTokens: f[4] as int? ?? 0, outputTokens: f[5] as int? ?? 0,
      cost: (f[6] as num?)?.toDouble() ?? 0.0,
      requestCount: f[7] as int? ?? 0, date: f[8] as DateTime,
      durationMs: f[9] as int? ?? 0,
    );
  }
  @override
  void write(BinaryWriter w, UsageStatModel o) {
    w.writeByte(10);
    w..writeByte(0)..write(o.id)..writeByte(1)..write(o.providerId)
     ..writeByte(2)..write(o.modelId)..writeByte(3)..write(o.featureType)
     ..writeByte(4)..write(o.inputTokens)..writeByte(5)..write(o.outputTokens)
     ..writeByte(6)..write(o.cost)..writeByte(7)..write(o.requestCount)
     ..writeByte(8)..write(o.date)..writeByte(9)..write(o.durationMs);
  }
}

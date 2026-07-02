import 'package:hive/hive.dart';

class McpServerModel extends HiveObject {
  static const int hiveTypeId = 9;
  String id; String name; String url; String? description;
  bool isConnected; bool isEnabled; Map<String,dynamic> tools;
  DateTime addedAt; DateTime? lastConnected;
  Map<String,String> headers; List<String> allowedTools;
  String? iconUrl; String? category;

  McpServerModel({
    required this.id, required this.name, required this.url,
    this.description, this.isConnected = false, this.isEnabled = true,
    this.tools = const {}, required this.addedAt, this.lastConnected,
    this.headers = const {}, this.allowedTools = const [],
    this.iconUrl, this.category,
  });
}

class McpServerModelAdapter extends TypeAdapter<McpServerModel> {
  @override
  final int typeId = McpServerModel.hiveTypeId;
  @override
  McpServerModel read(BinaryReader r) {
    final n = r.readByte();
    final f = <int,dynamic>{for(int i=0;i<n;i++) r.readByte():r.read()};
    return McpServerModel(
      id: f[0] as String, name: f[1] as String, url: f[2] as String,
      description: f[3] as String?, isConnected: f[4] as bool? ?? false,
      isEnabled: f[5] as bool? ?? true,
      tools: (f[6] as Map?)?.cast<String,dynamic>() ?? {},
      addedAt: f[7] as DateTime, lastConnected: f[8] as DateTime?,
      headers: (f[9] as Map?)?.cast<String,String>() ?? {},
      allowedTools: (f[10] as List?)?.cast<String>() ?? [],
      iconUrl: f[11] as String?, category: f[12] as String?,
    );
  }
  @override
  void write(BinaryWriter w, McpServerModel o) {
    w.writeByte(13);
    w..writeByte(0)..write(o.id)..writeByte(1)..write(o.name)
     ..writeByte(2)..write(o.url)..writeByte(3)..write(o.description)
     ..writeByte(4)..write(o.isConnected)..writeByte(5)..write(o.isEnabled)
     ..writeByte(6)..write(o.tools)..writeByte(7)..write(o.addedAt)
     ..writeByte(8)..write(o.lastConnected)..writeByte(9)..write(o.headers)
     ..writeByte(10)..write(o.allowedTools)..writeByte(11)..write(o.iconUrl)
     ..writeByte(12)..write(o.category);
  }
}

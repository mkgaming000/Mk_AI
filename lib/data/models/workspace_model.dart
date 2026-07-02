import 'package:hive/hive.dart';

class WorkspaceModel extends HiveObject {
  static const int hiveTypeId = 7;
  String id; String name; String rootPath; DateTime createdAt;
  DateTime lastOpenedAt; String? description; String? iconEmoji;
  Map<String, dynamic> settings; List<String> recentFiles; bool isPinned;

  WorkspaceModel({
    required this.id, required this.name, required this.rootPath,
    required this.createdAt, required this.lastOpenedAt,
    this.description, this.iconEmoji, this.settings = const {},
    this.recentFiles = const [], this.isPinned = false,
  });
}

class WorkspaceModelAdapter extends TypeAdapter<WorkspaceModel> {
  @override
  final int typeId = WorkspaceModel.hiveTypeId;
  @override
  WorkspaceModel read(BinaryReader r) {
    final n = r.readByte();
    final f = <int,dynamic>{for(int i=0;i<n;i++) r.readByte():r.read()};
    return WorkspaceModel(
      id: f[0] as String, name: f[1] as String, rootPath: f[2] as String,
      createdAt: f[3] as DateTime, lastOpenedAt: f[4] as DateTime,
      description: f[5] as String?, iconEmoji: f[6] as String?,
      settings: (f[7] as Map?)?.cast<String,dynamic>() ?? {},
      recentFiles: (f[8] as List?)?.cast<String>() ?? [],
      isPinned: f[9] as bool? ?? false,
    );
  }
  @override
  void write(BinaryWriter w, WorkspaceModel o) {
    w.writeByte(10);
    w..writeByte(0)..write(o.id)..writeByte(1)..write(o.name)
     ..writeByte(2)..write(o.rootPath)..writeByte(3)..write(o.createdAt)
     ..writeByte(4)..write(o.lastOpenedAt)..writeByte(5)..write(o.description)
     ..writeByte(6)..write(o.iconEmoji)..writeByte(7)..write(o.settings)
     ..writeByte(8)..write(o.recentFiles)..writeByte(9)..write(o.isPinned);
  }
}

import 'package:hive/hive.dart';

class CodeProjectModel extends HiveObject {
  static const int hiveTypeId = 8;
  String id; String name; String workspaceId; String language;
  String? description; List<String> openFiles; String? activeFile;
  DateTime createdAt; DateTime updatedAt; Map<String,dynamic> editorSettings;
  List<String> tags; String? gitRemoteUrl; String? gitBranch;

  CodeProjectModel({
    required this.id, required this.name, required this.workspaceId,
    required this.language, this.description, this.openFiles = const [],
    this.activeFile, required this.createdAt, required this.updatedAt,
    this.editorSettings = const {}, this.tags = const [],
    this.gitRemoteUrl, this.gitBranch,
  });
}

class CodeProjectModelAdapter extends TypeAdapter<CodeProjectModel> {
  @override
  final int typeId = CodeProjectModel.hiveTypeId;
  @override
  CodeProjectModel read(BinaryReader r) {
    final n = r.readByte();
    final f = <int,dynamic>{for(int i=0;i<n;i++) r.readByte():r.read()};
    return CodeProjectModel(
      id: f[0] as String, name: f[1] as String, workspaceId: f[2] as String,
      language: f[3] as String, description: f[4] as String?,
      openFiles: (f[5] as List?)?.cast<String>() ?? [],
      activeFile: f[6] as String?, createdAt: f[7] as DateTime,
      updatedAt: f[8] as DateTime,
      editorSettings: (f[9] as Map?)?.cast<String,dynamic>() ?? {},
      tags: (f[10] as List?)?.cast<String>() ?? [],
      gitRemoteUrl: f[11] as String?, gitBranch: f[12] as String?,
    );
  }
  @override
  void write(BinaryWriter w, CodeProjectModel o) {
    w.writeByte(13);
    w..writeByte(0)..write(o.id)..writeByte(1)..write(o.name)
     ..writeByte(2)..write(o.workspaceId)..writeByte(3)..write(o.language)
     ..writeByte(4)..write(o.description)..writeByte(5)..write(o.openFiles)
     ..writeByte(6)..write(o.activeFile)..writeByte(7)..write(o.createdAt)
     ..writeByte(8)..write(o.updatedAt)..writeByte(9)..write(o.editorSettings)
     ..writeByte(10)..write(o.tags)..writeByte(11)..write(o.gitRemoteUrl)
     ..writeByte(12)..write(o.gitBranch);
  }
}

import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/api_key_model.dart';
import '../../../data/models/image_result_model.dart';
import '../../../data/models/agent_model.dart';
import '../../../data/models/usage_stat_model.dart';
import '../../../data/models/workspace_model.dart';
import '../../../data/models/code_project_model.dart';
import '../../../data/models/mcp_server_model.dart';
import '../../constants/app_constants.dart';

class HiveBoxes {
  HiveBoxes._();

  static void registerAdapters() {
    _safeRegister(ConversationModelAdapter(), ConversationModel.hiveTypeId);
    _safeRegister(MessageModelAdapter(), MessageModel.hiveTypeId);
    _safeRegister(MessageRoleAdapter(), 20);
    _safeRegister(MessageContentTypeAdapter(), 21);
    _safeRegister(ApiKeyModelAdapter(), ApiKeyModel.hiveTypeId);
    _safeRegister(ImageResultModelAdapter(), ImageResultModel.hiveTypeId);
    _safeRegister(AgentModelAdapter(), AgentModel.hiveTypeId);
    _safeRegister(UsageStatModelAdapter(), UsageStatModel.hiveTypeId);
    _safeRegister(WorkspaceModelAdapter(), WorkspaceModel.hiveTypeId);
    _safeRegister(CodeProjectModelAdapter(), CodeProjectModel.hiveTypeId);
    _safeRegister(McpServerModelAdapter(), McpServerModel.hiveTypeId);
  }

  static void _safeRegister(TypeAdapter adapter, int typeId) {
    if (!Hive.isAdapterRegistered(typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  static Future<void> openAllBoxes() async {
    await Future.wait([
      Hive.openBox<ConversationModel>(AppConstants.boxConversations),
      Hive.openBox<MessageModel>(AppConstants.boxMessages),
      Hive.openBox<ApiKeyModel>(AppConstants.boxApiKeys),
      Hive.openBox<ImageResultModel>(AppConstants.boxImageHistory),
      Hive.openBox<AgentModel>(AppConstants.boxAgents),
      Hive.openBox<UsageStatModel>(AppConstants.boxUsageStats),
      Hive.openBox<WorkspaceModel>(AppConstants.boxWorkspaces),
      Hive.openBox<CodeProjectModel>(AppConstants.boxCodeProjects),
      Hive.openBox<McpServerModel>(AppConstants.boxMcpServers),
    ]);
  }

  static Box<ConversationModel> get conversations =>
      Hive.box<ConversationModel>(AppConstants.boxConversations);
  static Box<MessageModel> get messages =>
      Hive.box<MessageModel>(AppConstants.boxMessages);
  static Box<ApiKeyModel> get apiKeys =>
      Hive.box<ApiKeyModel>(AppConstants.boxApiKeys);
  static Box<ImageResultModel> get imageHistory =>
      Hive.box<ImageResultModel>(AppConstants.boxImageHistory);
  static Box<AgentModel> get agents =>
      Hive.box<AgentModel>(AppConstants.boxAgents);
  static Box<UsageStatModel> get usageStats =>
      Hive.box<UsageStatModel>(AppConstants.boxUsageStats);
  static Box<WorkspaceModel> get workspaces =>
      Hive.box<WorkspaceModel>(AppConstants.boxWorkspaces);
  static Box<CodeProjectModel> get codeProjects =>
      Hive.box<CodeProjectModel>(AppConstants.boxCodeProjects);
  static Box<McpServerModel> get mcpServers =>
      Hive.box<McpServerModel>(AppConstants.boxMcpServers);
}

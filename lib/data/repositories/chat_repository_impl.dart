import 'package:uuid/uuid.dart';
import '../../core/storage/local_storage_service.dart';
import '../datasources/local/conversation_local_datasource.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/ai_router_service.dart';
import '../services/token_counter_service.dart';
import '../services/cost_tracker_service.dart';

class ChatRepositoryImpl {
  final AiRouterService _aiRouter;
  final ConversationLocalDatasource _local;
  final LocalStorageService _storage;
  final TokenCounterService _tokenCounter;
  final CostTrackerService _costTracker;
  final _uuid = const Uuid();

  ChatRepositoryImpl({
    required AiRouterService aiRouter,
    required ConversationLocalDatasource localDatasource,
    required LocalStorageService localStorage,
    required TokenCounterService tokenCounter,
    required CostTrackerService costTracker,
  })  : _aiRouter = aiRouter,
        _local = localDatasource,
        _storage = localStorage,
        _tokenCounter = tokenCounter,
        _costTracker = costTracker;

  // ── Conversations ─────────────────────────────────────────────────────

  Future<ConversationModel> createConversation({
    required String providerId,
    required String modelId,
    String? title,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    final c = ConversationModel(
      id: _uuid.v4(),
      title: title ?? 'New Chat',
      providerId: providerId,
      modelId: modelId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      systemPrompt: systemPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );
    await _local.saveConversation(c);
    return c;
  }

  List<ConversationModel> getAllConversations() =>
      _local.getAllConversations();
  List<ConversationModel> searchConversations(String q) =>
      _local.searchConversations(q);
  List<ConversationModel> getRecentConversations([int limit = 10]) =>
      _local.getRecentConversations(limit);
  ConversationModel? getConversation(String id) =>
      _local.getConversation(id);

  Future<void> deleteConversation(String id) =>
      _local.deleteConversation(id);
  Future<void> updateConversationTitle(String id, String title) =>
      _local.updateTitle(id, title);
  Future<void> pinConversation(String id, bool pinned) =>
      _local.pinConversation(id, pinned);

  // ── Messages ──────────────────────────────────────────────────────────

  List<MessageModel> getMessages(String conversationId) =>
      _local.getMessages(conversationId);

  Future<MessageModel> saveUserMessage({
    required String conversationId,
    required String content,
    List<Map<String, dynamic>>? attachments,
  }) async {
    final m = MessageModel(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: MessageRole.user,
      content: content,
      createdAt: DateTime.now(),
      attachments: attachments,
    );
    await _local.saveMessage(m);
    return m;
  }

  Future<MessageModel> createAssistantMessage({
    required String conversationId,
    required String providerId,
    required String modelId,
  }) async {
    final m = MessageModel(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
      providerId: providerId,
      modelId: modelId,
      isStreaming: true,
    );
    await _local.saveMessage(m);
    return m;
  }

  Future<void> updateMessage(MessageModel m) => _local.updateMessage(m);
  Future<void> deleteMessage(String id) => _local.deleteMessage(id);
  Future<void> clearMessages(String conversationId) =>
      _local.clearMessages(conversationId);

  // ── Streaming ─────────────────────────────────────────────────────────

  Stream<String> streamResponse({
    required String providerId,
    required String modelId,
    required List<MessageModel> messages,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    Map<String, dynamic>? providerOptions,
  }) {
    return _aiRouter.streamChat(
      providerId: providerId,
      modelId: modelId,
      messages: messages,
      systemPrompt: systemPrompt,
      temperature: temperature ??
          _storage.getDoubleOrDefault('default_temperature', 0.7),
      maxTokens: maxTokens,
      providerOptions: providerOptions,
    );
  }

  Future<List<String>> getModelsForProvider(String providerId) =>
      _aiRouter.getModelsForProvider(providerId);

  void invalidateProvider(String providerId) =>
      _aiRouter.invalidateProvider(providerId);

  /// Estimates token usage and cost for a completed exchange, persists it
  /// to the cost tracker (so Usage & Costs reflects real spend), and
  /// returns the computed values so the caller can attach them to the
  /// stored message.
  ({int inputTokens, int outputTokens, double cost}) recordMessageUsage({
    required String providerId,
    required String modelId,
    required List<MessageModel> promptMessages,
    required String responseContent,
    required int durationMs,
    String featureType = 'chat',
  }) {
    final inputTokens = _tokenCounter.estimateConversationTokens(
        promptMessages.map((m) => m.content).toList());
    final outputTokens = _tokenCounter.estimateTokens(responseContent);
    final cost = _tokenCounter.calculateCost(
      providerId: providerId,
      modelId: modelId,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
    );

    _costTracker.recordUsage(
      providerId: providerId,
      modelId: modelId,
      featureType: featureType,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      cost: cost,
      durationMs: durationMs,
    );

    return (inputTokens: inputTokens, outputTokens: outputTokens, cost: cost);
  }

  Future<void> autoTitle(String conversationId, String firstMessage) async {
    final c = _local.getConversation(conversationId);
    if (c == null || c.title != 'New Chat') return;
    final title = firstMessage.length > 50
        ? '${firstMessage.substring(0, 47)}...'
        : firstMessage;
    await _local.updateTitle(conversationId, title);
  }
}

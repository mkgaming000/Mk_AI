import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/repositories/chat_repository_impl.dart';
import '../../settings/providers/settings_provider.dart';

class ConversationListNotifier extends StateNotifier<AsyncValue<List<ConversationModel>>> {
  final ChatRepositoryImpl _repo;
  String _query = '';
  ConversationListNotifier(this._repo) : super(const AsyncValue.loading()) { _load(); }
  void _load() {
    try {
      final list = _query.isEmpty ? _repo.getAllConversations() : _repo.searchConversations(_query);
      state = AsyncValue.data(list);
    } catch (e, s) { state = AsyncValue.error(e, s); }
  }
  void search(String q) { _query = q; _load(); }
  void refresh() => _load();
  Future<void> deleteConversation(String id) async { await _repo.deleteConversation(id); _load(); }
  Future<void> pinConversation(String id, bool p) async { await _repo.pinConversation(id, p); _load(); }
  Future<void> renameConversation(String id, String t) async { await _repo.updateConversationTitle(id, t); _load(); }
}

final conversationListProvider = StateNotifierProvider<ConversationListNotifier, AsyncValue<List<ConversationModel>>>(
  (ref) => ConversationListNotifier(ref.read(chatRepositoryProvider)));

enum ChatStatus { idle, loading, streaming, error }

class ChatState {
  final ConversationModel? conversation;
  final List<MessageModel> messages;
  final ChatStatus status;
  final String? error;
  final String? streamingMessageId;
  final bool isThinking;
  final String? thinkingContent;
  final String selectedProviderId;
  final String selectedModelId;
  final String? systemPrompt;
  final double temperature;
  final int maxTokens;

  const ChatState({
    this.conversation, this.messages = const [], this.status = ChatStatus.idle,
    this.error, this.streamingMessageId, this.isThinking = false,
    this.thinkingContent, required this.selectedProviderId,
    required this.selectedModelId, this.systemPrompt,
    this.temperature = 0.7, this.maxTokens = 4096,
  });

  ChatState copyWith({
    ConversationModel? conversation, List<MessageModel>? messages,
    ChatStatus? status, String? error, String? streamingMessageId,
    bool? isThinking, String? thinkingContent,
    String? selectedProviderId, String? selectedModelId,
    String? systemPrompt, double? temperature, int? maxTokens,
  }) => ChatState(
    conversation: conversation ?? this.conversation,
    messages: messages ?? this.messages,
    status: status ?? this.status, error: error,
    streamingMessageId: streamingMessageId ?? this.streamingMessageId,
    isThinking: isThinking ?? this.isThinking,
    thinkingContent: thinkingContent ?? this.thinkingContent,
    selectedProviderId: selectedProviderId ?? this.selectedProviderId,
    selectedModelId: selectedModelId ?? this.selectedModelId,
    systemPrompt: systemPrompt ?? this.systemPrompt,
    temperature: temperature ?? this.temperature,
    maxTokens: maxTokens ?? this.maxTokens,
  );

  bool get isIdle => status == ChatStatus.idle;
  bool get isLoading => status == ChatStatus.loading;
  bool get isStreaming => status == ChatStatus.streaming;
  bool get hasError => status == ChatStatus.error;
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepositoryImpl _repo;
  final Ref _ref;
  StreamSubscription<String>? _sub;
  final _uuid = const Uuid();

  ChatNotifier(this._repo, this._ref, String provider, String model)
      : super(ChatState(selectedProviderId: provider, selectedModelId: model));

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  Future<void> loadConversation(String id) async {
    final c = _repo.getConversation(id);
    if (c == null) return;
    final msgs = _repo.getMessages(id);
    state = state.copyWith(conversation: c, messages: msgs,
      selectedProviderId: c.providerId, selectedModelId: c.modelId);
  }

  void selectProvider(String p) => state = state.copyWith(selectedProviderId: p);
  void selectModel(String m) => state = state.copyWith(selectedModelId: m);
  void setSystemPrompt(String? p) => state = state.copyWith(systemPrompt: p);
  void setTemperature(double t) => state = state.copyWith(temperature: t);
  void setMaxTokens(int t) => state = state.copyWith(maxTokens: t);

  Future<void> sendMessage({required String content, List<Map<String, dynamic>>? attachments}) async {
    if (content.trim().isEmpty && (attachments == null || attachments.isEmpty)) return;
    if (state.isStreaming || state.isLoading) return;
    await _sub?.cancel();

    final streamingEnabled = _ref.read(settingsProvider).streamingEnabled;

    state = state.copyWith(status: ChatStatus.loading, error: null);
    try {
      ConversationModel conv = state.conversation ??
          await _repo.createConversation(
            providerId: state.selectedProviderId, modelId: state.selectedModelId,
            systemPrompt: state.systemPrompt, temperature: state.temperature,
            maxTokens: state.maxTokens,
          );
      final userMsg = await _repo.saveUserMessage(
        conversationId: conv.id, content: content.trim(), attachments: attachments);
      final msgsWithUser = [...state.messages, userMsg];
      state = state.copyWith(conversation: conv, messages: msgsWithUser, status: ChatStatus.streaming);

      final assistantMsg = await _repo.createAssistantMessage(
        conversationId: conv.id,
        providerId: state.selectedProviderId, modelId: state.selectedModelId);
      state = state.copyWith(
        messages: [...msgsWithUser, assistantMsg],
        streamingMessageId: assistantMsg.id);

      final buf = StringBuffer();
      final thinkBuf = StringBuffer();
      final start = DateTime.now();

      _sub = _repo.streamResponse(
        providerId: state.selectedProviderId, modelId: state.selectedModelId,
        messages: msgsWithUser, systemPrompt: state.systemPrompt ?? conv.systemPrompt,
        temperature: state.temperature, maxTokens: state.maxTokens,
      ).listen((chunk) {
        if (!mounted) return;
        if (chunk.startsWith('\x00THINKING\x00')) {
          final end = chunk.indexOf('\x00/THINKING\x00');
          if (end != -1) {
            thinkBuf.write(chunk.substring('\x00THINKING\x00'.length, end));
            // Thinking is always surfaced live — it's a distinct signal
            // from the answer body and isn't what the setting controls.
            state = state.copyWith(isThinking: true, thinkingContent: thinkBuf.toString());
            return;
          }
        }
        if (state.isThinking) state = state.copyWith(isThinking: false);
        buf.write(chunk);
        // When streaming is disabled, the response is still fetched via
        // the same streaming API call underneath (providers don't offer a
        // separate non-streaming endpoint here), but the UI only reveals
        // the full answer once at the end instead of token-by-token.
        if (streamingEnabled) {
          final updated = state.messages.map((m) =>
            m.id == assistantMsg.id ? m.copyWith(content: buf.toString()) : m).toList();
          state = state.copyWith(messages: updated);
        }
      }, onDone: () async {
        if (!mounted) return;
        final ms = DateTime.now().difference(start).inMilliseconds;
        final usage = _repo.recordMessageUsage(
          providerId: state.selectedProviderId,
          modelId: state.selectedModelId,
          promptMessages: msgsWithUser,
          responseContent: buf.toString(),
          durationMs: ms,
        );
        final finalMsg = assistantMsg.copyWith(
          content: buf.toString(), isStreaming: false,
          thinking: thinkBuf.isNotEmpty ? thinkBuf.toString() : null, durationMs: ms,
          inputTokens: usage.inputTokens, outputTokens: usage.outputTokens, cost: usage.cost);
        await _repo.updateMessage(finalMsg);
        await _repo.autoTitle(conv.id, content.trim());
        final finalMsgs = state.messages.map((m) => m.id == finalMsg.id ? finalMsg : m).toList();
        state = state.copyWith(messages: finalMsgs, status: ChatStatus.idle,
          streamingMessageId: null, isThinking: false, thinkingContent: null,
          conversation: _repo.getConversation(conv.id) ?? conv);
        _ref.read(conversationListProvider.notifier).refresh();
      }, onError: (e) async {
        if (!mounted) return;
        final errMsg = assistantMsg.copyWith(content: buf.toString(),
          isStreaming: false, hasError: true, errorMessage: e.toString());
        await _repo.updateMessage(errMsg);
        final errMsgs = state.messages.map((m) => m.id == errMsg.id ? errMsg : m).toList();
        state = state.copyWith(messages: errMsgs, status: ChatStatus.error,
          error: e.toString(), streamingMessageId: null, isThinking: false);
      }, cancelOnError: true);
    } catch (e) {
      state = state.copyWith(status: ChatStatus.error, error: e.toString());
    }
  }

  Future<void> stopStreaming() async {
    await _sub?.cancel(); _sub = null;
    if (state.streamingMessageId != null) {
      final msgs = state.messages.map((m) =>
        m.id == state.streamingMessageId ? m.copyWith(isStreaming: false) : m).toList();
      state = state.copyWith(messages: msgs, status: ChatStatus.idle,
        streamingMessageId: null, isThinking: false);
    }
  }

  Future<void> deleteMessage(String id) async {
    await _repo.deleteMessage(id);
    state = state.copyWith(messages: state.messages.where((m) => m.id != id).toList());
  }

  Future<void> clearConversation() async {
    if (state.conversation == null) return;
    await _repo.clearMessages(state.conversation!.id);
    state = state.copyWith(messages: []);
  }

  Future<void> regenerateLastResponse() async {
    final lastAssist = state.messages.lastWhere(
      (m) => m.role == MessageRole.assistant, orElse: () => state.messages.last);
    if (lastAssist.role != MessageRole.assistant) return;
    await _repo.deleteMessage(lastAssist.id);
    final withoutLast = state.messages.where((m) => m.id != lastAssist.id).toList();
    state = state.copyWith(messages: withoutLast);
    final lastUser = withoutLast.lastWhere(
      (m) => m.role == MessageRole.user, orElse: () => withoutLast.last);
    if (lastUser.role == MessageRole.user) {
      await sendMessage(content: lastUser.content, attachments: lastUser.attachments);
    }
  }
}

final chatProvider = StateNotifierProvider.autoDispose.family<ChatNotifier, ChatState, Map<String,String>>(
  (ref, params) {
    final settings = ref.read(settingsProvider);
    return ChatNotifier(ref.read(chatRepositoryProvider), ref,
      params['provider'] ?? settings.defaultProvider,
      params['model'] ?? settings.defaultModel);
  });
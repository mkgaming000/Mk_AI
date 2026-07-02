import '../../../core/storage/database/hive_boxes.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';

class ConversationLocalDatasource {
  Future<void> saveConversation(ConversationModel c) async =>
      HiveBoxes.conversations.put(c.id, c);

  Future<void> deleteConversation(String id) async {
    await HiveBoxes.conversations.delete(id);
    final keys = HiveBoxes.messages.keys
        .where((k) => HiveBoxes.messages.get(k)?.conversationId == id)
        .toList();
    await HiveBoxes.messages.deleteAll(keys);
  }

  ConversationModel? getConversation(String id) =>
      HiveBoxes.conversations.get(id);

  List<ConversationModel> getAllConversations() =>
      HiveBoxes.conversations.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<ConversationModel> searchConversations(String query) {
    final q = query.toLowerCase();
    return HiveBoxes.conversations.values
        .where((c) => c.title.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<ConversationModel> getRecentConversations([int limit = 10]) =>
      getAllConversations().take(limit).toList();

  Future<void> pinConversation(String id, bool pinned) async {
    final c = HiveBoxes.conversations.get(id);
    if (c != null) {
      c.isPinned = pinned;
      await HiveBoxes.conversations.put(id, c);
    }
  }

  Future<void> updateTitle(String id, String title) async {
    final c = HiveBoxes.conversations.get(id);
    if (c != null) {
      c.title = title;
      c.updatedAt = DateTime.now();
      await HiveBoxes.conversations.put(id, c);
    }
  }

  Future<void> saveMessage(MessageModel m) async {
    await HiveBoxes.messages.put(m.id, m);
    _recomputeConversationAggregates(m.conversationId);
  }

  Future<void> updateMessage(MessageModel m) async {
    await HiveBoxes.messages.put(m.id, m);
    _recomputeConversationAggregates(m.conversationId);
  }

  void _recomputeConversationAggregates(String conversationId) {
    final c = HiveBoxes.conversations.get(conversationId);
    if (c == null) return;
    final msgs = getMessages(conversationId);
    c.messageCount = msgs.length;
    c.totalTokens = msgs.fold<int>(
        0, (sum, m) => sum + (m.inputTokens ?? 0) + (m.outputTokens ?? 0));
    c.totalCost = msgs.fold<double>(0.0, (sum, m) => sum + (m.cost ?? 0.0));
    c.updatedAt = DateTime.now();
    HiveBoxes.conversations.put(conversationId, c);
  }

  Future<void> deleteMessage(String id) async =>
      HiveBoxes.messages.delete(id);

  List<MessageModel> getMessages(String conversationId) =>
      HiveBoxes.messages.values
          .where((m) => m.conversationId == conversationId)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Future<void> clearMessages(String conversationId) async {
    final keys = HiveBoxes.messages.keys
        .where((k) =>
            HiveBoxes.messages.get(k)?.conversationId == conversationId)
        .toList();
    await HiveBoxes.messages.deleteAll(keys);
    final c = HiveBoxes.conversations.get(conversationId);
    if (c != null) {
      c.messageCount = 0;
      c.totalTokens = 0;
      c.totalCost = 0;
      c.updatedAt = DateTime.now();
      await HiveBoxes.conversations.put(conversationId, c);
    }
  }
}

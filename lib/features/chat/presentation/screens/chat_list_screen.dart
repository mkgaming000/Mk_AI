import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../data/models/conversation_model.dart';
import '../../../../shared/widgets/omni_app_bar.dart';
import '../../providers/chat_provider.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});
  @override ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground1 : null,
      appBar: OmniAppBar(
        showLogo: !_searching,
        titleWidget: _searching ? _SearchBar(controller: _searchCtrl,
          onChanged: (q) => ref.read(conversationListProvider.notifier).search(q),
          onClear: () => ref.read(conversationListProvider.notifier).search('')) : null,
        actions: [
          if (!_searching) IconButton(icon: const Icon(Icons.search_rounded), onPressed: () => setState(() => _searching = true)),
          if (_searching) TextButton(onPressed: () { setState(() => _searching = false); _searchCtrl.clear(); ref.read(conversationListProvider.notifier).search(''); }, child: const Text('Cancel')),
          IconButton(icon: const Icon(Icons.edit_square_rounded), onPressed: () => context.push(RouteNames.newChat), tooltip: 'New chat'),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: \$e')),
        data: (conversations) {
          if (conversations.isEmpty) return _Empty(onNew: () => context.push(RouteNames.newChat));
          final pinned = conversations.where((c) => c.isPinned).toList();
          final unpinned = conversations.where((c) => !c.isPinned).toList();
          return RefreshIndicator(
            onRefresh: () async => ref.read(conversationListProvider.notifier).refresh(),
            child: CustomScrollView(slivers: [
              if (pinned.isNotEmpty) ...[
                const SliverToBoxAdapter(child: _SectionLabel('📌 Pinned')),
                SliverList.builder(itemCount: pinned.length, itemBuilder: (_, i) => _Tile(conversation: pinned[i], index: i)),
              ],
              SliverToBoxAdapter(child: pinned.isNotEmpty ? const _SectionLabel('Recent') : const SizedBox.shrink()),
              SliverList.builder(itemCount: unpinned.length, itemBuilder: (_, i) => _Tile(conversation: unpinned[i], index: i)),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ]),
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchBar({required this.controller, required this.onChanged, required this.onClear});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).colorScheme.outline)),
      child: TextField(controller: controller, autofocus: true, onChanged: onChanged,
        decoration: InputDecoration(hintText: 'Search...', prefixIcon: const Icon(Icons.search_rounded, size: 18), border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIcon: controller.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded, size: 16), onPressed: onClear) : null)),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
    child: Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.darkPrimary, letterSpacing: 0.8, fontWeight: FontWeight.w700)),
  );
}

class _Tile extends ConsumerWidget {
  final ConversationModel conversation;
  final int index;
  const _Tile({required this.conversation, required this.index});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Slidable(
      key: ValueKey(conversation.id),
      endActionPane: ActionPane(motion: const DrawerMotion(), children: [
        SlidableAction(onPressed: (_) => ref.read(conversationListProvider.notifier).pinConversation(conversation.id, !conversation.isPinned),
          backgroundColor: AppColors.darkAccentOrange, foregroundColor: Colors.white,
          icon: conversation.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
          label: conversation.isPinned ? 'Unpin' : 'Pin'),
        SlidableAction(onPressed: (_) => _delete(context, ref),
          backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Colors.white,
          icon: Icons.delete_rounded, label: 'Delete'),
      ]),
      child: GestureDetector(
        onTap: () => context.push('/chat/\${conversation.id}'),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.darkBorderFaint : AppColors.lightBorder),
          ),
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: conversation.providerId.toProviderColor().withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(conversation.providerId.providerEmoji(), style: const TextStyle(fontSize: 20)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(conversation.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall)),
                if (conversation.isPinned) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.push_pin_rounded, size: 12, color: AppColors.darkAccentOrange)),
                const SizedBox(width: 6),
                Text(conversation.updatedAt.timeAgo, style: Theme.of(context).textTheme.bodySmall),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: conversation.providerId.toProviderColor().withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(conversation.modelId, style: TextStyle(fontSize: 10, color: conversation.providerId.toProviderColor()))),
                const SizedBox(width: 6),
                Text('\${conversation.messageCount} msgs', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ])),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.darkOnSurfaceVariant),
          ]),
        ),
      ).animate(delay: Duration(milliseconds: index * 25)).fadeIn(duration: 250.ms),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Conversation'),
      content: Text('Delete "\${conversation.title}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error), child: const Text('Delete')),
      ],
    ));
    if (ok == true) ref.read(conversationListProvider.notifier).deleteConversation(conversation.id);
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onNew;
  const _Empty({required this.onNew});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 88, height: 88, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(22)), child: const Center(child: Text('💬', style: TextStyle(fontSize: 44))))
        .animate().fadeIn().scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
    const SizedBox(height: 20),
    Text('Start a conversation', style: Theme.of(context).textTheme.headlineSmall).animate().fadeIn(delay: 150.ms),
    const SizedBox(height: 8),
    Text('Chat with GPT-4o, Claude, Gemini, Grok, DeepSeek
and 8+ more AI models.',
      textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))
        .animate().fadeIn(delay: 250.ms),
    const SizedBox(height: 28),
    FilledButton.icon(onPressed: onNew, icon: const Icon(Icons.add_rounded), label: const Text('New Chat'),
      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)))
        .animate().fadeIn(delay: 350.ms).scale(delay: 350.ms, begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
  ]));
}
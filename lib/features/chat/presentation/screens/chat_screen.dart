import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/omni_app_bar.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../providers/chat_provider.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_settings_sheet.dart';
import '../widgets/message_bubble.dart';
import '../widgets/model_selector_chip.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? conversationId;
  const ChatScreen({super.key, this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollCtrl = ScrollController();
  late Map<String, String> _providerParams;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _providerParams = {
      'provider': settings.defaultProvider,
      'model': settings.defaultModel,
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.conversationId != null) {
        ref.read(chatProvider(_providerParams).notifier)
            .loadConversation(widget.conversationId!);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(_providerParams));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(chatProvider(_providerParams), (prev, next) {
      if (next.messages.length != prev?.messages.length ||
          next.isStreaming) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground1 : null,
      appBar: OmniAppBar(
        title: chatState.conversation?.title ?? 'New Chat',
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows_rounded, size: 20),
            onPressed: () => context.push(RouteNames.chatCompare),
            tooltip: 'Compare models',
          ),
          if (chatState.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, size: 20),
              onPressed: () => _confirmClear(context),
              tooltip: 'Clear',
            ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 20),
            onPressed: () => _showSettings(context),
            tooltip: 'Settings',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: ModelSelectorChip(
              selectedProvider: chatState.selectedProviderId,
              selectedModel: chatState.selectedModelId,
              onChanged: (provider, model) {
                setState(() {
                  _providerParams = {'provider': provider, 'model': model};
                });
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty
                ? _WelcomeView(onSuggestion: (s) => ref
                    .read(chatProvider(_providerParams).notifier)
                    .sendMessage(content: s))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: chatState.messages.length,
                    itemBuilder: (ctx, i) => MessageBubble(
                      message: chatState.messages[i],
                      isLast: i == chatState.messages.length - 1,
                      onDelete: () => ref
                          .read(chatProvider(_providerParams).notifier)
                          .deleteMessage(chatState.messages[i].id),
                      onRegenerate: i == chatState.messages.length - 1 &&
                              chatState.messages[i].isAssistant
                          ? () => ref
                              .read(chatProvider(_providerParams).notifier)
                              .regenerateLastResponse()
                          : null,
                    ),
                  ),
          ),
          ChatInputBar(
            isStreaming: chatState.isStreaming,
            onSend: (content, attachments) => ref
                .read(chatProvider(_providerParams).notifier)
                .sendMessage(content: content, attachments: attachments),
            onStop: () => ref
                .read(chatProvider(_providerParams).notifier)
                .stopStreaming(),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Delete all messages in this conversation?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(chatProvider(_providerParams).notifier).clearConversation();
    }
  }

  void _showSettings(BuildContext context) {
    final chatState = ref.read(chatProvider(_providerParams));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChatSettingsSheet(
        temperature: chatState.temperature,
        maxTokens: chatState.maxTokens,
        systemPrompt: chatState.systemPrompt,
        onApply: ({required temperature, required maxTokens, required systemPrompt}) {
          final notifier = ref.read(chatProvider(_providerParams).notifier);
          notifier.setTemperature(temperature);
          notifier.setMaxTokens(maxTokens);
          notifier.setSystemPrompt(systemPrompt);
        },
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  final void Function(String) onSuggestion;
  const _WelcomeView({required this.onSuggestion});

  static const _suggestions = [
    'Explain quantum computing simply',
    'Write a Python web scraper',
    'Review my code for bugs',
    'Help me plan a startup idea',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(child: Text('⚡', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 18),
            Text('OmniForge AI',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text('Ask me anything.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 28),
            ...(_suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => onSuggestion(s),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline),
                      ),
                      child: Row(children: [
                        Expanded(child: Text(s)),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14,
                            color: AppColors.darkOnSurfaceVariant),
                      ]),
                    ),
                  ),
                ))),
          ],
        ),
      ),
    );
  }
}

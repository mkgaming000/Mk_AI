import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isLast;
  final VoidCallback? onDelete;
  final VoidCallback? onRegenerate;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isLast,
    this.onDelete,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    switch (message.role) {
      case MessageRole.user:
        return _UserBubble(message: message, onDelete: onDelete);
      case MessageRole.assistant:
        return _AssistantBubble(
          message: message,
          isLast: isLast,
          onDelete: onDelete,
          onRegenerate: onRegenerate,
        );
      case MessageRole.system:
      case MessageRole.tool:
        return _SystemBubble(message: message);
    }
  }
}

// ── User Bubble ──────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final MessageModel message;
  final VoidCallback? onDelete;
  const _UserBubble({required this.message, this.onDelete});

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(ctx);
              },
            ),
            if (onDelete != null)
              ListTile(
                leading: Icon(Icons.delete_outline_rounded,
                    color: Theme.of(ctx).colorScheme.error),
                title: Text('Delete',
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                onTap: () {
                  onDelete!();
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 4, 12, 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onLongPress: () => _showMenu(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.attachments != null &&
                    message.attachments!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Wrap(
                      spacing: 6,
                      children: message.attachments!.map((a) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.attach_file_rounded,
                                  size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(a['name'] ?? 'file',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                if (message.content.isNotEmpty)
                  Text(
                    message.content,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15, height: 1.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Assistant Bubble ─────────────────────────────────────────────────────

class _AssistantBubble extends StatelessWidget {
  final MessageModel message;
  final bool isLast;
  final VoidCallback? onDelete;
  final VoidCallback? onRegenerate;

  const _AssistantBubble({
    required this.message,
    required this.isLast,
    this.onDelete,
    this.onRegenerate,
  });

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(ctx);
              },
            ),
            if (onRegenerate != null)
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: const Text('Regenerate'),
                onTap: () {
                  onRegenerate!();
                  Navigator.pop(ctx);
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: Icon(Icons.delete_outline_rounded,
                    color: Theme.of(ctx).colorScheme.error),
                title: Text('Delete',
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                onTap: () {
                  onDelete!();
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    if (message.hasError) {
      return Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.errorMessage ?? 'Something went wrong',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 14),
            ),
          ),
        ],
      );
    }

    if (message.content.isEmpty && message.isStreaming) {
      return const _CursorBlink();
    }

    return MarkdownBody(
      data: message.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
        code: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 13,
          backgroundColor: isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.lightSurfaceContainer,
        ),
        codeblockPadding: const EdgeInsets.all(12),
        codeblockDecoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.lightSurfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 48, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.thinking != null && message.thinking!.isNotEmpty)
            _ThinkingBlock(thinking: message.thinking!),
          GestureDetector(
            onLongPress: () => _showMenu(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorderFaint
                      : AppColors.lightBorder,
                ),
              ),
              child: _buildContent(context, isDark),
            ),
          ),
          if (message.isStreaming)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: _CursorBlink(),
            ),
          if (!message.isStreaming &&
              message.content.isNotEmpty &&
              isLast)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  _Action(
                    icon: Icons.copy_rounded,
                    onTap: () => Clipboard.setData(
                        ClipboardData(text: message.content)),
                  ),
                  if (onRegenerate != null)
                    _Action(icon: Icons.refresh_rounded, onTap: onRegenerate!),
                  if (onDelete != null)
                    _Action(icon: Icons.delete_outline_rounded, onTap: onDelete!),
                  const Spacer(),
                  if (message.durationMs != null)
                    Text(
                      '${(message.durationMs! / 1000).toStringAsFixed(1)}s',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Thinking Block ───────────────────────────────────────────────────────

class _ThinkingBlock extends StatefulWidget {
  final String thinking;
  const _ThinkingBlock({required this.thinking});

  @override
  State<_ThinkingBlock> createState() => _ThinkingBlockState();
}

class _ThinkingBlockState extends State<_ThinkingBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.darkPrimary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.darkPrimary.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_rounded,
                    size: 14, color: AppColors.darkPrimary),
                const SizedBox(width: 6),
                const Text(
                  'Thinking',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkPrimary,
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 14,
                  color: AppColors.darkPrimary,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 6),
              Text(
                widget.thinking,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.darkOnSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── System / Tool Bubble ─────────────────────────────────────────────────

class _SystemBubble extends StatelessWidget {
  final MessageModel message;
  const _SystemBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.content,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
        ),
      ),
    );
  }
}

// ── Cursor Blink ──────────────────────────────────────────────────────────

class _CursorBlink extends StatefulWidget {
  const _CursorBlink();

  @override
  State<_CursorBlink> createState() => _CursorBlinkState();
}

class _CursorBlinkState extends State<_CursorBlink>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 2,
        height: 16,
        color: AppColors.darkPrimary.withOpacity(_ctrl.value),
      ),
    );
  }
}

// ── Action Icon Button ───────────────────────────────────────────────────

class _Action extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Icon(icon, size: 16, color: AppColors.darkOnSurfaceVariant),
      ),
    );
  }
}

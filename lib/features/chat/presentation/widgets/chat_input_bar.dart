import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';

class ChatInputBar extends StatefulWidget {
  final bool isStreaming;
  final void Function(String content, List<Map<String, dynamic>>? attachments) onSend;
  final VoidCallback onStop;

  const ChatInputBar({
    super.key,
    required this.isStreaming,
    required this.onSend,
    required this.onStop,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  final List<_Attachment> _attachments = [];
  bool _showAttachMenu = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage({ImageSource source = ImageSource.gallery}) async {
    setState(() => _showAttachMenu = false);
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source, imageQuality: 85);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      setState(() {
        _attachments.add(_Attachment(
          name: image.name,
          type: 'image',
          bytes: bytes,
          mimeType: 'image/jpeg',
        ));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    setState(() => _showAttachMenu = false);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md', 'csv', 'json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes != null) {
        setState(() {
          _attachments.add(_Attachment(
            name: file.name,
            type: 'file',
            bytes: file.bytes!,
            mimeType: 'text/plain',
          ));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  void _removeAttachment(int index) =>
      setState(() => _attachments.removeAt(index));

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;

    final attachmentData = _attachments.map((a) {
      if (a.type == 'image') {
        return {
          'type': 'image',
          'data': base64Encode(a.bytes),
          'mediaType': a.mimeType,
          'name': a.name,
        };
      }
      return {
        'type': 'file',
        'content': String.fromCharCodes(a.bytes),
        'name': a.name,
      };
    }).toList();

    widget.onSend(text, attachmentData.isEmpty ? null : attachmentData);
    _textController.clear();
    setState(() {
      _hasText = false;
      _attachments.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorderFaint : AppColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Attachment previews
            if (_attachments.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  itemCount: _attachments.length,
                  itemBuilder: (ctx, i) => _AttachmentPreview(
                    attachment: _attachments[i],
                    onRemove: () => _removeAttachment(i),
                  ),
                ),
              ),

            // Attach menu
            if (_showAttachMenu)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _AttachOption(
                      icon: Icons.image_rounded,
                      label: 'Image',
                      color: AppColors.darkPrimary,
                      onTap: () => _pickImage(),
                    ),
                    const SizedBox(width: 12),
                    _AttachOption(
                      icon: Icons.description_rounded,
                      label: 'File',
                      color: AppColors.darkSecondary,
                      onTap: _pickFile,
                    ),
                    const SizedBox(width: 12),
                    _AttachOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: AppColors.darkTertiary,
                      onTap: () =>
                          _pickImage(source: ImageSource.camera),
                    ),
                  ],
                ),
              ),

            // Input row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attach button
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showAttachMenu = !_showAttachMenu),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10, right: 4),
                      child: AnimatedRotation(
                        turns: _showAttachMenu ? 0.125 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.add_circle_outline_rounded,
                          color: _showAttachMenu
                              ? AppColors.darkPrimary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                          size: 26,
                        ),
                      ),
                    ),
                  ),

                  // Text field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 160),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _focusNode.hasFocus
                              ? AppColors.darkPrimary.withOpacity(0.5)
                              : (isDark
                                  ? AppColors.darkBorderFaint
                                  : AppColors.lightBorder),
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: widget.isStreaming
                              ? 'AI is responding...'
                              : 'Ask anything...',
                          hintStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.6),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) {
                          if (!widget.isStreaming) _send();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send / Stop button
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: widget.isStreaming
                        ? _StopButton(
                            key: const ValueKey('stop'),
                            onTap: widget.onStop,
                          )
                        : _SendButton(
                            key: const ValueKey('send'),
                            enabled:
                                _hasText || _attachments.isNotEmpty,
                            onTap: _send,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _SendButton({super.key, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.primaryGradient : null,
          color: enabled ? null : AppColors.darkSurfaceVariant,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.darkPrimary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Icon(
          Icons.arrow_upward_rounded,
          color: enabled ? Colors.white : AppColors.darkOnSurfaceVariant,
          size: 22,
        ),
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StopButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withOpacity(0.3),
          ),
        ),
        child: Icon(
          Icons.stop_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 22,
        ),
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AttachOption(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _Attachment {
  final String name;
  final String type;
  final Uint8List bytes;
  final String mimeType;
  _Attachment(
      {required this.name,
      required this.type,
      required this.bytes,
      required this.mimeType});
}

class _AttachmentPreview extends StatelessWidget {
  final _Attachment attachment;
  final VoidCallback onRemove;
  const _AttachmentPreview(
      {required this.attachment, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 64,
      height: 64,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Stack(
        children: [
          if (attachment.type == 'image')
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(attachment.bytes,
                  fit: BoxFit.cover, width: 64, height: 64),
            )
          else
            const Center(
                child: Icon(Icons.description_rounded, size: 32)),
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

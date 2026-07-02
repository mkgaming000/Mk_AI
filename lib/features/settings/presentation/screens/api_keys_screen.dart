import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/provider_constants.dart';
import '../../../../shared/widgets/omni_app_bar.dart';
import '../../providers/settings_provider.dart';

class ApiKeysScreen extends ConsumerWidget {
  const ApiKeysScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final apiKeys = ref.watch(apiKeysProvider);
    final allProviders = [...ProviderConstants.chatProviders, ...ProviderConstants.imageProviders, ...ProviderConstants.voiceProviders].toSet().toList();
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground1 : null,
      appBar: const OmniAppBar(title: 'API Keys'),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.darkPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkPrimary.withOpacity(0.2))),
          child: Row(children: [const Icon(Icons.shield_rounded, color: AppColors.darkPrimary, size: 18), const SizedBox(width: 8),
            Expanded(child: Text('Keys are encrypted with AES-256 and stored only on this device.', style: Theme.of(context).textTheme.bodySmall))])),
        ...allProviders.asMap().entries.map((e) {
          final provider = e.value;
          final pId = provider.name;
          final existing = apiKeys.where((k) => k.providerId == pId).firstOrNull;
          return _KeyTile(provider: provider, isConnected: existing != null, maskedKey: existing?.maskedKey, index: e.key,
            onTap: () => _showDialog(context, ref, pId, existing != null),
            onDelete: existing != null ? () => ref.read(apiKeysProvider.notifier).deleteKey(pId) : null);
        }),
      ]),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref, String providerId, bool isUpdate) {
    final ctrl = TextEditingController();
    bool obscure = true;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => AlertDialog(
      title: Text(isUpdate ? 'Update API Key' : 'Add API Key'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Enter your \${ProviderConstants.providerNames[ProviderConstants.chatProviders.where((p) => p.name == providerId).firstOrNull] ?? providerId} API key',
          style: Theme.of(ctx).textTheme.bodySmall),
        const SizedBox(height: 12),
        TextField(controller: ctrl, obscureText: obscure, autofocus: true,
          decoration: InputDecoration(hintText: 'sk-...',
            suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18), onPressed: () => ss(() => obscure = !obscure)))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          final key = ctrl.text.trim();
          if (key.isEmpty) return;
          await ref.read(apiKeysProvider.notifier).saveKey(providerId: providerId, apiKey: key);
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Save')),
      ],
    )));
  }
}

class _KeyTile extends StatelessWidget {
  final AiProvider provider; final bool isConnected; final String? maskedKey;
  final int index; final VoidCallback onTap; final VoidCallback? onDelete;
  const _KeyTile({required this.provider, required this.isConnected, this.maskedKey, required this.index, required this.onTap, this.onDelete});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isConnected ? AppColors.darkAccentGreen.withOpacity(0.3) : (isDark ? AppColors.darkBorderFaint : AppColors.lightBorder))),
      child: ListTile(onTap: onTap,
        leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: ProviderConstants.colorForProvider(provider).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(ProviderConstants.emojiForProvider(provider), style: const TextStyle(fontSize: 18)))),
        title: Text(ProviderConstants.providerNames[provider] ?? provider.name),
        subtitle: Text(isConnected ? (maskedKey ?? 'Connected') : 'Not connected',
          style: TextStyle(color: isConnected ? AppColors.darkAccentGreen : null, fontFamily: isConnected ? 'JetBrainsMono' : null, fontSize: 12)),
        trailing: isConnected ? Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.darkAccentGreen, size: 18),
          if (onDelete != null) IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18), onPressed: onDelete),
        ]) : const Icon(Icons.add_circle_outline_rounded, size: 20))
    ).animate(delay: Duration(milliseconds: index * 20)).fadeIn(duration: 200.ms);
  }
}
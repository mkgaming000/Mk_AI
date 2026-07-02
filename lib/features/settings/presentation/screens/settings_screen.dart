import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/omni_app_bar.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final configured = ref.watch(configuredProvidersProvider);
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground1 : null,
      appBar: const OmniAppBar(title: 'Settings'),
      body: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
        _SectionLabel('AI Providers'),
        _Tile(icon: Icons.vpn_key_rounded, color: AppColors.darkPrimary, title: 'API Keys',
          subtitle: '\${configured.length} provider\${configured.length == 1 ? "" : "s"} connected',
          onTap: () => context.push(RouteNames.apiKeys)),
        _Tile(icon: Icons.hub_rounded, color: AppColors.darkSecondary, title: 'MCP Servers',
          subtitle: 'Tool integrations', onTap: () => context.push(RouteNames.mcpServers)),
        _Tile(icon: Icons.computer_rounded, color: AppColors.ollamaColor, title: 'Local Models (Ollama)',
          subtitle: 'Run AI on your computer', onTap: () => context.push(RouteNames.localModels)),
        _Tile(icon: Icons.bar_chart_rounded, color: AppColors.darkAccentGreen, title: 'Usage & Costs',
          subtitle: 'Track spending', onTap: () => context.push(RouteNames.usageStats)),
        const SizedBox(height: 12),
        _SectionLabel('Appearance'),
        _Tile(icon: Icons.palette_rounded, color: AppColors.darkTertiary, title: 'Theme & Display',
          subtitle: 'Dark mode, fonts, code themes', onTap: () => context.push(RouteNames.appearance)),
        const SizedBox(height: 12),
        _SectionLabel('Chat'),
        _Switch(icon: Icons.bolt_rounded, color: AppColors.darkAccentYellow, title: 'Streaming Responses',
          subtitle: 'Show AI responses as they generate', value: settings.streamingEnabled,
          onChanged: (v) => ref.read(settingsProvider.notifier).setStreamingEnabled(v)),
        const SizedBox(height: 12),
        _SectionLabel('Privacy & Security'),
        _Switch(icon: Icons.fingerprint_rounded, color: AppColors.darkPrimary, title: 'Biometric Lock',
          subtitle: 'Require fingerprint / Face ID to open', value: settings.biometricEnabled,
          onChanged: (v) => ref.read(settingsProvider.notifier).setBiometricEnabled(v)),
        _Switch(icon: Icons.analytics_rounded, color: AppColors.darkSecondary, title: 'Anonymous Analytics',
          subtitle: 'Help improve OmniForge AI', value: settings.analyticsEnabled,
          onChanged: (v) => ref.read(settingsProvider.notifier).setAnalyticsEnabled(v)),
        const SizedBox(height: 12),
        _SectionLabel('About'),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (_, snap) => ListTile(
            leading: Container(width: 38, height: 38, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)), child: const Center(child: Text('⚡', style: TextStyle(fontSize: 16)))),
            title: const Text('OmniForge AI'),
            subtitle: Text('Version \${snap.data?.version ?? "1.0.0"}'),
          )),
        const SizedBox(height: 32),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);
  @override build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
    child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.darkPrimary, letterSpacing: 1.0, fontWeight: FontWeight.w700)));
}

class _Tile extends StatelessWidget {
  final IconData icon; final Color color; final String title;
  final String? subtitle; final VoidCallback onTap;
  const _Tile({required this.icon, required this.color, required this.title, this.subtitle, required this.onTap});
  @override build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
    title: Text(title), subtitle: subtitle != null ? Text(subtitle!) : null,
    trailing: const Icon(Icons.chevron_right_rounded, size: 20));
}

class _Switch extends StatelessWidget {
  final IconData icon; final Color color; final String title;
  final String subtitle; final bool value; final ValueChanged<bool> onChanged;
  const _Switch({required this.icon, required this.color, required this.title, required this.subtitle, required this.value, required this.onChanged});
  @override build(BuildContext context) => ListTile(
    leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
    title: Text(title), subtitle: Text(subtitle),
    trailing: Switch(value: value, onChanged: onChanged));
}
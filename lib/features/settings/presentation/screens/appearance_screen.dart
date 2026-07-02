import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/omni_app_bar.dart';
import '../../providers/settings_provider.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});
  static const _themes = ['github-dark','monokai','dracula','nord','one-dark','github','solarized-light'];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: const OmniAppBar(title: 'Theme & Display'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Theme Mode', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 10),
        Row(children: [
          _ThemeOption(label: 'Dark', icon: Icons.dark_mode_rounded, isSelected: themeMode == ThemeMode.dark,
            onTap: () { ref.read(themeModeProvider.notifier).state = ThemeMode.dark; ref.read(localStorageProvider).setThemeMode('dark'); }),
          const SizedBox(width: 10),
          _ThemeOption(label: 'Light', icon: Icons.light_mode_rounded, isSelected: themeMode == ThemeMode.light,
            onTap: () { ref.read(themeModeProvider.notifier).state = ThemeMode.light; ref.read(localStorageProvider).setThemeMode('light'); }),
          const SizedBox(width: 10),
          _ThemeOption(label: 'System', icon: Icons.brightness_auto_rounded, isSelected: themeMode == ThemeMode.system,
            onTap: () { ref.read(themeModeProvider.notifier).state = ThemeMode.system; ref.read(localStorageProvider).setThemeMode('system'); }),
        ]),
        const SizedBox(height: 24),
        Text('Message Font Size', style: Theme.of(context).textTheme.labelLarge),
        Row(children: [
          Text('Aa', style: TextStyle(fontSize: settings.messageFontSize)),
          Expanded(child: Slider(value: settings.messageFontSize, min: 12, max: 20, divisions: 8,
            label: settings.messageFontSize.toStringAsFixed(0),
            onChanged: (v) => ref.read(settingsProvider.notifier).setMessageFontSize(v))),
        ]),
        const SizedBox(height: 12),
        Text('Terminal Font Size', style: Theme.of(context).textTheme.labelLarge),
        Row(children: [
          Text('Aa', style: TextStyle(fontSize: settings.terminalFontSize, fontFamily: 'JetBrainsMono')),
          Expanded(child: Slider(value: settings.terminalFontSize, min: 10, max: 18, divisions: 8,
            label: settings.terminalFontSize.toStringAsFixed(0),
            onChanged: (v) => ref.read(settingsProvider.notifier).setTerminalFontSize(v))),
        ]),
        const SizedBox(height: 24),
        Text('Code Theme', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: _themes.map((t) {
          final sel = settings.codeTheme == t;
          return GestureDetector(
            onTap: () => ref.read(settingsProvider.notifier).setCodeTheme(t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppColors.darkPrimary.withOpacity(0.15) : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? AppColors.darkPrimary.withOpacity(0.4) : Theme.of(context).colorScheme.outline)),
              child: Text(t, style: TextStyle(fontSize: 12, fontFamily: 'JetBrainsMono', fontWeight: FontWeight.w500, color: sel ? AppColors.darkPrimary : null))));
        }).toList()),
      ]),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label; final IconData icon; final bool isSelected; final VoidCallback onTap;
  const _ThemeOption({required this.label, required this.icon, required this.isSelected, required this.onTap});
  @override build(BuildContext context) => Expanded(child: GestureDetector(onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(color: isSelected ? AppColors.darkPrimary.withOpacity(0.12) : Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: isSelected ? AppColors.darkPrimary.withOpacity(0.5) : Theme.of(context).colorScheme.outline, width: isSelected ? 1.5 : 1)),
    child: Column(children: [Icon(icon, color: isSelected ? AppColors.darkPrimary : null, size: 22), const SizedBox(height: 5),
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? AppColors.darkPrimary : null))]))));
}
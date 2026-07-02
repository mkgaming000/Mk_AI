import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/omni_app_bar.dart';
import '../../../../shared/widgets/gradient_button.dart';

class VideoGenScreen extends ConsumerStatefulWidget {
  const VideoGenScreen({super.key});
  @override ConsumerState<VideoGenScreen> createState() => _VideoGenScreenState();
}

class _VideoGenScreenState extends ConsumerState<VideoGenScreen> {
  final _promptCtrl = TextEditingController();
  String _provider = 'runway', _duration = '4s', _ratio = '16:9';
  bool _loading = false;
  static const _providers = [
    {'id': 'runway', 'name': 'Runway Gen-3', 'icon': '🎬'},
    {'id': 'pika', 'name': 'Pika 1.5', 'icon': '⚡'},
    {'id': 'luma', 'name': 'Luma Dream', 'icon': '💫'},
    {'id': 'kling', 'name': 'Kling AI', 'icon': '🎞️'},
  ];
  static const _durations = ['4s', '8s', '16s'];
  static const _ratios = ['16:9', '9:16', '1:1'];
  @override void dispose() { _promptCtrl.dispose(); super.dispose(); }

  @override build(BuildContext context) {
    return Scaffold(
      appBar: const OmniAppBar(title: 'Video Studio'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: _providers.map((p) {
          final sel = _provider == p['id'];
          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _provider = p['id']!),
            child: Container(margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: sel ? AppColors.darkPrimary.withOpacity(0.15) : Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? AppColors.darkPrimary.withOpacity(0.4) : Colors.transparent)),
              child: Column(children: [Text(p['icon']!, style: const TextStyle(fontSize: 20)), const SizedBox(height: 2), Text(p['name']!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sel ? AppColors.darkPrimary : null), textAlign: TextAlign.center)]))));
        }).toList()),
        const SizedBox(height: 16),
        Container(height: 180, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.darkPrimary.withOpacity(0.15), AppColors.darkSecondary.withOpacity(0.08)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.darkPrimary.withOpacity(0.2))),
          child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.play_circle_outline_rounded, size: 48, color: Colors.white24),
            SizedBox(height: 8), Text('Generated video will appear here', style: TextStyle(color: Colors.white38, fontSize: 13)),
          ]))),
        const SizedBox(height: 16),
        TextField(controller: _promptCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Video Prompt', hintText: 'A cinematic shot of a spaceship entering warp speed...')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Duration', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            Row(children: _durations.map((d) { final sel = _duration == d; return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(onTap: () => setState(() => _duration = d),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: sel ? AppColors.darkSecondary.withOpacity(0.15) : Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(8), border: Border.all(color: sel ? AppColors.darkSecondary.withOpacity(0.4) : Colors.transparent)),
                child: Text(d, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? AppColors.darkSecondary : null))))); }).toList()),
          ])),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ratio', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            Row(children: _ratios.map((r) { final sel = _ratio == r; return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(onTap: () => setState(() => _ratio = r),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: sel ? AppColors.darkTertiary.withOpacity(0.15) : Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(8), border: Border.all(color: sel ? AppColors.darkTertiary.withOpacity(0.4) : Colors.transparent)),
                child: Text(r, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? AppColors.darkTertiary : null))))); }).toList()),
          ])),
        ]),
        Container(margin: const EdgeInsets.symmetric(vertical: 12), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.darkAccentYellow.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkAccentYellow.withOpacity(0.2))),
          child: Row(children: [const Icon(Icons.info_outline_rounded, color: AppColors.darkAccentYellow, size: 16), const SizedBox(width: 8),
            const Expanded(child: Text('Runway, Pika, Luma, and Kling API keys required.\nAdd in Settings → API Keys.', style: TextStyle(color: AppColors.darkAccentYellow, fontSize: 12)))])),
        const SizedBox(height: 8),
        GradientButton(label: _loading ? 'Generating...' : 'Generate Video', isLoading: _loading, width: double.infinity, height: 54,
          icon: _loading ? null : const Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
          onPressed: _loading ? null : () async {
            setState(() => _loading = true);
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) setState(() => _loading = false);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add your video API key in Settings to generate real videos.')));
          }),
        const SizedBox(height: 40),
      ]),
    );
  }
}

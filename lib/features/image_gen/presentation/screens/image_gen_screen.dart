import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/omni_app_bar.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../providers/image_gen_provider.dart';

enum GalleryMode { history, gallery }

class ImageGenScreen extends ConsumerStatefulWidget {
  const ImageGenScreen({super.key});
  @override ConsumerState<ImageGenScreen> createState() => _ImageGenScreenState();
}

class _ImageGenScreenState extends ConsumerState<ImageGenScreen> {
  final _promptCtrl = TextEditingController();
  final _negCtrl = TextEditingController();
  bool _showAdvanced = false;

  static const _providers = [
    {'id': 'openai', 'name': 'DALL-E 3', 'icon': '🎨'},
    {'id': 'stability', 'name': 'Stable Diffusion', 'icon': '⚡'},
    {'id': 'replicate', 'name': 'Flux 1.1 Pro', 'icon': '🌀'},
  ];
  static const _ratios = ['1:1', '16:9', '9:16', '4:3', '3:4'];
  static const _styles = ['vivid', 'natural', 'anime', 'photorealistic', '3d-render', 'digital-art'];

  @override void dispose() { _promptCtrl.dispose(); _negCtrl.dispose(); super.dispose(); }

  bool _isDataUrl(String url) => url.startsWith('data:');

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(imageGenProvider);
    final notifier = ref.read(imageGenProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground1 : null,
      appBar: OmniAppBar(
        title: 'Image Studio',
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_rounded),
            onPressed: () => context.push(RouteNames.imageGallery),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Provider selector
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _providers.length,
            itemBuilder: (_, i) {
              final p = _providers[i];
              final sel = state.provider == p['id'];
              return GestureDetector(
                onTap: () => notifier.setProvider(p['id']!),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.darkPrimary.withOpacity(0.15) : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? AppColors.darkPrimary.withOpacity(0.4) : Theme.of(context).colorScheme.outline),
                  ),
                  child: Text('${p['icon']} ${p['name']}',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: sel ? AppColors.darkPrimary : null)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Generated images
        if (state.generatedUrls.isNotEmpty) ...[
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: state.generatedUrls.length == 1 ? 1 : 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: state.generatedUrls.map((url) => ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _isDataUrl(url)
                  ? Image.memory(base64Decode(url.split(',').last), fit: BoxFit.cover)
                  : CachedNetworkImage(imageUrl: url, fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.darkSurfaceVariant,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)))),
            )).toList(),
          ).animate().fadeIn(),
          const SizedBox(height: 16),
        ],

        // Prompt
        TextField(
          controller: _promptCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Prompt',
            hintText: 'A cosmic nebula in the shape of a dragon, ultrarealistic...',
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.auto_fix_high_rounded, size: 20,
                color: AppColors.darkPrimary.withOpacity(0.6)),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Aspect ratio
        Row(children: [
          Text('Ratio', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(width: 12),
          Expanded(child: SizedBox(height: 36, child: ListView(
            scrollDirection: Axis.horizontal,
            children: _ratios.map((r) {
              final sel = state.aspectRatio == r;
              return GestureDetector(
                onTap: () => notifier.setAspectRatio(r),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.darkPrimary.withOpacity(0.15) : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sel ? AppColors.darkPrimary.withOpacity(0.4) : Theme.of(context).colorScheme.outline),
                  ),
                  child: Text(r, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: sel ? AppColors.darkPrimary : null)),
                ),
              );
            }).toList(),
          ))),
        ]),
        const SizedBox(height: 8),

        // Advanced toggle
        GestureDetector(
          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          child: Row(children: [
            Text('Advanced Options', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(width: 4),
            Icon(_showAdvanced ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 16),
          ]),
        ),

        if (_showAdvanced) ...[
          const SizedBox(height: 10),
          TextField(controller: _negCtrl,
            decoration: const InputDecoration(labelText: 'Negative Prompt (optional)',
              hintText: 'blurry, low quality, watermark...')),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: _styles.map((s) {
            final sel = state.style == s;
            return GestureDetector(
              onTap: () => notifier.setStyle(sel ? null : s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: sel ? AppColors.darkSecondary.withOpacity(0.15) : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? AppColors.darkSecondary.withOpacity(0.4) : Theme.of(context).colorScheme.outline),
                ),
                child: Text(s, style: TextStyle(fontSize: 12, color: sel ? AppColors.darkSecondary : null)),
              ),
            );
          }).toList()),
        ],

        if (state.error != null) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(10)),
            child: Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer))),
        ],

        const SizedBox(height: 20),
        GradientButton(
          label: state.isGenerating ? 'Generating...' : 'Generate Image',
          isLoading: state.isGenerating,
          width: double.infinity, height: 54,
          icon: state.isGenerating ? null : const Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 18),
          onPressed: state.isGenerating ? null : () {
            notifier.setPrompt(_promptCtrl.text);
            notifier.setNegativePrompt(_negCtrl.text);
            notifier.generate();
          },
        ),
        const SizedBox(height: 40),
      ]),
    );
  }
}

class ImageGalleryScreen extends ConsumerWidget {
  final GalleryMode mode;
  const ImageGalleryScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(imageHistoryProvider);
    final images = mode == GalleryMode.gallery ? all.where((i) => i.isFavorited).toList() : all;

    return Scaffold(
      appBar: OmniAppBar(title: mode == GalleryMode.gallery ? 'Favorites' : 'History'),
      body: images.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.photo_library_outlined, size: 56, color: Colors.white24),
              const SizedBox(height: 12),
              Text(mode == GalleryMode.gallery ? 'No favorites yet' : 'No images yet'),
            ]))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: images.length,
              itemBuilder: (_, i) {
                final img = images[i];
                final url = img.imageUrls.isNotEmpty ? img.imageUrls.first : '';
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(fit: StackFit.expand, children: [
                    url.startsWith('data:')
                        ? Image.memory(base64Decode(url.split(',').last), fit: BoxFit.cover)
                        : CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                    Positioned(bottom: 0, left: 0, right: 0, child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)])),
                      child: Text(img.prompt, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 11)))),
                    Positioned(top: 4, right: 4, child: GestureDetector(
                      onTap: () => ref.read(imageGenProvider.notifier).toggleFavorite(img.id),
                      child: Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                        child: Icon(img.isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 16, color: img.isFavorited ? AppColors.darkTertiary : Colors.white)))),
                  ]),
                ).animate(delay: Duration(milliseconds: i * 30)).fadeIn();
              }),
    );
  }
}

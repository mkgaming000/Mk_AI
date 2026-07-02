import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/omni_app_bar.dart';
import '../../providers/search_provider.dart';

class SearchAIScreen extends ConsumerStatefulWidget {
  const SearchAIScreen({super.key});
  @override ConsumerState<SearchAIScreen> createState() => _SearchAIScreenState();
}

class _SearchAIScreenState extends ConsumerState<SearchAIScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override void dispose() { _ctrl.dispose(); _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground1 : null,
      appBar: const OmniAppBar(title: 'Search AI'),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          Expanded(child: Container(decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outline)),
            child: TextField(controller: _ctrl, focusNode: _focus, textInputAction: TextInputAction.search,
              decoration: InputDecoration(hintText: 'Search anything...', prefixIcon: const Icon(Icons.search_rounded, size: 20), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: _ctrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded, size: 16), onPressed: () { _ctrl.clear(); setState(() {}); }) : null),
              onChanged: (_) => setState(() {}),
              onSubmitted: (q) => ref.read(searchProvider.notifier).search(q))),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: state.isSearching || state.isDeepResearching ? null : () => ref.read(searchProvider.notifier).search(_ctrl.text.trim()),
            child: Container(width: 46, height: 46, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
              child: state.isSearching ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))) : const Icon(Icons.search_rounded, color: Colors.white))),
        ])),
        if (!state.isSearching && !state.isDeepResearching && state.results.isEmpty)
          TextButton.icon(onPressed: _ctrl.text.trim().isNotEmpty ? () => ref.read(searchProvider.notifier).deepResearch(_ctrl.text.trim()) : null,
            icon: const Icon(Icons.manage_search_rounded, size: 18), label: const Text('Deep Research')),
        Expanded(child: state.isSearching || state.isDeepResearching
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 14),
              Text(state.isDeepResearching ? 'Deep researching...' : 'Searching...', style: Theme.of(context).textTheme.bodyMedium)]))
          : ListView(padding: const EdgeInsets.all(12), children: [
            if (state.error != null) _ErrorCard(state.error!),
            if (state.aiSummary != null) ...[
              _SectionLabel('AI Summary'),
              Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.darkPrimary.withOpacity(0.08), AppColors.darkSecondary.withOpacity(0.04)]), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.darkPrimary.withOpacity(0.2))),
                child: MarkdownBody(data: state.aiSummary!, selectable: true, styleSheet: MarkdownStyleSheet(p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)))).animate().fadeIn(),
            ],
            if (state.results.isNotEmpty) ...[
              _SectionLabel('${state.results.length} Results'),
              ...state.results.asMap().entries.map((e) => _ResultCard(result: e.value, index: e.key)),
            ],
            if (state.results.isEmpty && state.aiSummary == null && state.query.isNotEmpty)
              Center(child: Column(children: [
                const SizedBox(height: 40),
                const Icon(Icons.search_off_rounded, size: 48, color: Colors.white24),
                const SizedBox(height: 12),
                Text('No results for "${state.query}"'),
              ])),
          ])),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);
  @override build(ctx) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(title, style: Theme.of(ctx).textTheme.labelLarge));
}

class _ResultCard extends StatelessWidget {
  final SearchResult result; final int index;
  const _ResultCard({required this.result, required this.index});
  @override build(BuildContext context) => GestureDetector(
    onTap: () async { final uri = Uri.tryParse(result.url); if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication); },
    child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).colorScheme.outline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (result.source != null) Text(result.source!, style: TextStyle(fontSize: 10, color: AppColors.darkSecondary, fontWeight: FontWeight.w600)),
        Text(result.title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(result.snippet, maxLines: 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5)),
      ])).animate(delay: Duration(milliseconds: index * 30)).fadeIn());
}

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard(this.error);
  @override build(ctx) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.errorContainer, borderRadius: BorderRadius.circular(10)),
    child: Row(children: [Icon(Icons.error_outline_rounded, color: Theme.of(ctx).colorScheme.error, size: 16), const SizedBox(width: 8), Expanded(child: Text(error))]));
}

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';

class SearchResult {
  final String title;
  final String url;
  final String snippet;
  final String? publishedDate;
  final String? source;

  const SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    this.publishedDate,
    this.source,
  });

  factory SearchResult.fromDDG(Map<String, dynamic> json) => SearchResult(
        title: json['Text'] as String? ?? '',
        url: json['FirstURL'] as String? ?? '',
        snippet: json['Text'] as String? ?? '',
      );
}

class SearchState {
  final bool isSearching;
  final bool isDeepResearching;
  final String query;
  final List<SearchResult> results;
  final String? aiSummary;
  final String? error;
  final List<String> searchHistory;

  const SearchState({
    this.isSearching = false,
    this.isDeepResearching = false,
    this.query = '',
    this.results = const [],
    this.aiSummary,
    this.error,
    this.searchHistory = const [],
  });

  SearchState copyWith({
    bool? isSearching,
    bool? isDeepResearching,
    String? query,
    List<SearchResult>? results,
    String? aiSummary,
    String? error,
    List<String>? searchHistory,
  }) =>
      SearchState(
        isSearching: isSearching ?? this.isSearching,
        isDeepResearching: isDeepResearching ?? this.isDeepResearching,
        query: query ?? this.query,
        results: results ?? this.results,
        aiSummary: aiSummary,
        error: error,
        searchHistory: searchHistory ?? this.searchHistory,
      );
}

class SearchNotifier extends StateNotifier<SearchState> {
  final Ref _ref;

  SearchNotifier(this._ref) : super(const SearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    state = state.copyWith(
        isSearching: true, query: query, results: [], aiSummary: null, error: null);

    try {
      final results = await _fetchSearchResults(query);
      state = state.copyWith(
        isSearching: false,
        results: results,
        searchHistory: [query, ...state.searchHistory.take(49)],
      );
      if (results.isNotEmpty) await _summarizeResults(query, results);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: e.toString());
    }
  }

  Future<void> deepResearch(String topic) async {
    state = state.copyWith(
        isDeepResearching: true, query: topic, results: [], aiSummary: null, error: null);

    try {
      final queries = await _generateSubQueries(topic);
      final allResults = <SearchResult>[];
      for (final q in queries.take(4)) {
        final r = await _fetchSearchResults(q);
        allResults.addAll(r.take(3));
      }
      state = state.copyWith(isDeepResearching: false, results: allResults);
      await _deepSynthesis(topic, allResults);
    } catch (e) {
      state = state.copyWith(isDeepResearching: false, error: e.toString());
    }
  }

  Future<List<SearchResult>> _fetchSearchResults(String query) async {
    try {
      final dio = ApiClient.create(baseUrl: 'https://api.duckduckgo.com');
      final response = await dio.get('/', queryParameters: {
        'q': query,
        'format': 'json',
        'no_html': '1',
        'skip_disambig': '1',
      });
      final data = response.data as Map<String, dynamic>;
      final results = <SearchResult>[];

      final abstract = data['AbstractText'] as String?;
      final abstractUrl = data['AbstractURL'] as String?;
      final abstractSource = data['AbstractSource'] as String?;
      if (abstract != null && abstract.isNotEmpty) {
        results.add(SearchResult(
          title: data['Heading'] as String? ?? query,
          url: abstractUrl ?? '',
          snippet: abstract,
          source: abstractSource,
        ));
      }

      final relatedTopics = data['RelatedTopics'] as List<dynamic>? ?? [];
      for (final topic in relatedTopics.take(6)) {
        if (topic is Map<String, dynamic>) {
          final text = topic['Text'] as String?;
          final firstUrl = topic['FirstURL'] as String?;
          if (text != null && firstUrl != null && text.isNotEmpty) {
            results.add(SearchResult(
              title: text.split(' - ').first,
              url: firstUrl,
              snippet: text,
            ));
          }
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> _generateSubQueries(String topic) async {
    final settings = _ref.read(settingsProvider);
    final chatRepo = _ref.read(chatRepositoryProvider);
    final buffer = StringBuffer();

    try {
      await for (final chunk in chatRepo.streamResponse(
        providerId: settings.defaultProvider,
        modelId: settings.defaultModel,
        messages: [],
        systemPrompt:
            'Generate exactly 4 specific search queries for researching the '
            'given topic. Output only the queries, one per line, no numbering, '
            'no extra text.',
      )) {
        buffer.write(chunk);
      }
      return buffer
          .toString()
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .take(4)
          .toList();
    } catch (_) {
      return [topic];
    }
  }

  Future<void> _summarizeResults(
      String query, List<SearchResult> results) async {
    final settings = _ref.read(settingsProvider);
    final chatRepo = _ref.read(chatRepositoryProvider);
    final context =
        results.map((r) => '${r.title}: ${r.snippet}').join('\n\n');
    final buffer = StringBuffer();

    try {
      await for (final chunk in chatRepo.streamResponse(
        providerId: settings.defaultProvider,
        modelId: settings.defaultModel,
        messages: [],
        systemPrompt:
            'Summarize the following search results for the query "$query" '
            'in 2-3 concise paragraphs:\n\n$context',
      )) {
        buffer.write(chunk);
        state = state.copyWith(aiSummary: buffer.toString());
      }
    } catch (_) {
      // Summarization failure is non-critical
    }
  }

  Future<void> _deepSynthesis(
      String topic, List<SearchResult> results) async {
    final settings = _ref.read(settingsProvider);
    final chatRepo = _ref.read(chatRepositoryProvider);
    final context =
        results.map((r) => '[${r.source ?? r.url}] ${r.snippet}').join('\n\n');
    final buffer = StringBuffer();

    try {
      await for (final chunk in chatRepo.streamResponse(
        providerId: settings.defaultProvider,
        modelId: settings.defaultModel,
        messages: [],
        systemPrompt:
            'Write a comprehensive research report on "$topic" using the '
            'following sources. Include: Executive Summary, Key Findings, '
            'Analysis, Conclusion, and References.\n\nSources:\n$context',
      )) {
        buffer.write(chunk);
        state = state.copyWith(aiSummary: buffer.toString());
      }
    } catch (_) {}
  }

  void clearSearch() => state = const SearchState();
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>(
        (ref) => SearchNotifier(ref));

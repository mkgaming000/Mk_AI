import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/storage/database/hive_boxes.dart';
import '../../../data/models/agent_model.dart';
import '../../../features/settings/providers/settings_provider.dart';

class AgentsNotifier extends StateNotifier<List<AgentModel>> {
  AgentsNotifier() : super([]) { _load(); }
  final _uuid = const Uuid();

  void _load() => state = HiveBoxes.agents.values.toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Future<AgentModel> create({
    required String name,
    required String description,
    required String systemPrompt,
    required String providerId,
    required String modelId,
    String? iconEmoji,
    int? color,
    bool enableWebSearch = false,
    bool enableCodeExecution = false,
    bool enableMemory = false,
    double? temperature,
  }) async {
    final agent = AgentModel(
      id: _uuid.v4(),
      name: name,
      description: description,
      systemPrompt: systemPrompt,
      providerId: providerId,
      modelId: modelId,
      iconEmoji: iconEmoji ?? '🤖',
      color: color,
      enableWebSearch: enableWebSearch,
      enableCodeExecution: enableCodeExecution,
      enableMemory: enableMemory,
      temperature: temperature,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await HiveBoxes.agents.put(agent.id, agent);
    _load();
    return agent;
  }

  Future<void> update(AgentModel updated) async {
    final a = updated.copyWith(updatedAt: DateTime.now());
    await HiveBoxes.agents.put(a.id, a);
    _load();
  }

  Future<void> delete(String id) async {
    await HiveBoxes.agents.delete(id);
    _load();
  }

  void refresh() => _load();
}

final agentsProvider =
    StateNotifierProvider<AgentsNotifier, List<AgentModel>>(
        (ref) => AgentsNotifier());

// Pre-built default agents
final defaultAgentsProvider = Provider<List<AgentModel>>((ref) {
  final settings = ref.watch(settingsProvider);
  return [
    AgentModel(
      id: 'builtin_research',
      name: 'Research Assistant',
      description: 'Deep research on any topic with citations',
      systemPrompt:
          'You are a meticulous research assistant. Provide thorough, '
          'accurate, well-structured research with clear source attribution. '
          'Break down complex topics, identify key findings, and present '
          'balanced perspectives. Always acknowledge uncertainty.',
      providerId: settings.defaultProvider,
      modelId: settings.defaultModel,
      iconEmoji: '🔬',
      color: 0xFF22D3EE,
      enableWebSearch: true,
      enableMemory: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    AgentModel(
      id: 'builtin_coder',
      name: 'Code Reviewer',
      description: 'Reviews code, finds bugs, suggests improvements',
      systemPrompt:
          'You are an expert software engineer and code reviewer. Analyze '
          'code for bugs, security issues, performance, and best practices. '
          'Provide specific, actionable feedback with code examples. '
          'Be thorough but constructive.',
      providerId: settings.defaultProvider,
      modelId: settings.defaultModel,
      iconEmoji: '💻',
      color: 0xFF8B5CF6,
      enableWebSearch: false,
      enableCodeExecution: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    AgentModel(
      id: 'builtin_writer',
      name: 'Creative Writer',
      description: 'Creative writing, stories, scripts, and poetry',
      systemPrompt:
          'You are a creative writing expert with expertise in fiction, '
          'non-fiction, screenwriting, and poetry. Help users develop '
          'compelling narratives, memorable characters, and vivid prose. '
          'Offer both creative output and constructive guidance.',
      providerId: settings.defaultProvider,
      modelId: settings.defaultModel,
      iconEmoji: '✍️',
      color: 0xFFF472B6,
      enableWebSearch: false,
      temperature: 1.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    AgentModel(
      id: 'builtin_analyst',
      name: 'Data Analyst',
      description: 'Analyzes data, creates insights, writes reports',
      systemPrompt:
          'You are a data analyst expert. Help interpret data, identify '
          'patterns and trends, create visualizations, and generate '
          'actionable business insights. Use statistical reasoning and '
          'present findings clearly for both technical and non-technical audiences.',
      providerId: settings.defaultProvider,
      modelId: settings.defaultModel,
      iconEmoji: '📊',
      color: 0xFF34D399,
      enableWebSearch: true,
      enableCodeExecution: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
});

final allAgentsProvider = Provider<List<AgentModel>>((ref) {
  final custom = ref.watch(agentsProvider);
  final defaults = ref.watch(defaultAgentsProvider);
  return [...defaults, ...custom];
});

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../data/models/agent_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/repositories/chat_repository_impl.dart';
import '../../../data/services/mcp_client_service.dart';

class AgentStep {
  final String id;
  final String type;
  final String content;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final bool isError;

  AgentStep({
    required this.id,
    required this.type,
    required this.content,
    this.metadata,
    DateTime? timestamp,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum AgentEventType { token, stepStart, stepComplete, toolCall, toolResult, done, error }

class AgentEvent {
  final AgentEventType type;
  final String content;
  final AgentStep? step;
  const AgentEvent({required this.type, required this.content, this.step});
}

class AgentRunnerService {
  final ChatRepositoryImpl _chatRepo;
  final McpClientService _mcpClient;
  static const int _maxIterations = 20;

  AgentRunnerService({
    required ChatRepositoryImpl chatRepo,
    required McpClientService mcpClient,
  })  : _chatRepo = chatRepo,
        _mcpClient = mcpClient;

  Stream<AgentEvent> run({
    required AgentModel agent,
    required String userInput,
    List<MessageModel> history = const [],
  }) async* {
    int iteration = 0;

    final mcpTools = _mcpClient.allTools
        .where((t) => agent.mcpServerIds.contains(t.serverId))
        .map((t) => t.toOpenAIToolDefinition())
        .toList();

    final builtInTools = _buildBuiltInTools(agent);
    final allTools = [...mcpTools, ...builtInTools];

    final messages = [
      ...history,
      MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: 'agent_${agent.id}',
        role: MessageRole.user,
        content: userInput,
        createdAt: DateTime.now(),
      ),
    ];

    while (iteration < _maxIterations) {
      iteration++;
      final responseBuffer = StringBuffer();

      yield AgentEvent(
          type: AgentEventType.stepStart,
          content: 'Thinking... (step $iteration)');

      try {
        await for (final chunk in _chatRepo.streamResponse(
          providerId: agent.providerId,
          modelId: agent.modelId,
          messages: messages,
          systemPrompt: _buildSystemPrompt(agent, allTools),
          temperature: agent.temperature ?? 0.7,
          maxTokens: 4096,
        )) {
          responseBuffer.write(chunk);
          yield AgentEvent(type: AgentEventType.token, content: chunk);
        }
      } catch (e) {
        yield AgentEvent(type: AgentEventType.error, content: e.toString());
        return;
      }

      final responseText = responseBuffer.toString();

      messages.add(MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: 'agent_${agent.id}',
        role: MessageRole.assistant,
        content: responseText,
        createdAt: DateTime.now(),
      ));

      // Check for tool call in the response text
      final toolCall = _parseToolCallFromText(responseText);

      if (toolCall == null) {
        // No tool call — agent is done
        yield AgentEvent(
          type: AgentEventType.done,
          content: responseText,
          step: AgentStep(
            id: 'step_$iteration',
            type: 'output',
            content: responseText,
          ),
        );
        return;
      }

      final toolName = toolCall['name'] as String;
      final toolArgsJson = toolCall['args'] as String? ?? '{}';

      yield AgentEvent(
        type: AgentEventType.toolCall,
        content: 'Using tool: $toolName',
        step: AgentStep(
          id: 'tool_call_$iteration',
          type: 'tool_call',
          content: toolName,
          metadata: {'args': toolArgsJson},
        ),
      );

      final result = await _executeTool(toolName, toolArgsJson, agent);

      yield AgentEvent(
        type: AgentEventType.toolResult,
        content: result,
        step: AgentStep(
          id: 'tool_result_$iteration',
          type: 'tool_result',
          content: result,
        ),
      );

      messages.add(MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: 'agent_${agent.id}',
        role: MessageRole.tool,
        content: 'Tool ($toolName) result:\n$result',
        createdAt: DateTime.now(),
      ));
    }

    yield AgentEvent(
      type: AgentEventType.error,
      content: 'Maximum iterations ($_maxIterations) reached.',
    );
  }

  Future<String> _executeTool(
      String toolName, String argsJson, AgentModel agent) async {
    try {
      Map<String, dynamic> args;
      try {
        args = jsonDecode(argsJson) as Map<String, dynamic>;
      } catch (_) {
        args = {};
      }

      // MCP tool: "serverId__toolName"
      if (toolName.contains('__')) {
        final parts = toolName.split('__');
        final serverId = parts.first;
        final name = parts.skip(1).join('__');
        final result = await _mcpClient.executeTool(
          serverId: serverId,
          toolName: name,
          arguments: args,
        );
        return result.displayText;
      }

      switch (toolName) {
        case 'web_search':
          return '[Web Search] Query: "${args['query']}" — '
              'Connect to a search MCP server for real results.';
        case 'code_execute':
          return '[Code Execute] Language: ${args['language']} — '
              'Connect to a code execution MCP server for real output.';
        default:
          return 'Unknown tool: $toolName';
      }
    } catch (e) {
      return 'Tool error: $e';
    }
  }

  Map<String, dynamic>? _parseToolCallFromText(String text) {
    final regex = RegExp(
      r'<tool_call>\s*\{[^}]*"name"\s*:\s*"([^"]+)"[^}]*"args"\s*:\s*(\{[^}]*\})[^}]*\}\s*</tool_call>',
      dotAll: true,
    );
    final match = regex.firstMatch(text);
    if (match == null) return null;
    return {'name': match.group(1), 'args': match.group(2)};
  }

  String _buildSystemPrompt(AgentModel agent, List<Map<String, dynamic>> tools) {
    final buffer = StringBuffer();
    buffer.writeln(agent.systemPrompt);
    buffer.writeln();

    if (tools.isNotEmpty) {
      buffer.writeln('You have access to the following tools:');
      for (final tool in tools) {
        final fn = tool['function'] as Map<String, dynamic>;
        buffer.writeln('- ${fn['name']}: ${fn['description']}');
      }
      buffer.writeln();
      buffer.writeln(
          'To call a tool, wrap your call in <tool_call>{"name":"toolName","args":{"key":"value"}}</tool_call>');
      buffer.writeln('Think step by step. Provide a final answer when complete.');
    }

    return buffer.toString();
  }

  List<Map<String, dynamic>> _buildBuiltInTools(AgentModel agent) {
    final tools = <Map<String, dynamic>>[];

    if (agent.enableWebSearch) {
      tools.add({
        'type': 'function',
        'function': {
          'name': 'web_search',
          'description': 'Search the web for current information',
          'parameters': {
            'type': 'object',
            'properties': {
              'query': {'type': 'string', 'description': 'Search query'},
            },
            'required': ['query'],
          },
        },
      });
    }

    if (agent.enableCodeExecution) {
      tools.add({
        'type': 'function',
        'function': {
          'name': 'code_execute',
          'description': 'Execute code and return output',
          'parameters': {
            'type': 'object',
            'properties': {
              'code': {'type': 'string', 'description': 'Code to execute'},
              'language': {'type': 'string', 'description': 'Programming language'},
            },
            'required': ['code', 'language'],
          },
        },
      });
    }

    return tools;
  }
}

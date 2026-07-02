import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/database/hive_boxes.dart';
import '../models/mcp_server_model.dart';

class McpTool {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
  final String serverId;

  const McpTool({
    required this.name,
    required this.description,
    required this.inputSchema,
    required this.serverId,
  });

  Map<String, dynamic> toOpenAIToolDefinition() => {
        'type': 'function',
        'function': {
          'name': '${serverId}__$name',
          'description': description,
          'parameters': inputSchema,
        },
      };

  factory McpTool.fromJson(Map<String, dynamic> j, String serverId) =>
      McpTool(
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        inputSchema: j['inputSchema'] as Map<String, dynamic>? ?? {},
        serverId: serverId,
      );
}

class McpToolResult {
  final String toolName;
  final bool isError;
  final dynamic content;
  final String? errorMessage;
  final int durationMs;

  const McpToolResult({
    required this.toolName,
    required this.isError,
    this.content,
    this.errorMessage,
    required this.durationMs,
  });

  String get displayText {
    if (isError) return 'Error: $errorMessage';
    if (content is String) return content as String;
    return jsonEncode(content);
  }
}

class McpClientService {
  final Map<String, Dio> _clients = {};
  final Map<String, List<McpTool>> _serverTools = {};
  final Map<String, bool> _connectionStatus = {};

  List<McpServerModel> get enabledServers =>
      HiveBoxes.mcpServers.values.where((s) => s.isEnabled).toList();

  List<McpTool> get allTools =>
      _serverTools.values.expand((t) => t).toList();

  bool isConnected(String serverId) =>
      _connectionStatus[serverId] == true;

  Future<void> connectAll() async {
    await Future.wait(enabledServers.map((s) => connect(s.id)),
        eagerError: false);
  }

  Future<bool> connect(String serverId) async {
    final server = HiveBoxes.mcpServers.get(serverId);
    if (server == null) return false;
    try {
      final url = server.url.endsWith('/')
          ? server.url.substring(0, server.url.length - 1)
          : server.url;
      final dio = ApiClient.create(
        baseUrl: url,
        defaultHeaders: {...server.headers, 'Content-Type': 'application/json'},
        connectionTimeoutSeconds: 10,
      );
      _clients[serverId] = dio;
      await _initialize(serverId, dio);
      await _discoverTools(serverId, dio);
      _connectionStatus[serverId] = true;
      server.isConnected = true;
      server.lastConnected = DateTime.now();
      await HiveBoxes.mcpServers.put(serverId, server);
      return true;
    } catch (e) {
      debugPrint('MCP connect error $serverId: $e');
      _connectionStatus[serverId] = false;
      return false;
    }
  }

  Future<void> _initialize(String serverId, Dio dio) async {
    try {
      await dio.post('/mcp/v1/initialize', data: {
        'protocolVersion': '2024-11-05',
        'capabilities': {'roots': {'listChanged': true}},
        'clientInfo': {'name': 'OmniForge AI', 'version': '1.0.0'},
      });
    } catch (_) {}
  }

  Future<void> _discoverTools(String serverId, Dio dio) async {
    try {
      final response = await dio.post('/mcp/v1/tools/list',
          data: {'jsonrpc': '2.0', 'id': 1, 'method': 'tools/list'});
      final result = (response.data as Map<String, dynamic>)['result']
          as Map<String, dynamic>?;
      final toolsJson = result?['tools'] as List<dynamic>? ?? [];
      _serverTools[serverId] = toolsJson
          .map((t) => McpTool.fromJson(t as Map<String, dynamic>, serverId))
          .toList();
    } catch (e) {
      _serverTools[serverId] = [];
    }
  }

  Future<McpToolResult> executeTool({
    required String serverId,
    required String toolName,
    required Map<String, dynamic> arguments,
  }) async {
    final stopwatch = Stopwatch()..start();
    final client = _clients[serverId];
    if (client == null) {
      return McpToolResult(
          toolName: toolName, isError: true,
          errorMessage: 'Server not connected: $serverId', durationMs: 0);
    }
    try {
      final response = await client.post('/mcp/v1/tools/call', data: {
        'jsonrpc': '2.0',
        'id': DateTime.now().millisecondsSinceEpoch,
        'method': 'tools/call',
        'params': {'name': toolName, 'arguments': arguments},
      });
      stopwatch.stop();
      final data = response.data as Map<String, dynamic>;
      if (data.containsKey('error')) {
        final err = data['error'] as Map<String, dynamic>;
        return McpToolResult(
            toolName: toolName, isError: true,
            errorMessage: err['message'] as String? ?? 'Unknown error',
            durationMs: stopwatch.elapsedMilliseconds);
      }
      final content = _extractContent(data['result']);
      return McpToolResult(
          toolName: toolName, isError: false, content: content,
          durationMs: stopwatch.elapsedMilliseconds);
    } catch (e) {
      stopwatch.stop();
      return McpToolResult(
          toolName: toolName, isError: true,
          errorMessage: e.toString(), durationMs: stopwatch.elapsedMilliseconds);
    }
  }

  dynamic _extractContent(dynamic result) {
    if (result == null) return '';
    if (result is Map<String, dynamic>) {
      final content = result['content'];
      if (content is List) {
        return content
            .whereType<Map<String, dynamic>>()
            .where((c) => c['type'] == 'text')
            .map((c) => c['text'] as String? ?? '')
            .join('\n');
      }
      return result;
    }
    return result.toString();
  }

  void disconnect(String serverId) {
    _clients.remove(serverId);
    _serverTools.remove(serverId);
    _connectionStatus[serverId] = false;
  }

  void disconnectAll() {
    _clients.clear();
    _serverTools.clear();
    _connectionStatus.clear();
  }
}

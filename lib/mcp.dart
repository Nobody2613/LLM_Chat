import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// MCP（Model Context Protocol）Streamable HTTP transport 客户端。
///
/// 协议：单一 endpoint，POST JSON-RPC 2.0 消息。
/// 响应可能是 application/json（单个响应）或 text/event-stream
/// （流式响应 + 服务器通知）。
///
/// 参考：MCP 2025-03-26 specification 的 Streamable HTTP transport。

/// 一个 MCP 工具定义（服务器声明的能力）。
class McpToolDef {
  const McpToolDef({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  /// 工具名（服务器内唯一）
  final String name;

  /// 工具描述（供 LLM 判断是否调用）
  final String description;

  /// 参数 JSON Schema（直接作为 OpenAI function parameters）
  final Map<String, dynamic> inputSchema;

  factory McpToolDef.fromJson(Map<String, dynamic> j) => McpToolDef(
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        inputSchema: (j['inputSchema'] as Map<String, dynamic>?) ??
            const {'type': 'object', 'properties': {}},
      );
}

/// 工具调用结果（content blocks 拼接为文本）。
class McpToolResult {
  const McpToolResult({required this.text, this.isError = false});

  /// 所有 text content block 拼接的结果文本
  final String text;

  /// 服务器标记的调用错误
  final bool isError;
}

/// MCP Streamable HTTP 客户端：连接单一 endpoint，
/// 完成 initialize 握手后可列出/调用工具。
class McpClient {
  McpClient({required this.url, this.token = ''});

  /// MCP 服务器 endpoint（如 https://server.com/mcp）
  final String url;

  /// 可选 Bearer token
  final String token;

  final http.Client _http = http.Client();
  int _nextId = 1;
  bool _initialized = false;

  /// 协议版本（与服务器协商后填充；默认 2025-03-26）
  String _protocolVersion = '2025-03-26';

  /// 发送一条 JSON-RPC 请求并等待对应的响应。
  /// 支持 application/json（直接解析）与 text/event-stream
  /// （读 SSE 流，取第一个含 result/error 的 data 行）。
  Future<Map<String, dynamic>> _request(
    String method, {
    Map<String, dynamic>? params,
  }) async {
    final id = _nextId++;
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    });
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json, text/event-stream',
    };
    if (token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }
    final res = await _http
        .post(Uri.parse(url), headers: headers, body: body)
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final contentType = res.headers['content-type'] ?? '';

    if (contentType.contains('text/event-stream')) {
      // SSE 流：逐行找 data: {json}，匹配 id 的响应（或首个 result/error）
      for (final line in res.body.split('\n')) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;
        final data = trimmed.substring(5).trim();
        if (data.isEmpty || data == '[DONE]') continue;
        try {
          final obj = jsonDecode(data) as Map<String, dynamic>;
          // 匹配 id，或者是 result/error 响应（无 id 时取首个）
          if (obj['id'] == id ||
              (obj['id'] == null && (obj['result'] != null || obj['error'] != null))) {
            return obj;
          }
        } catch (_) {
          // 跳过非 JSON 的 data 行（如 ping 通知）
        }
      }
      throw Exception('SSE 流中未找到响应');
    }

    // application/json：直接解析
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// 握手：initialize（仅一次，幂等）
  Future<void> initialize() async {
    if (_initialized) return;
    final res = await _request('initialize', params: {
      'protocolVersion': _protocolVersion,
      'capabilities': <String, dynamic>{},
      'clientInfo': {'name': 'llm_ui', 'version': '1.0.0'},
    });
    if (res['error'] != null) {
      throw Exception('initialize 失败: ${res['error']}');
    }
    final result = res['result'] as Map<String, dynamic>?;
    if (result != null) {
      final pv = result['protocolVersion'];
      if (pv is String && pv.isNotEmpty) _protocolVersion = pv;
    }
    // 通知服务器初始化完成（fire-and-forget；失败忽略）
    try {
      final body = jsonEncode({
        'jsonrpc': '2.0',
        'method': 'notifications/initialized',
      });
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer ${token.trim()}';
      }
      await _http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // 通知失败不影响主流程
    }
    _initialized = true;
  }

  /// 列出服务器提供的所有工具。
  Future<List<McpToolDef>> listTools() async {
    await initialize();
    final res = await _request('tools/list');
    if (res['error'] != null) {
      throw Exception('tools/list 失败: ${res['error']}');
    }
    final result = res['result'] as Map<String, dynamic>?;
    final tools = (result?['tools'] as List?) ?? [];
    return tools
        .map((t) => McpToolDef.fromJson(t as Map<String, dynamic>))
        .where((t) => t.name.isNotEmpty)
        .toList();
  }

  /// 调用一个工具，返回拼接后的文本结果。
  Future<McpToolResult> callTool(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    await initialize();
    final res = await _request('tools/call', params: {
      'name': name,
      'arguments': arguments,
    });
    if (res['error'] != null) {
      throw Exception('tools/call 失败: ${res['error']}');
    }
    final result = res['result'] as Map<String, dynamic>?;
    final isError = result?['isError'] == true;
    final content = (result?['content'] as List?) ?? [];
    // 拼接所有 text content block
    final buf = StringBuffer();
    for (final c in content) {
      final m = c as Map<String, dynamic>;
      if (m['type'] == 'text') {
        buf.writeln(m['text']);
      }
    }
    return McpToolResult(text: buf.toString().trim(), isError: isError);
  }

  void dispose() {
    _http.close();
  }
}

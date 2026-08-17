import 'package:flutter_test/flutter_test.dart';

import 'package:llm_ui/chat.dart';

void main() {
  group('parseMcpServersJson 宽容解析', () {
    test('Claude 风格 mcpServers 包装', () {
      const json =
          '{"mcpServers": {"filesystem": {"url": "https://fs.example.com/mcp", "token": "abc"}, '
          '"weather": {"url": "https://w.example.com/mcp/"}}}';
      final servers = parseMcpServersJson(json);
      expect(servers.length, 2);
      expect(servers[0].name, 'filesystem');
      expect(servers[0].url, 'https://fs.example.com/mcp');
      expect(servers[0].token, 'abc');
      expect(servers[1].name, 'weather');
      // 尾部斜杠被清理
      expect(servers[1].url, 'https://w.example.com/mcp');
      expect(servers[1].token, '');
    });

    test('单服务器格式', () {
      const json = '{"name": "my-server", "url": "https://x.com/mcp", "token": "t"}';
      final servers = parseMcpServersJson(json);
      expect(servers.length, 1);
      expect(servers.first.name, 'my-server');
      expect(servers.first.url, 'https://x.com/mcp');
      expect(servers.first.token, 't');
    });

    test('数组格式', () {
      const json =
          '[{"name": "a", "url": "https://a.com/mcp"}, {"name": "b", "url": "https://b.com/mcp"}]';
      final servers = parseMcpServersJson(json);
      expect(servers.length, 2);
      expect(servers[1].name, 'b');
    });

    test('headers 里提取 Bearer token', () {
      const json =
          '{"mcpServers": {"s": {"url": "https://x.com/mcp", "headers": {"Authorization": "Bearer secret123"}}}}';
      final servers = parseMcpServersJson(json);
      expect(servers.length, 1);
      expect(servers.first.token, 'secret123');
    });

    test('无效 JSON 或缺少 url/command 返回空列表', () {
      expect(parseMcpServersJson('not json'), isEmpty);
      expect(parseMcpServersJson('{"name": "x"}'), isEmpty);
    });

    test('stdio 条目（command 无 url）被识别并标记', () {
      const json =
          '{"mcpServers": {"ddg-search": {"command": "npx", "args": ["-y", "duckduckgo-mcp-server"]}}}';
      final servers = parseMcpServersJson(json);
      expect(servers.length, 1);
      final s = servers.first;
      expect(s.name, 'ddg-search');
      expect(s.isStdio, true);
      expect(s.transport, 'stdio');
      expect(s.url, '');
      expect(s.command, ['npx', '-y', 'duckduckgo-mcp-server']);
    });

    test('stdio + http 混合配置', () {
      const json =
          '{"mcpServers": {"local": {"command": "npx", "args": ["-y", "x"]}, '
          '"remote": {"url": "https://r.com/mcp"}}}';
      final servers = parseMcpServersJson(json);
      expect(servers.length, 2);
      expect(servers[0].isStdio, true);
      expect(servers[1].isStdio, false);
      expect(servers[1].url, 'https://r.com/mcp');
    });

    test('批量导入 id 唯一', () {
      const json =
          '[{"name": "a", "url": "https://a.com/mcp"}, {"name": "b", "url": "https://b.com/mcp"}]';
      final servers = parseMcpServersJson(json);
      final ids = servers.map((s) => s.id).toSet();
      expect(ids.length, servers.length);
    });
  });
}

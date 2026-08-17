import 'package:flutter_test/flutter_test.dart';

import 'package:llm_ui/chat.dart';

void main() {
  group('Conversation 归档/锁定序列化', () {
    Conversation makeConv({bool archived = false, bool locked = false, DateTime? archivedAt}) =>
        Conversation(
          id: 'c1',
          title: '测试',
          messages: [],
          updatedAt: DateTime(2026, 1, 1),
          archived: archived,
          locked: locked,
          archivedAt: archivedAt,
        );

    test('toJson/fromJson 往返保持归档状态', () {
      final c = makeConv(
        archived: true,
        locked: true,
        archivedAt: DateTime(2026, 8, 1, 12, 30),
      );
      final decoded = Conversation.fromJson(c.toJson());
      expect(decoded.archived, true);
      expect(decoded.locked, true);
      expect(decoded.archivedAt, DateTime(2026, 8, 1, 12, 30));
    });

    test('普通对话往返', () {
      final c = makeConv();
      final decoded = Conversation.fromJson(c.toJson());
      expect(decoded.archived, false);
      expect(decoded.locked, false);
      expect(decoded.archivedAt, isNull);
    });

    test('旧数据缺字段兼容（默认非归档非锁定）', () {
      final json = {
        'id': 'c1',
        'title': '旧数据',
        'messages': <dynamic>[],
        'updatedAt': '2026-01-01T00:00:00.000',
      };
      final decoded = Conversation.fromJson(json);
      expect(decoded.archived, false);
      expect(decoded.locked, false);
      expect(decoded.archivedAt, isNull);
    });

    test('归档后从 JSON 保留 archivedAt 时间戳', () {
      final c = makeConv(archived: true, archivedAt: DateTime(2026, 8, 2));
      final raw = c.toJson();
      expect(raw['archived'], true);
      expect(raw['archivedAt'], isNotNull);
      expect(raw['locked'], false);
    });
  });
}

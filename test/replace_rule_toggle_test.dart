import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:llm_ui/chat.dart';
import 'package:llm_ui/main.dart';

void main() {
  group('TextReplaceRule 开关', () {
    test('禁用的规则不应用', () {
      final rules = [
        TextReplaceRule(display: '用户', model: 'user', enabled: false),
        TextReplaceRule(display: '助手', model: 'assistant'),
      ];
      expect(applyDisplayRules('user 说 assistant', rules), 'user 说 助手');
      expect(applyModelRules('用户 说 助手', rules), '用户 说 assistant');
    });

    test('序列化往返保留 enabled + 旧数据默认开启', () {
      final r = TextReplaceRule(display: 'a', model: 'b', enabled: false);
      final restored =
          TextReplaceRule.fromJson(jsonDecode(jsonEncode(r.toJson())));
      expect(restored.enabled, isFalse);

      final old = TextReplaceRule.fromJson({'display': 'x', 'model': 'y'});
      expect(old.enabled, isTrue);
    });
  });

  group('defaultContextWindowFor', () {
    test('DeepSeek 1M，其余 128k', () {
      expect(defaultContextWindowFor('deepseek-v4-flash'), 1048576);
      expect(defaultContextWindowFor('my-ds-model'), 1048576);
      expect(defaultContextWindowFor('gpt-4o'), 131072);
      expect(defaultContextWindowFor(''), 131072);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:llm_ui/main.dart';

void main() {
  group('estimateTokens', () {
    test('中文按 1 字/token', () {
      expect(estimateTokens('你好世界'), 4);
      expect(estimateTokens(''), 0);
    });

    test('英文按 4 字符/token', () {
      expect(estimateTokens('hello world'), 3); // 11 字符 → 2 + ceil(9/4)=3
      expect(estimateTokens('abcdefgh'), 2); // 8 字符 → 2
    });

    test('中英混合', () {
      // '你好 hello'：2 汉字 + 6 字符（含空格）→ 2 + ceil(6/4)=2 → 4
      expect(estimateTokens('你好 hello'), 4);
    });
  });

  group('formatTokenCount', () {
    test('k 格式化', () {
      expect(formatTokenCount(500), '500');
      expect(formatTokenCount(1234), '1.2k');
      expect(formatTokenCount(131072), '131.1k');
      expect(formatTokenCount(1048576), '1048.6k');
    });
  });
}

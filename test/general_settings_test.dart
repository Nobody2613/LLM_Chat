import 'package:flutter_test/flutter_test.dart';

import 'package:llm_ui/general_settings.dart';

void main() {
  group('GeneralSettings 序列化', () {
    test('defaults 编码后再解码应一致', () {
      const s = GeneralSettings.defaults;
      final decoded = GeneralSettings.decode(s.encode());
      expect(decoded.pasteLongTextAsFile, s.pasteLongTextAsFile);
      expect(decoded.pasteThreshold, s.pasteThreshold);
      expect(decoded.titleStrategy, s.titleStrategy);
      expect(decoded.aiTitleModel, s.aiTitleModel);
      expect(decoded.aiTitlePrompt, s.aiTitlePrompt);
      expect(decoded.markdownEnabled, s.markdownEnabled);
      expect(decoded.latexEnabled, s.latexEnabled);
      expect(decoded.mermaidEnabled, s.mermaidEnabled);
      expect(decoded.artifactsEnabled, s.artifactsEnabled);
    });

    test('修改字段后 encode/decode 往返保持新值', () {
      final s = GeneralSettings.defaults.copyWith(
        pasteThreshold: 500,
        titleStrategy: TitleStrategy.timestamp,
        markdownEnabled: false,
      );
      final decoded = GeneralSettings.decode(s.encode());
      expect(decoded.pasteThreshold, 500);
      expect(decoded.titleStrategy, TitleStrategy.timestamp);
      expect(decoded.markdownEnabled, false);
    });

    test('损坏的 JSON 字符串应回退到 defaults', () {
      final decoded = GeneralSettings.decode('not a json');
      expect(decoded.pasteThreshold, GeneralSettings.defaults.pasteThreshold);
      expect(decoded.titleStrategy, GeneralSettings.defaults.titleStrategy);
    });

    test('未知字段不影响反序列化（向前兼容）', () {
      final raw =
          '{"pasteThreshold": 8000, "unknownField": true, "latexEnabled": false}';
      final decoded = GeneralSettings.decode(raw);
      expect(decoded.pasteThreshold, 8000);
      expect(decoded.latexEnabled, false);
      // 缺字段用默认值
      expect(decoded.markdownEnabled, GeneralSettings.defaults.markdownEnabled);
    });

    test('TitleStrategy.label 三种都有中文标签', () {
      for (final s in TitleStrategy.values) {
        expect(s.label.isNotEmpty, true);
      }
      expect(TitleStrategy.timestamp.label, '时间戳');
      expect(TitleStrategy.firstLine.label, '第一句对话');
      expect(TitleStrategy.ai.label, 'AI 生成');
    });

    test('归档设置字段序列化往返', () {
      const s = GeneralSettings.defaults;
      expect(s.autoArchiveDays, 30);
      expect(s.autoDeleteDays, 90);
      final custom = s.copyWith(autoArchiveDays: 7, autoDeleteDays: 0);
      final decoded = GeneralSettings.decode(custom.encode());
      expect(decoded.autoArchiveDays, 7);
      expect(decoded.autoDeleteDays, 0);
    });

    test('旧 JSON 缺归档字段用默认值', () {
      final raw = '{"pasteThreshold": 100}';
      final decoded = GeneralSettings.decode(raw);
      expect(decoded.autoArchiveDays, GeneralSettings.defaults.autoArchiveDays);
      expect(decoded.autoDeleteDays, GeneralSettings.defaults.autoDeleteDays);
    });

    test('内置工具开关序列化往返', () {
      const s = GeneralSettings.defaults;
      expect(s.builtinToolsEnabled, true);
      final custom = s.copyWith(builtinToolsEnabled: false);
      expect(GeneralSettings.decode(custom.encode()).builtinToolsEnabled, false);
    });

    test('内置工具子开关序列化往返 + 默认全开', () {
      const s = GeneralSettings.defaults;
      expect(s.builtinTimeEnabled, true);
      expect(s.builtinLocationEnabled, true);
      expect(s.builtinSearchEnabled, true);
      final custom = s.copyWith(
        builtinTimeEnabled: false,
        builtinLocationEnabled: false,
        builtinSearchEnabled: false,
      );
      final decoded = GeneralSettings.decode(custom.encode());
      expect(decoded.builtinTimeEnabled, false);
      expect(decoded.builtinLocationEnabled, false);
      expect(decoded.builtinSearchEnabled, false);
      // 旧 JSON 缺字段 → 默认全开
      final legacy = GeneralSettings.decode('{"pasteThreshold": 100}');
      expect(legacy.builtinTimeEnabled, true);
      expect(legacy.builtinSearchEnabled, true);
    });

    test('PDF 解析为图像开关序列化往返 + 旧数据默认关闭', () {
      const s = GeneralSettings.defaults;
      expect(s.pdfAsImage, false); // 默认关闭
      final custom = s.copyWith(pdfAsImage: true);
      expect(GeneralSettings.decode(custom.encode()).pdfAsImage, true);
      // 旧 JSON 缺字段 → 默认 false
      final decoded = GeneralSettings.decode('{"pasteThreshold": 100}');
      expect(decoded.pdfAsImage, false);
    });
  });
}

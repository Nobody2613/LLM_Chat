import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llm_ui/markdown_view.dart';

void main() {
  testWidgets('MarkdownView 渲染标题/加粗', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MarkdownView(text: '# Title\n\n**bold** text'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Title'), findsOneWidget);
    // 加粗段落在 RichText 内，需 findRichText 匹配
    expect(find.textContaining('bold', findRichText: true), findsOneWidget);
  });
}

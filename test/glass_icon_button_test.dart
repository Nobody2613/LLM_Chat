import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:llm_ui/main.dart';

void main() {
  /// 波纹圆：按钮内唯一的圆形 Container
  Finder rippleCircle() => find.byWidgetPredicate(
        (w) =>
            w is Container &&
            (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
      );

  testWidgets('GlassIconButton 波纹：按下出现、动画结束消失、点击触发动作',
      (WidgetTester tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassIconButton(
              icon: Icons.add_comment_outlined,
              onTap: () => tapped++,
            ),
          ),
        ),
      ),
    );

    // 静止时无波纹残留
    expect(rippleCircle(), findsNothing);

    // 按下：波纹开始扩散（前 80ms 内可见）
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(GlassIconButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(rippleCircle(), findsOneWidget);

    // 动画结束后消失（不残留）
    await tester.pump(const Duration(milliseconds: 400));
    expect(rippleCircle(), findsNothing);

    // 抬手：动作已执行
    await gesture.up();
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('GlassIconButton 连续点击：波纹每次重新开始，动作每次触发',
      (WidgetTester tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassIconButton(
              icon: Icons.volume_up,
              onTap: () => tapped++,
            ),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(GlassIconButton));
    for (var i = 0; i < 3; i++) {
      final gesture = await tester.startGesture(center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      await gesture.up();
      await tester.pump();
      expect(tapped, i + 1, reason: '第 ${i + 1} 次点击应触发动作');
      // 动画播完后回到静止
      await tester.pump(const Duration(milliseconds: 400));
      expect(rippleCircle(), findsNothing, reason: '第 ${i + 1} 次点击后波纹应消失');
    }
  });
}

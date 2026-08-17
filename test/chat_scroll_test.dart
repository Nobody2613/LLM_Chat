// 验证 CustomScrollView(center 锚定) 方案的滚动语义：
// 1) 上翻后内容增长 → offset 保持（顶部锚定，文字不动）
// 2) 贴底（offset = max）内容增长 → offset 钉在新底部（底部生长）
// 3) 流式模拟：上翻后不被拉回底部
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llm_ui/main.dart';

Widget buildList(ChatScrollController controller, GlobalKey centerKey,
    int itemCount) {
  return MaterialApp(
    home: Scaffold(
      body: CustomScrollView(
        controller: controller,
        center: centerKey,
        slivers: [
          SliverPadding(key: centerKey, padding: EdgeInsets.zero),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => SizedBox(
                  height: 60,
                  child: Text('item $index'),
                ),
                childCount: itemCount,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('上翻后内容增长：offset 保持（顶部锚定，文字不动）', (tester) async {
    final controller = ChatScrollController();
    final centerKey = GlobalKey();
    var itemCount = 12; // 12×60+32+100=852 > 视口 600 → max=252
    await tester.pumpWidget(buildList(controller, centerKey, itemCount));
    await tester.pump();
    final pos = controller.position;

    // 上翻到 offset 80
    pos.jumpTo(80);
    await tester.pump();
    final before = pos.pixels;
    // ignore: avoid_print
    print('上翻后 pixels=$before max=${pos.maxScrollExtent}');

    // 内容增长：+5 个 item
    itemCount = 17;
    await tester.pumpWidget(buildList(controller, centerKey, itemCount));
    await tester.pump();
    // ignore: avoid_print
    print('增长后 pixels=${pos.pixels} max=${pos.maxScrollExtent}');
    // 顶部锚定：offset 保持 → 文字不动（无补偿）
    expect(pos.pixels, closeTo(before, 1), reason: '上翻时内容增长 offset 保持');
    controller.dispose();
  });

  testWidgets('贴底（offset=max）内容增长：钉在新底部（底部生长）', (tester) async {
    final controller = ChatScrollController();
    final centerKey = GlobalKey();
    var itemCount = 12;
    await tester.pumpWidget(buildList(controller, centerKey, itemCount));
    await tester.pump();
    final pos = controller.position;

    // 贴底
    pos.jumpTo(pos.maxScrollExtent);
    await tester.pump();
    final before = pos.pixels;
    // ignore: avoid_print
    print('贴底 pixels=$before max=${pos.maxScrollExtent}');

    itemCount = 17; // 内容增长
    await tester.pumpWidget(buildList(controller, centerKey, itemCount));
    await tester.pump();
    // ignore: avoid_print
    print('增长后 pixels=${pos.pixels} max=${pos.maxScrollExtent}');
    expect(pos.pixels, closeTo(pos.maxScrollExtent, 1),
        reason: '贴底时内容增长 offset 钉在新底部');
    expect(pos.pixels, greaterThan(before), reason: '底部生长（offset 增大）');
    controller.dispose();
  });

  testWidgets('流式模拟：上翻后内容持续增长不拉回底部', (tester) async {
    final controller = ChatScrollController();
    final centerKey = GlobalKey();
    var itemCount = 12;
    await tester.pumpWidget(buildList(controller, centerKey, itemCount));
    await tester.pump();
    final pos = controller.position;

    pos.jumpTo(100); // 上翻
    await tester.pump();
    final before = pos.pixels;
    // ignore: avoid_print
    print('上翻后 pixels=$before max=${pos.maxScrollExtent}');

    // 模拟流式：内容逐步增长 10 次
    for (var i = 0; i < 10; i++) {
      itemCount++;
      await tester.pumpWidget(buildList(controller, centerKey, itemCount));
      await tester.pump();
    }
    // ignore: avoid_print
    print('流式后 pixels=${pos.pixels} max=${pos.maxScrollExtent}');
    // 顶部锚定：offset 保持（不被拉回底部）
    expect(pos.pixels, closeTo(before, 1), reason: '上翻后流式增长不被拉回底部');
    controller.dispose();
  });

  testWidgets('内容不足时：锚点对齐视口顶（消息从顶部开始）', (tester) async {
    final controller = ChatScrollController();
    final centerKey = GlobalKey();
    await tester.pumpWidget(buildList(controller, centerKey, 3)); // 3×60=180 < 600
    await tester.pump();
    final pos = controller.position;
    // ignore: avoid_print
    print('内容少: pixels=${pos.pixels} max=${pos.maxScrollExtent}');
    // 锚点（消息列表顶部）在视口顶：offset 0 时首条消息顶部可见
    expect(pos.pixels, 0, reason: '内容少时 offset 0（顶部对齐）');
    expect(find.text('item 0'), findsOneWidget, reason: '首条消息可见（顶部开始）');
    controller.dispose();
  });
}

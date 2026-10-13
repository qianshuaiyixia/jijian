// 极简日记 · Phase 0 冒烟测试
// 目的：验证 App 能正常构建与渲染，后续 Phase 1 起逐步补充业务逻辑测试。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jijian/main.dart';

void main() {
  testWidgets('App 能渲染，且展示空状态', (WidgetTester tester) async {
    await tester.pumpWidget(const JiJianApp());

    // 标题与空状态提示
    expect(find.text('极简日记'), findsWidgets);
    expect(find.text('还没有日记'), findsOneWidget);

    // 新建按钮存在
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}

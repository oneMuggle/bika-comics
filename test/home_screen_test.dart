import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picacg_flutter/features/home/presentation/home_screen.dart';

ProviderScope _scope(Widget child) => ProviderScope(
      overrides: [
        homeCollectionsProvider.overrideWith((ref) async => []),
        homeRandomProvider.overrideWith((ref) async => []),
      ],
      child: child,
    );

void main() {
  testWidgets('HomeScreen 提供两个 TabController 页面且不触发断言', (tester) async {
    await tester.pumpWidget(
      _scope(const MaterialApp(home: HomeScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('推荐'), findsOneWidget);
    expect(find.text('随机'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HomeScreen 菜单按钮调用外层抽屉回调', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      _scope(
        MaterialApp(
          home: HomeScreen(onOpenDrawer: () => opened = true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    expect(opened, isTrue);
  });
}

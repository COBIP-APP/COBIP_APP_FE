import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('문법 홈에서 언어별 목록을 열고 필터 후 돌아온다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    appRouter.go('/grammar');
    await tester.pumpWidget(const CobipApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Python'));
    await tester.enterText(find.byType(TextField), 'elif');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('조건문'));
    await tester.tap(find.text('조건문'));
    await tester.pumpAndSettle();
    expect(find.text('Python 문법'), findsOneWidget);
    expect(find.text('반복문'), findsOneWidget);
    expect(find.text('변수와 자료형'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('기초'));
    await tester.pumpAndSettle();
    expect(find.text('변수와 자료형'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
    expect(find.text('반복문'), findsNothing);

    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(find.text('elif'), findsOneWidget);
    expect(find.text('Python 문법 챕터'), findsOneWidget);
    await tester.ensureVisible(find.text('전체 보기'));
    await tester.tap(find.text('전체 보기'));
    await tester.pumpAndSettle();
    expect(find.text('5개 챕터 · 예시 진행률'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('잘못된 언어는 복귀하고 잘못된 카테고리는 전체 목록을 표시한다', (tester) async {
    appRouter.go('/grammar/unknown/chapters');
    await tester.pumpWidget(const CobipApp());
    await tester.pumpAndSettle();
    expect(find.text('문법 학습'), findsOneWidget);

    appRouter.go('/grammar/java/chapters?category=unknown');
    await tester.pumpAndSettle();
    expect(find.text('Java 문법'), findsOneWidget);
    expect(find.text('6개 챕터 · 예시 진행률'), findsOneWidget);
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}

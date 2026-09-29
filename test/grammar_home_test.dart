import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('홈에서 문법으로 이동하고 검색과 언어 선택을 유지한다', (tester) async {
    appRouter.go('/home');
    await tester.pumpWidget(const CobipApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('문법'));
    await tester.pumpAndSettle();
    expect(find.text('문법 학습'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Python'));
    await tester.enterText(find.byType(TextField), 'elif');
    await tester.pumpAndSettle();
    expect(find.text('조건문'), findsOneWidget);
    expect(find.text('변수와 자료형'), findsNothing);

    await tester.tap(find.byTooltip('COBIP 챗봇'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('학습 계속하기'));
    await tester.pumpAndSettle();
    expect(find.text('elif'), findsOneWidget);
    expect(find.text('Python 문법 챕터'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '없는문법');
    await tester.pumpAndSettle();
    expect(find.textContaining('검색 결과가 없어요'), findsOneWidget);
    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pumpAndSettle();
    expect(find.text('변수와 자료형'), findsOneWidget);

    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}

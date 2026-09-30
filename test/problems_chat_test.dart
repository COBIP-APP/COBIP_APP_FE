import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/chat/presentation/chat_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(WidgetTester tester, String path) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    appRouter.go(path);
    await tester.pumpWidget(const CobipApp());
    await tester.pumpAndSettle();
  }

  testWidgets('답안 입력과 챗봇 대화 후 원래 문제로 복귀하고 결과를 확인한다', (tester) async {
    await open(tester, '/home');
    await tester.tap(find.text('문제'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
    await tester.tap(find.text('Java 기초 미션'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('problem-code')),
      'for demo',
    );
    final location = appRouter.routeInformationProvider.value.uri;
    await tester.tap(find.byTooltip('COBIP 챗봇'));
    await tester.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri, location);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == '메시지 보내기',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byKey(const ValueKey('chat-input')), '반복문 알려줘');
    await tester.pump();
    await tester.tap(find.byTooltip('메시지 보내기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('반복문은 같은 작업'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('chat-input')), '작성 중');
    await tester.tap(find.byTooltip('챗봇 닫기'));
    await tester.pumpAndSettle();
    expect(find.text('for demo'), findsOneWidget);
    await tester.tap(find.byTooltip('COBIP 챗봇'));
    await tester.pumpAndSettle();
    expect(find.text('작성 중'), findsOneWidget);
    expect(find.text('반복문 알려줘'), findsOneWidget);
    await tester.tap(find.text('학습 계속하기'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('free'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('free'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('problem-output')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(const ValueKey('problem-output')), '6');
    await tester.scrollUntilVisible(
      find.text('답안 확인하기'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('답안 확인하기'));
    await tester.pumpAndSettle();
    expect(find.text('자동 확인 2 / 2'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('문제 목록으로 돌아가기'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('문제 목록으로 돌아가기'));
    await tester.pumpAndSettle();
    expect(find.text('Java 기초 미션'), findsOneWidget);
    await tester.tap(find.text('챗봇'));
    await tester.pumpAndSettle();
    expect(find.text('반복문 알려줘'), findsOneWidget);
    await tester.tap(find.byTooltip('챗봇 닫기'));
    await tester.pumpAndSettle();
  });

  testWidgets('작은 화면과 키보드에서도 채팅 입력과 닫기가 가능하다', (tester) async {
    await open(tester, '/practical');
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.tap(find.text('챗봇'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.enterText(find.byKey(const ValueKey('chat-input')), '캐시');
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.tap(find.byTooltip('메시지 보내기'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(ChatPanel), findsOneWidget);
    await tester.tap(find.byTooltip('챗봇 닫기'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatPanel), findsNothing);
  });

  testWidgets('잘못된 미션 주소는 문제 목록으로 돌아간다', (tester) async {
    await open(tester, '/problems/missing');
    expect(find.text('Java 기초 미션'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}

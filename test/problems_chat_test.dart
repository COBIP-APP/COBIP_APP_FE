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

  testWidgets('오답만 초기화해 반복 재풀이하고 모두 맞으면 복귀만 제공한다', (tester) async {
    await open(tester, '/problems/java-basics');
    Future<void> reveal(Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    Future<void> submit() async {
      await reveal(find.text('답안 확인하기'));
      await tester.tap(find.text('답안 확인하기'));
      await tester.pumpAndSettle();
    }

    await tester.enterText(
      find.byKey(const ValueKey('problem-code')),
      'sample',
    );
    await reveal(find.text('public'));
    await tester.tap(find.text('public'));
    await reveal(find.byKey(const ValueKey('problem-output')));
    await tester.enterText(find.byKey(const ValueKey('problem-output')), '0');
    await submit();
    expect(find.text('자동 확인 0 / 2'), findsOneWidget);
    await reveal(find.text('다시 풀기'));
    expect(find.text('나가기'), findsOneWidget);
    await tester.tap(find.text('다시 풀기'));
    await tester.pumpAndSettle();
    expect(find.text('오답 다시 풀기'), findsOneWidget);
    expect(find.byKey(const ValueKey('problem-code')), findsNothing);
    expect(find.byIcon(Icons.radio_button_checked), findsNothing);
    await reveal(find.text('free'));
    await tester.tap(find.text('free'));
    await reveal(find.byKey(const ValueKey('problem-output')));
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('problem-output')))
          .controller!
          .text,
      isEmpty,
    );
    await tester.enterText(find.byKey(const ValueKey('problem-output')), '1');
    await submit();
    expect(find.text('자동 확인 1 / 2'), findsOneWidget);
    await reveal(find.text('다시 풀기'));
    await tester.tap(find.text('다시 풀기'));
    await tester.pumpAndSettle();
    expect(find.text('객관식'), findsNothing);
    await reveal(find.byKey(const ValueKey('problem-output')));
    await tester.enterText(find.byKey(const ValueKey('problem-output')), '6');
    await submit();
    expect(find.text('자동 확인 2 / 2'), findsOneWidget);
    await reveal(find.text('문제 목록으로 돌아가기'));
    expect(find.text('다시 풀기'), findsNothing);
    expect(find.text('나가기'), findsNothing);
    await tester.tap(find.text('문제 목록으로 돌아가기'));
    await tester.pumpAndSettle();
    expect(find.text('Java 기초 미션'), findsOneWidget);
  });

  testWidgets('잘못된 미션 주소는 문제 목록으로 돌아간다', (tester) async {
    await open(tester, '/problems/missing');
    expect(find.text('Java 기초 미션'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}

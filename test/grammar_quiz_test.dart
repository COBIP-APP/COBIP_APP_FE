import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('답 선택과 해설, 오답 채점, 결과 및 재시도가 동작한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    appRouter.go('/grammar/java/chapters/conditions/example');
    await tester.pumpWidget(const CobipApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음 예제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음 예제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('퀴즈 풀기'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '정답 제출'))
          .onPressed,
      isNull,
    );
    const answers = [1, 0, 0];
    for (var i = 0; i < answers.length; i++) {
      final answer = find.byKey(ValueKey('answer-${answers[i]}'));
      await tester.ensureVisible(answer);
      await tester.tap(answer);
      await tester.pumpAndSettle();
      if (i == 0) {
        await tester.tap(find.text('개념 다시 보기'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('이전'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, '정답 제출'))
              .onPressed,
          isNotNull,
        );
      }
      await tester.tap(find.text('정답 제출'));
      await tester.pumpAndSettle();
      expect(find.text(i == 1 ? '다시 확인해 보세요' : '정답이에요!'), findsOneWidget);
      // 제출 후 다른 보기를 눌러도 답과 점수는 바뀌지 않습니다.
      await tester.ensureVisible(find.byKey(const ValueKey('answer-3')));
      await tester.tap(find.byKey(const ValueKey('answer-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(i == 2 ? '결과 보기' : '다음 문제'));
      await tester.pumpAndSettle();
    }
    expect(find.text('67점'), findsOneWidget);
    expect(find.text('맞힌 문제 2'), findsOneWidget);
    expect(find.text('틀린 문제 1'), findsOneWidget);
    await tester.tap(find.text('다시 풀기'));
    await tester.pumpAndSettle();
    expect(find.text('문제 1 / 3'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '정답 제출'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(find.text('예제 3 / 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('좁은 화면과 큰 글자에서도 퀴즈 버튼과 선택지가 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    appRouter.go('/grammar/python/chapters/conditions/example/quiz');
    await tester.pumpWidget(const CobipApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('answer-1')));
    await tester.tap(find.byKey(const ValueKey('answer-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('정답 제출'));
    await tester.pumpAndSettle();
    expect(find.text('정답이에요!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

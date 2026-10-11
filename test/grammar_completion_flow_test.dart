import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/grammar/presentation/grammar_lesson_screen.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_preview_store.dart';
import 'package:cobip_app_fe/features/problems/presentation/question_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'auth_test_support.dart';

void main() {
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.dragUntilVisible(
      finder.hitTestable(),
      find.byType(ListView).last,
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('완료 저장 실패는 학습에 남고 성공 후에만 연결 문제를 순서대로 푼다', (tester) async {
    final router = createAppRouter(
      initialLocation: '/grammar/java/chapters/111?section=11105',
    );
    addTearDown(router.dispose);
    await tester.pumpLearningWidget(CobipApp(router: router));
    await tester.pumpAndSettle();
    final store = tester
        .element(find.byType(GrammarLessonScreen))
        .read<LearningPreviewStore>();
    expect(find.text(store.template(111)!.description), findsNothing);
    expect(find.text('문제 풀기'), findsNothing);
    await reveal(tester, find.text('학습 완료'));
    store.failNextAction = true;
    await tester.tap(find.text('학습 완료'));
    await tester.pumpAndSettle();
    expect(store.progress(111), isNull);
    expect(find.text('문제 풀기'), findsNothing);
    await reveal(tester, find.text('학습 완료'));
    await tester.tap(find.text('학습 완료'));
    await tester.pumpAndSettle();
    expect(find.text('학습을 마쳤어요'), findsOneWidget);
    expect(find.text('학습 목차'), findsNothing);
    await tester.tap(find.text('문제 풀기'));
    await tester.pumpAndSettle();
    for (final id in [1000, 1001, 1002]) {
      expect(
        tester
            .widget<QuestionPreviewScreen>(find.byType(QuestionPreviewScreen))
            .questionId,
        id,
      );
      await reveal(tester, find.byKey(const ValueKey('choice-A')));
      await tester.tap(find.byKey(const ValueKey('choice-A')));
      await reveal(tester, find.text('답안 제출'));
      await tester.tap(find.text('답안 제출'));
      await tester.pumpAndSettle();
      expect(store.latest(id), isNotNull);
      if (id != 1002) {
        await reveal(tester, find.text('다음 문제'));
        await tester.tap(find.text('다음 문제'));
        await tester.pumpAndSettle();
      }
    }
    expect(find.text('다음 문제'), findsNothing);
    await reveal(tester, find.text('학습으로 돌아가기'));
    await tester.tap(find.text('학습으로 돌아가기'));
    await tester.pumpAndSettle();
    expect(find.text('학습을 마쳤어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 640), const Size(640, 320)]) {
    testWidgets('목차 닫기는 위치를 보존하고 선택은 이동한다 $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final router = createAppRouter(
        initialLocation: '/grammar/java/chapters/111',
      );
      addTearDown(router.dispose);
      await tester.pumpLearningWidget(CobipApp(router: router));
      await tester.pumpAndSettle();
      final store = tester
          .element(find.byType(GrammarLessonScreen))
          .read<LearningPreviewStore>();
      await tester.tap(find.byTooltip('목차'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('목차 닫기'));
      await tester.pumpAndSettle();
      expect(store.progress(111), isNull);
      await tester.tap(find.byTooltip('목차'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const ValueKey('section-11105')));
      await tester.tap(find.byKey(const ValueKey('section-11105')));
      await tester.pumpAndSettle();
      expect(store.progress(111)!.lastSectionId, 11105);
      expect(find.text('학습 목차'), findsNothing);
      expect(find.text('5 / 5 목차'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('문제가 없는 학습도 완료할 수 있고 문제 버튼은 없다', (tester) async {
    final router = createAppRouter(
      initialLocation: '/grammar/java/chapters/110?section=11002',
    );
    addTearDown(router.dispose);
    await tester.pumpLearningWidget(CobipApp(router: router));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('학습 완료'));
    await tester.tap(find.text('학습 완료'));
    await tester.pumpAndSettle();
    expect(find.text('학습을 마쳤어요'), findsOneWidget);
    expect(find.text('문제 풀기'), findsNothing);
  });
}

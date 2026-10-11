import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/app/app_ui_tokens.dart';
import 'package:cobip_app_fe/app/widgets/learning_card.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_preview_widgets.dart';
import 'package:cobip_app_fe/features/grammar/presentation/grammar_lesson_screen.dart';
import 'package:cobip_app_fe/features/grammar/presentation/grammar_practice_screen.dart';
import 'package:cobip_app_fe/features/learning/data/learning_preview_data.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_preview_store.dart';
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

  testWidgets('본문만 읽거나 오답이 있으면 완료하지 않고 세 문제 결과를 함께 확인한다', (tester) async {
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
    await reveal(tester, find.text('본문 읽기 완료'));
    store.failNextAction = true;
    await tester.tap(find.text('본문 읽기 완료'));
    await tester.pumpAndSettle();
    expect(store.progress(111)!.completedAt, isNull);
    expect(find.text('문제 풀기'), findsNothing);
    await reveal(tester, find.text('본문 읽기 완료'));
    await tester.tap(find.text('본문 읽기 완료'));
    await tester.pumpAndSettle();
    expect(find.text('본문을 다 읽었어요'), findsOneWidget);
    expect(store.progress(111)!.completedAt, isNull);
    expect(find.text('학습 목차'), findsNothing);
    await tester.tap(find.text('문제 풀기'));
    await tester.pumpAndSettle();
    expect(find.byType(GrammarPracticeScreen), findsOneWidget);
    await reveal(tester, find.text('답 확인'));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '답 확인'))
          .onPressed,
      isNull,
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, 3000));
    await tester.pumpAndSettle();
    for (final id in [1000, 1001, 1002]) {
      final correctKey = previewAnswerKeys[id]!;
      final choice = id == 1001 ? (correctKey == 'A' ? 'B' : 'A') : correctKey;
      final option = find.byKey(ValueKey('choice-$id-$choice'));
      await reveal(tester, option);
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(store.latest(id), isNull);
    }
    await reveal(tester, find.text('답 확인'));
    store.failNextAction = true;
    await tester.tap(find.text('답 확인'));
    await tester.pumpAndSettle();
    expect(find.text('답안을 확인하지 못했어요. 선택한 답은 유지되니 다시 눌러 주세요.'), findsOneWidget);
    await reveal(tester, find.text('답 확인'));
    await tester.tap(find.text('답 확인'));
    await tester.pumpAndSettle();
    for (final id in [1000, 1001, 1002]) {
      expect(store.latest(id), isNotNull);
      final explanation = store.question(id)!.explanation!;
      expect(find.text(explanation), findsNothing);
      final result = find.byKey(ValueKey('result-$id'));
      await reveal(tester, result);
      expect(
        find.descendant(
          of: result,
          matching: find.text(id == 1001 ? '오답' : '정답'),
        ),
        findsOneWidget,
      );
      final decoration =
          tester.widget<Container>(result).decoration! as BoxDecoration;
      expect(
        (decoration.border! as Border).top.color,
        id == 1001 ? AppColors.error : AppColors.success,
      );
      final toggle = find.byKey(ValueKey('explanation-toggle-$id'));
      await reveal(tester, toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.text(explanation), findsOneWidget);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.text(explanation), findsNothing);
    }
    expect(find.text('학습 끝내기'), findsNothing);
    expect(store.progress(111)!.completedAt, isNull);
    expect(find.text('다음 문제'), findsNothing);
    await reveal(tester, find.text('다시 풀기'));
    await tester.tap(find.text('다시 풀기'));
    await tester.pumpAndSettle();
    expect(find.text('모든 문제를 풀고 한 번에 답을 확인해 보세요. (0 / 3)'), findsOneWidget);
    expect(find.text('풀이 보기'), findsNothing);
    await reveal(tester, find.text('학습으로 돌아가기'));
    await tester.tap(find.text('학습으로 돌아가기'));
    await tester.pumpAndSettle();
    expect(find.text('본문을 다 읽었어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final entry in {'java': 111, 'python': 121, 'javascript': 131}.entries) {
    testWidgets('${entry.key} 모두 정답이면 학습 끝내기로 해당 언어 목록에 돌아간다', (tester) async {
      final router = createAppRouter(
        initialLocation: '/grammar-practice/${entry.value}',
      );
      addTearDown(router.dispose);
      await tester.pumpLearningWidget(CobipApp(router: router));
      await tester.pumpAndSettle();
      final store = tester
          .element(find.byType(GrammarPracticeScreen))
          .read<LearningPreviewStore>();
      final questions = store.questions.where(
        (q) => q.relatedTemplateId == entry.value,
      );
      for (final question in questions) {
        final option = find.byKey(
          ValueKey('choice-${question.id}-${previewAnswerKeys[question.id]}'),
        );
        await reveal(tester, option);
        await tester.tap(option);
        await tester.pumpAndSettle();
      }
      await reveal(tester, find.text('답 확인'));
      await tester.tap(find.text('답 확인'));
      await tester.pumpAndSettle();
      expect(find.text('다시 풀기'), findsNothing);
      await reveal(tester, find.text('학습 끝내기'));
      if (entry.key == 'java') {
        store.failNextAction = true;
        await tester.tap(find.text('학습 끝내기'));
        await tester.pumpAndSettle();
        expect(find.byType(GrammarPracticeScreen), findsOneWidget);
        expect(store.progress(entry.value), isNull);
        expect(find.text('학습 완료를 저장하지 못했어요. 다시 눌러 주세요.'), findsOneWidget);
        await reveal(tester, find.text('학습 끝내기'));
      }
      await tester.tap(find.text('학습 끝내기'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/grammar/${entry.key}/chapters',
      );
      expect(find.byType(GrammarPracticeScreen), findsNothing);
      expect(find.text('문법 챕터'), findsOneWidget);
      expect(store.progress(entry.value)!.completedAt, isNotNull);
      await reveal(tester, find.textContaining('학습 완료 · 복습하기'));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      final card = find.byWidgetPredicate(
        (w) => w is TemplatePreviewCard && w.item.id == entry.value,
      );
      expect(
        tester
            .widget<LearningCard>(
              find.descendant(of: card, matching: find.byType(LearningCard)),
            )
            .backgroundColor,
        AppColors.completedSurface,
      );
      if (entry.key == 'java') {
        await tester.tap(find.text('조건문'));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('다시 학습하기'));
        await tester.tap(find.text('다시 학습하기'));
        await tester.pumpAndSettle();
        expect(store.progress(entry.value)!.completedAt, isNull);
        expect(store.progress(entry.value)!.lastSectionId, 11101);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('예제 부모 목차는 하위 예제를 보여주고 선택하면 이동한다', (tester) async {
    final router = createAppRouter(
      initialLocation: '/grammar/java/chapters/111?section=11102',
    );
    addTearDown(router.dispose);
    await tester.pumpLearningWidget(CobipApp(router: router));
    await tester.pumpAndSettle();
    expect(find.text('예제 목차'), findsOneWidget);
    for (final id in [11103, 11104, 11105]) {
      await reveal(tester, find.byKey(ValueKey('example-$id')));
    }
    await tester.tap(find.byKey(const ValueKey('example-11105')));
    await tester.pumpAndSettle();
    expect(find.text('5 / 5 목차'), findsOneWidget);
    expect(
      tester
          .element(find.byType(GrammarLessonScreen))
          .read<LearningPreviewStore>()
          .progress(111)!
          .lastSectionId,
      11105,
    );
  });

  for (final size in [const Size(320, 640), const Size(640, 320)]) {
    testWidgets('함께 푸는 문제의 큰 글씨 배치 $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final router = createAppRouter(initialLocation: '/grammar-practice/111');
      addTearDown(router.dispose);
      await tester.pumpLearningWidget(CobipApp(router: router));
      await tester.pumpAndSettle();
      for (final id in [1000, 1001, 1002]) {
        final option = find.byKey(ValueKey('choice-$id-A'));
        await reveal(tester, option);
        await tester.tap(option);
        await tester.pumpAndSettle();
      }
      await reveal(tester, find.text('답 확인'));
      await tester.tap(find.text('답 확인'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const ValueKey('result-1002')));
      final toggle = find.byKey(const ValueKey('explanation-toggle-1002'));
      await reveal(tester, toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await reveal(tester, find.text('풀이 접기'));
      expect(tester.takeException(), isNull);
    });
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
      expect(store.progress(111)!.lastSectionId, 11101);
      expect(store.progress(111)!.completedAt, isNull);
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

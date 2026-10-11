import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/learning/data/learning_preview_data.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_preview_store.dart';
import 'package:cobip_app_fe/features/problems/presentation/question_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'auth_test_support.dart';

void main() {
  Future<void> open(WidgetTester tester, String path) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = createAppRouter(initialLocation: path);
    addTearDown(router.dispose);
    await tester.pumpLearningWidget(CobipApp(router: router));
    await tester.pumpAndSettle();
  }

  Future<void> reveal(
    WidgetTester tester,
    Finder finder, {
    bool up = false,
  }) async {
    await tester.dragUntilVisible(
      finder.hitTestable(),
      find.byType(ListView).first,
      Offset(0, up ? 200 : -200),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('객관식은 한 문제씩 채점하고 최근 제출 결과를 다시 보여준다', (tester) async {
    await open(tester, '/problems/2001');
    final store = tester
        .element(find.byType(QuestionPreviewScreen))
        .read<LearningPreviewStore>();
    await reveal(tester, find.text('답안 제출'));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '답안 제출'))
          .onPressed,
      isNull,
    );
    final key = previewAnswerKeys[2001]!;
    await reveal(tester, find.byKey(ValueKey('choice-$key')), up: true);
    await tester.tap(find.byKey(ValueKey('choice-$key')));
    await reveal(tester, find.text('답안 제출'));
    await tester.tap(find.text('답안 제출'));
    await tester.pumpAndSettle();
    expect(store.latest(2001)!.score, 100);
    expect(find.text('채점 완료'), findsOneWidget);
    await reveal(tester, find.text('다시 풀기'));
    await tester.tap(find.text('다시 풀기'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('최근 제출 결과 보기'));
    await tester.tap(find.text('최근 제출 결과 보기'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('채점 완료'), up: true);
    expect(store.latest(2001)!.score, 100);
    expect(tester.takeException(), isNull);
  });

  for (final id in [2000, 2002]) {
    testWidgets('$id 서술·코드 답안은 실패 시 유지되고 제출하면 채점 대기다', (tester) async {
      await open(tester, '/problems/$id');
      final store = tester
          .element(find.byType(QuestionPreviewScreen))
          .read<LearningPreviewStore>();
      final field = find.byKey(const ValueKey('question-answer'));
      await reveal(tester, field);
      await tester.enterText(field, '직접 작성한 답안');
      tester.testTextInput.hide();
      await reveal(tester, find.text('답안 제출'));
      store.failNextAction = true;
      await tester.tap(find.text('답안 제출'));
      await tester.pumpAndSettle();
      expect(store.latest(id), isNull);
      expect(find.textContaining('답안을 제출하지 못했어요'), findsOneWidget);
      expect(tester.widget<TextField>(field).controller!.text, '직접 작성한 답안');
      await reveal(tester, find.text('답안 제출'));
      await tester.tap(find.text('답안 제출'));
      await tester.pumpAndSettle();
      expect(store.latest(id)!.pending, isTrue);
      expect(store.latest(id)!.score, isNull);
      expect(find.text('채점 대기'), findsOneWidget);
      expect(find.text('0점'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('문법 문제에서 연결된 학습 목차로 돌아간다', (tester) async {
    await open(tester, '/problems/1000');
    await reveal(tester, find.text('관련 학습 · 조건문'));
    await tester.tap(find.text('관련 학습 · 조건문'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('목차'));
    await tester.pumpAndSettle();
    final tile = tester.widget<ListTile>(
      find.byKey(const ValueKey('section-11103')),
    );
    expect(tile.selected, isTrue);
    expect(tester.takeException(), isNull);
  });
}

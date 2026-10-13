import 'preview_learning_store.dart';

import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/app/app_ui_tokens.dart';
import 'package:cobip_app_fe/app/widgets/learning_card.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_preview_widgets.dart';

import 'fixtures/learning_preview_data.dart';

import 'package:cobip_app_fe/features/learning/presentation/learning_store.dart';
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

  Future<void> reopen(WidgetTester tester, int id, Color background) async {
    await reveal(tester, find.text('목록으로 돌아가기'));
    await tester.tap(find.text('목록으로 돌아가기'));
    await tester.pumpAndSettle();
    final card = find.byWidgetPredicate(
      (w) => w is QuestionPreviewCard && w.item.id == id,
    );
    await reveal(tester, card);
    expect(
      tester
          .widget<LearningCard>(
            find.descendant(of: card, matching: find.byType(LearningCard)),
          )
          .backgroundColor,
      background,
    );
    final question = tester.widget<QuestionPreviewCard>(card).item;
    await tester.tap(
      find.descendant(of: card, matching: find.text(question.prompt)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('result-$id')), findsNothing);
    expect(find.text('풀이 보기'), findsNothing);
  }

  testWidgets('객관식은 한 문제씩 채점하고 최근 제출 결과를 다시 보여준다', (tester) async {
    await open(tester, '/problems/2001');
    final store = tester
        .element(find.byType(QuestionPreviewScreen))
        .read<LearningStore>();
    await reveal(tester, find.text('답 확인'));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '답 확인'))
          .onPressed,
      isNull,
    );
    final key = previewAnswerKeys[2001] == 'A' ? 'B' : 'A';
    await reveal(tester, find.byKey(ValueKey('choice-2001-$key')), up: true);
    await tester.tap(find.byKey(ValueKey('choice-2001-$key')));
    await reveal(tester, find.text('답 확인'));
    await tester.tap(find.text('답 확인'));
    await tester.pumpAndSettle();
    expect(store.latest(2001)!.score, 0);
    expect(find.text('오답'), findsOneWidget);
    final explanation = store.question(2001)!.explanation!;
    expect(find.text(explanation), findsNothing);
    await reveal(tester, find.text('풀이 보기'));
    await tester.tap(find.text('풀이 보기'));
    await tester.pumpAndSettle();
    expect(find.text(explanation), findsOneWidget);
    await reveal(tester, find.text('다시 풀기'));
    await tester.tap(find.text('다시 풀기'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('최근 제출 결과 보기'));
    await tester.tap(find.text('최근 제출 결과 보기'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('오답'), up: true);
    expect(store.latest(2001)!.score, 0);
    await reopen(tester, 2001, AppColors.inProgressSurface);
    await reveal(tester, find.text('답 확인'));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '답 확인'))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('정답은 초록 결과를 표시하고 문제 끝내기로 목록에 돌아간다', (tester) async {
    await open(tester, '/problems/2001');
    final option = find.byKey(
      ValueKey('choice-2001-${previewAnswerKeys[2001]}'),
    );
    await reveal(tester, option);
    await tester.tap(option);
    await reveal(tester, find.text('답 확인'));
    await tester.tap(find.text('답 확인'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('정답'));
    expect(find.text('오답'), findsNothing);
    expect(find.text('풀이 접기'), findsNothing);
    await reveal(tester, find.text('문제 끝내기'));
    await tester.tap(find.text('문제 끝내기'));
    await tester.pumpAndSettle();
    expect(find.byType(QuestionPreviewScreen), findsNothing);
    final card = find.byWidgetPredicate(
      (w) => w is QuestionPreviewCard && w.item.id == 2001,
    );
    await reveal(tester, card);
    expect(
      tester
          .widget<LearningCard>(
            find.descendant(of: card, matching: find.byType(LearningCard)),
          )
          .backgroundColor,
      AppColors.completedSurface,
    );
    await tester.tap(
      find.text(tester.widget<QuestionPreviewCard>(card).item.prompt),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('result-2001')), findsNothing);
    await reveal(tester, find.text('답 확인'));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '답 확인'))
          .onPressed,
      isNull,
    );
  });

  for (final id in [2000, 2002]) {
    testWidgets('$id 서술·코드 답안은 실패 시 유지되고 제출하면 채점 대기다', (tester) async {
      await open(tester, '/problems/$id');
      final store = tester
          .element(find.byType(QuestionPreviewScreen))
          .read<LearningStore>();
      final field = find.byKey(ValueKey('answer-$id'));
      await reveal(tester, field);
      await tester.enterText(field, '직접 작성한 답안');
      tester.testTextInput.hide();
      await reveal(tester, find.text('답안 제출'));
      (store as PreviewLearningStore).failNextAction = true;
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
      await reopen(tester, id, AppColors.inProgressSurface);
      await reveal(tester, field);
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
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

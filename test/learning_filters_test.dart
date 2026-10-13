import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/app/widgets/progressive_card_list.dart';
import 'package:cobip_app_fe/features/learning/data/learning_api.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_store.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_preview_widgets.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';
import 'learning_test_support.dart';

void main() {
  testWidgets('문제에 있는 언어만 표시하고 새 AI 언어와 언어 공통을 필터링한다', (tester) async {
    final server = LearningServer();
    final own = standaloneQuestion(41)
      ..addAll({
        'id': 503,
        'createdBy': 1,
        'published': false,
        'languageId': 303,
        'languageCode': 'RUST',
        'languageName': 'Rust',
      });
    server.handle = (r) async {
      if (r.path == '/api/languages') {
        return jsonResponse([
          {'id': 101, 'code': 'JAVA', 'name': 'Java'},
          {'id': 202, 'code': 'PYTHON', 'name': 'Python'},
        ], 200);
      }
      if (r.path == '/api/questions') {
        return jsonResponse([
          standaloneQuestion(41),
          standaloneQuestion(41)..addAll({'id': 502, 'languageId': null}),
          // Languages used only by chapter questions do not enter this filter.
          serverQuestion(41)
            ..addAll({'id': 504, 'languageId': 202, 'categoryId': 201}),
          // Even CODING_PROBLEM questions belong to learning when linked.
          serverQuestion(41)..addAll({'id': 505, 'languageId': 202}),
        ], 200);
      }
      if (r.path == '/api/users/me/questions') {
        return jsonResponse([
          own,
          for (final (id, topic) in [(506, 'AWS'), (507, ' aws ')])
            standaloneQuestion(41)..addAll({
              'id': id,
              'createdBy': 1,
              'published': false,
              'languageId': null,
              'generationTopic': topic,
            }),
        ], 200);
      }
      return server.respond(r);
    };
    final auth = (await tester.runAsync(
      () => testAuth(authenticated: true, adapter: server),
    ))!;
    addTearDown(auth.dispose);
    final store = LearningStore(api: LearningApi(auth.api.dio));
    final router = createAppRouter(initialLocation: '/problems');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(
      CobipApp(router: router, learningStore: store),
      auth: auth,
    );
    await tester.pumpAndSettle();

    Future<void> filter() async {
      await tester.tap(find.byTooltip('필터'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ChoiceChip, 'Java'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Rust'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '언어 공통'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'AWS'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'aws'), findsNothing);
      expect(find.widgetWithText(ChoiceChip, 'Python'), findsNothing);
    }

    await filter();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Rust'));
    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();
    final rustCards = tester
        .widget<ProgressiveCardList>(find.byType(ProgressiveCardList))
        .items
        .cast<QuestionPreviewCard>();
    expect(rustCards.single.item.id, 503);
    expect(find.text('Rust · 전체 유형'), findsOneWidget);

    await filter();
    await tester.tap(find.widgetWithText(ChoiceChip, '언어 공통'));
    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();
    final commonCards = tester
        .widget<ProgressiveCardList>(find.byType(ProgressiveCardList))
        .items
        .cast<QuestionPreviewCard>();
    expect(commonCards.single.item.id, 502);
    expect(find.text('언어 공통 · 전체 유형'), findsOneWidget);

    await filter();
    await tester.tap(find.widgetWithText(ChoiceChip, 'AWS'));
    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();
    final topicCards = tester
        .widget<ProgressiveCardList>(find.byType(ProgressiveCardList))
        .items
        .cast<QuestionPreviewCard>();
    expect(topicCards.map((card) => card.item.id), unorderedEquals([506, 507]));
    expect(find.text('AWS · 전체 유형'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('필터는 적용할 때 반영하고 닫기는 취소하며 초기화로 복구한다', (tester) async {
    final router = createAppRouter(initialLocation: '/problems');
    addTearDown(router.dispose);
    await tester.pumpLearningWidget(CobipApp(router: router));
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceChip), findsNothing);
    await tester.enterText(find.byType(TextField), '출력');
    await tester.tap(find.byTooltip('필터'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Python'));
    await tester.tap(find.byTooltip('필터 닫기'));
    await tester.pumpAndSettle();
    expect(find.text('전체 언어 · 전체 유형'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '출력',
    );
    await tester.tap(find.byTooltip('필터'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Python'));
    await tester.dragUntilVisible(
      find.widgetWithText(ChoiceChip, '코드 설명').hitTestable(),
      find.byType(ListView).last,
      const Offset(0, -100),
    );
    await tester.tap(find.widgetWithText(ChoiceChip, '코드 설명'));
    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(LearningListToolbar),
        matching: find.text('Python · 코드 설명'),
      ),
      findsOneWidget,
    );
    expect(find.byType(ChoiceChip), findsNothing);
    await tester.dragUntilVisible(
      find.byType(QuestionPreviewCard).hitTestable(),
      find.byType(ListView),
      const Offset(0, -150),
    );
    final card = tester.widget<QuestionPreviewCard>(
      find.byType(QuestionPreviewCard),
    );
    expect(card.item.languageId, 2);
    await tester.dragUntilVisible(
      find.byTooltip('필터').hitTestable(),
      find.byType(ListView),
      const Offset(0, 150),
    );
    await tester.tap(find.byTooltip('필터'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('초기화'));
    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();
    expect(find.text('전체 언어 · 전체 유형'), findsOneWidget);
  });

  for (final size in [const Size(320, 640), const Size(640, 320)]) {
    testWidgets('큰 글씨와 작은 화면에서도 필터 선택 및 적용 가능 $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final router = createAppRouter(initialLocation: '/problems');
      addTearDown(router.dispose);
      await tester.pumpLearningWidget(CobipApp(router: router));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.byTooltip('필터').hitTestable(),
        find.byType(ListView),
        const Offset(0, -150),
      );
      await tester.tap(find.byTooltip('필터'));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('제출한 문제만 보기').hitTestable(),
        find.byType(ListView).last,
        const Offset(0, -100),
      );
      await tester.tap(find.text('제출한 문제만 보기'));
      await tester.tap(find.text('적용'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('조건에 맞는 문제가 없어요'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('조건에 맞는 문제가 없어요'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

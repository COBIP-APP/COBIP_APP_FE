import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_preview_widgets.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';

void main() {
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
      expect(find.textContaining('조건에 맞는 문제가 없어요'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

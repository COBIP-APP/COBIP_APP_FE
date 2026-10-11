import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_preview_store.dart';
import 'package:cobip_app_fe/features/learning/presentation/template_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'auth_test_support.dart';

void main() {
  testWidgets('실무 분류와 검색에서 학습 목차로 이동하고 위치를 저장한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = createAppRouter(initialLocation: '/practical');
    addTearDown(router.dispose);
    await tester.pumpLearningWidget(CobipApp(router: router));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    await tester.dragUntilVisible(
      find.byTooltip('필터').hitTestable(),
      find.byType(ListView),
      const Offset(0, -150),
    );
    await tester.tap(find.byTooltip('필터'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'DB'));
    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();
    final store = tester
        .element(find.byType(NavigationBar))
        .read<LearningPreviewStore>();
    final database = store.template(202)!;
    await tester.dragUntilVisible(
      find.text(database.title).hitTestable(),
      find.byType(ListView),
      const Offset(0, -150),
    );
    await tester.tap(find.text(database.title));
    await tester.pumpAndSettle();
    expect(find.text('언어 공통'), findsOneWidget);
    expect(find.text('학습 목차'), findsOneWidget);
    await tester.dragUntilVisible(
      find
          .byKey(ValueKey('section-${database.allSections.last.id}'))
          .hitTestable(),
      find.byType(ListView),
      const Offset(0, -150),
    );
    await tester.tap(
      find.byKey(ValueKey('section-${database.allSections.last.id}')),
    );
    await tester.pumpAndSettle();
    expect(store.progress(202)!.lastSectionId, database.allSections.last.id);
    await tester.tap(find.byTooltip('북마크 저장'));
    await tester.pumpAndSettle();
    expect(store.bookmarked(202), isTrue);
    expect(find.byType(TemplatePreviewScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('검색 결과가 없을 때 지우면 목록을 복구한다', (tester) async {
    final router = createAppRouter(initialLocation: '/practical');
    addTearDown(router.dispose);
    await tester.pumpLearningWidget(CobipApp(router: router));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '존재하지않는주제');
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.textContaining('검색 결과가 없어요').hitTestable(),
      find.byType(ListView),
      const Offset(0, -150),
    );
    expect(find.textContaining('검색 결과가 없어요'), findsOneWidget);
    await tester.dragUntilVisible(
      find.byTooltip('검색어 지우기').hitTestable(),
      find.byType(ListView),
      const Offset(0, 150),
    );
    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('검색 결과가 없어요'), findsNothing);
  });
}

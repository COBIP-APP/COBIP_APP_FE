import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_preview_store.dart';
import 'package:cobip_app_fe/features/grammar/presentation/grammar_lesson_screen.dart';
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

  testWidgets('하위 목차 저장, 완료, 재진입 이어하기와 다시 학습', (tester) async {
    await open(tester, '/grammar/java/chapters/111');
    final store = tester
        .element(find.byType(GrammarLessonScreen))
        .read<LearningPreviewStore>();
    expect(store.progress(111), isNull);
    expect(find.text('학습 목차'), findsNothing);
    expect(find.text('연결된 문제'), findsNothing);
    await tester.tap(find.byTooltip('목차'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('section-11105')).hitTestable(),
      find.byType(ListView).last,
      const Offset(0, -200),
    );
    await tester.tap(find.byKey(const ValueKey('section-11105')));
    await tester.pumpAndSettle();
    expect(store.progress(111)!.lastSectionId, 11105);
    await tester.dragUntilVisible(
      find.text('학습 완료').hitTestable(),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await tester.tap(find.text('학습 완료'));
    await tester.pumpAndSettle();
    expect(store.progress(111)!.label, '완료');
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('조건문').hitTestable(),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    expect(find.textContaining('학습 완료 · 복습하기'), findsOneWidget);
    await tester.tap(find.text('조건문'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('다시 학습하기').hitTestable(),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await tester.tap(find.text('다시 학습하기'));
    await tester.pumpAndSettle();
    expect(store.progress(111)!.label, '학습 중');
    expect(store.progress(111)!.lastSectionId, 11101);
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('학습 완료 · 복습하기'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('북마크가 목록 필터에 반영되고 빈 목차는 완료할 수 없다', (tester) async {
    await open(tester, '/grammar/java/chapters/112');
    expect(find.text('아직 등록된 목차가 없어요.'), findsOneWidget);
    expect(find.text('학습 완료'), findsNothing);
    await tester.tap(find.byTooltip('북마크 저장'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byTooltip('필터').hitTestable(),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await tester.tap(find.byTooltip('필터'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('북마크만 보기'));
    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('반복문').hitTestable(),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    expect(find.text('조건문'), findsNothing);
    expect(find.text('반복문'), findsOneWidget);
  });

  testWidgets('존재하지 않는 학습은 안내를 보여준다', (tester) async {
    await open(tester, '/grammar/java/chapters/99999');
    expect(find.textContaining('학습을 찾을 수 없어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

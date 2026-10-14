import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_store.dart';
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

  testWidgets('첫 본문에서 진도를 저장하고 다음·이전 이동만으로 완료하지 않는다', (tester) async {
    await open(tester, '/grammar/java/chapters/111');
    final store = tester
        .element(find.byType(GrammarLessonScreen))
        .read<LearningStore>();
    expect(find.text('학습 목차'), findsNothing);
    expect(store.progress(111)!.lastSectionId, 11101);
    expect(store.progress(111)!.completedAt, isNull);
    await tester.dragUntilVisible(
      find.text('다음').hitTestable(),
      find.byType(ListView).last,
      const Offset(0, -200),
    );
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(store.progress(111)!.completedAt, isNull);
    await tester.dragUntilVisible(
      find.text('이전').hitTestable(),
      find.byType(ListView).last,
      const Offset(0, -200),
    );
    await tester.tap(find.text('이전'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 5 목차'), findsOneWidget);
    expect(store.progress(111)!.lastSectionId, 11101);
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

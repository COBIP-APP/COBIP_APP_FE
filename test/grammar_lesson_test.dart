import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/grammar/data/grammar_sample_data.dart';
import 'package:cobip_app_fe/features/grammar/presentation/lesson_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';

void main() {
  for (final language in GrammarLanguage.values) {
    testWidgets('${language.label} 조건문 개념과 예제 이동 및 전체 목록 복귀', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      appRouter.go('/grammar/${language.id}/chapters?category=control');
      await tester.pumpLearningWidget(const CobipApp());
      await tester.pumpAndSettle();
      expect(find.text('개념 학습하기 ›'), findsOneWidget);
      await tester.tap(find.text('조건문'));
      await tester.pumpAndSettle();
      expect(find.text('핵심 개념'), findsOneWidget);
      expect(find.text('${language.label} · 제어문 · 조건문'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await tester.tap(find.text('예제 보기'));
      await tester.pumpAndSettle();
      expect(find.text('예제 코드'), findsOneWidget);
      final code = tester.widget<LessonCode>(find.byType(LessonCode)).code;
      expect(
        code,
        contains(switch (language) {
          GrammarLanguage.java => 'System.out.println',
          GrammarLanguage.python => 'if score',
          GrammarLanguage.javascript => 'console.log',
        }),
      );
      await tester.tap(find.text('다음 예제'));
      await tester.pumpAndSettle();
      expect(find.text('예제 2 / 3'), findsOneWidget);
      await tester.tap(find.text('다음 예제'));
      await tester.pumpAndSettle();
      expect(find.text('예제 3 / 3'), findsOneWidget);
      expect(find.text('퀴즈 풀기'), findsOneWidget);
      await tester.tap(find.byTooltip('COBIA 챗봇'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('학습 계속하기'));
      await tester.pumpAndSettle();
      expect(find.text('예제 코드'), findsOneWidget);
      await tester.tap(find.text('예제 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('개념 다시 보기'));
      await tester.pumpAndSettle();
      expect(find.text('핵심 개념'), findsOneWidget);
      await tester.tap(find.text('이전'));
      await tester.pumpAndSettle();
      expect(
        find.text('${grammarSampleChapters[language]!.length}개 챕터 · 예시 진행률'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('예제 직접 진입도 개념으로 복귀하고 잘못된 언어는 문법 홈으로 이동한다', (tester) async {
    appRouter.go('/grammar/python/chapters/conditions/example');
    await tester.pumpLearningWidget(const CobipApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('개념 다시 보기'));
    await tester.pumpAndSettle();
    expect(find.text('핵심 개념'), findsOneWidget);
    appRouter.go('/grammar/unknown/chapters/conditions/example');
    await tester.pumpAndSettle();
    expect(find.text('문법 학습'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

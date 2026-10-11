import 'package:cobip_app_fe/features/grammar/presentation/grammar_lesson_screen.dart';
import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';

void main() {
  for (final entry in [
    ('java', 'Java', 110),
    ('python', 'Python', 120),
    ('javascript', 'JavaScript', 130),
  ]) {
    for (final systemBack in [false, true]) {
      testWidgets('${entry.$2} 변수 학습은 데이터 ID로 열리고 목록으로 복귀한다 $systemBack', (
        tester,
      ) async {
        final router = createAppRouter(
          initialLocation: '/grammar/${entry.$1}/chapters',
        );
        addTearDown(router.dispose);
        await tester.pumpLearningWidget(CobipApp(router: router));
        await tester.pumpAndSettle();
        await tester.dragUntilVisible(
          find.text('변수와 자료형').hitTestable(),
          find.byType(ListView),
          const Offset(0, -150),
        );
        await tester.tap(find.text('변수와 자료형'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<GrammarLessonScreen>(find.byType(GrammarLessonScreen))
              .templateId,
          entry.$3,
        );
        expect(find.byTooltip('목차'), findsOneWidget);
        expect(find.text('학습 목차'), findsNothing);
        if (systemBack) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(find.byTooltip('뒤로가기'));
        }
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          '/grammar/${entry.$1}/chapters',
        );
        expect(find.text('${entry.$2} 문법'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_preview_store.dart';
import 'package:cobip_app_fe/features/problems/presentation/question_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'auth_test_support.dart';

void main() {
  testWidgets('문제 풀이에서 챗봇 없이 답안을 작성한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = createAppRouter(initialLocation: '/problems/2000');
    addTearDown(router.dispose);
    await tester.pumpLearningWidget(CobipApp(router: router));
    await tester.pumpAndSettle();
    final answer = find.byKey(const ValueKey('answer-2000'));
    await tester.dragUntilVisible(
      answer.hitTestable(),
      find.byType(ListView),
      const Offset(0, -150),
    );
    await tester.enterText(answer, 'for (int i = 1; i <= 5; i++) {}');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    expect(find.byTooltip('COBIA 챗봇'), findsNothing);
    expect(
      tester.widget<TextField>(answer).controller!.text,
      'for (int i = 1; i <= 5; i++) {}',
    );
    expect(router.routeInformationProvider.value.uri.path, '/problems/2000');
    final store = tester
        .element(find.byType(QuestionPreviewScreen))
        .read<LearningPreviewStore>();
    expect(store.latest(2000), isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('잘못된 문제 ID는 안내를 표시한다', (tester) async {
    final router = createAppRouter(initialLocation: '/problems/missing');
    addTearDown(router.dispose);
    await tester.pumpLearningWidget(CobipApp(router: router));
    await tester.pumpAndSettle();
    expect(find.textContaining('문제를 찾을 수 없어요'), findsOneWidget);
  });
}

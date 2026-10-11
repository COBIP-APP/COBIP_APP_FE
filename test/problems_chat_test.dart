import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/chat/presentation/chat_panel.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_preview_store.dart';
import 'package:cobip_app_fe/features/problems/presentation/question_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'auth_test_support.dart';

void main() {
  testWidgets('챗봇을 열고 닫아도 문제 답안과 대화 내용을 유지한다', (tester) async {
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
    await tester.tap(find.byTooltip('COBIA 챗봇'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('chat-input')), '반복문 알려줘');
    await tester.pump();
    await tester.tap(find.byTooltip('메시지 보내기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('반복문은 같은 작업'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('chat-input')), '작성 중');
    await tester.tap(find.byTooltip('챗봇 닫기'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(answer).controller!.text,
      'for (int i = 1; i <= 5; i++) {}',
    );
    await tester.tap(find.byTooltip('COBIA 챗봇'));
    await tester.pumpAndSettle();
    expect(find.text('작성 중'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/problems/2000');
    await tester.tap(find.text('학습 계속하기'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatPanel), findsNothing);
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

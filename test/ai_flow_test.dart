import 'dart:async';

import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/learning/data/learning_api.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_store.dart';
import 'package:cobip_app_fe/features/problems/presentation/ai_quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'ai_test_support.dart';
import 'auth_test_support.dart';

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.dragUntilVisible(
    target.hitTestable(),
    find.byType(ListView).first,
    const Offset(0, -140),
  );
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('목록에서 생성 페이지로 이동하고 번호 답안·숨긴 풀이·상세 해설을 연결한다', (tester) async {
    final server = AiTestServer();
    final auth = await tester.runAsync(
      () => testAuth(authenticated: true, adapter: server),
    );
    addTearDown(auth!.dispose);
    final router = createAppRouter(initialLocation: '/problems');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(CobipApp(router: router), auth: auth);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('AI 실무 문제 생성'));
    expect(find.byType(AiQuizScreen), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('ai-category')))
          .controller!
          .text,
      'aws',
    );
    expect(find.byKey(const ValueKey('ai-domain')), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('ai-category')), '');
    expect(find.text('예: aws, docker, cicd'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('ai-category')), 'docker');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('ai-generate')));
    expect(server.calls('/ai/quiz/generate').single.data['category'], 'docker');
    expect(
      server.calls('/ai/quiz/generate').single.data.containsKey('domain'),
      isFalse,
    );
    expect(server.calls('/ai/quiz/generate').single.data['quiz_types'], [
      'MULTIPLE_CHOICE',
      'BLANK',
      'DESCRIPTIVE',
    ]);
    expect(find.text('생성 시 해설'), findsNothing);
    await tapVisible(tester, find.byKey(const ValueKey('ai-option-2')));
    await tapVisible(tester, find.text('답안 제출'));
    expect(server.calls('/ai/quiz/grade').single.data['userAnswer'], '2');
    expect(find.text('정답 · 100점'), findsOneWidget);
    expect(find.text('생성 시 해설'), findsNothing);
    await tapVisible(tester, find.text('풀이 보기'));
    expect(find.text('생성 시 해설'), findsOneWidget);
    expect(find.text('채점 후 해설'), findsNothing);
    await tapVisible(tester, find.text('자세한 해설'));
    expect(find.text('상세 해설'), findsOneWidget);
    await tapVisible(tester, find.text('다음 문제'));
    expect(find.text('blank 문제'), findsOneWidget);
    expect(find.text('채점 후 해설'), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('ai-answer')), '사용자 답안');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('답안 제출'));
    expect(
      server.calls('/ai/quiz/grade').last.data['question']['type'],
      'blank',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('생성 중 폼과 제출이 잠기고 실패 후 입력을 유지한다', (tester) async {
    final server = AiTestServer();
    final response = Completer<ResponseBody>();
    server.aiHandler = (_) => response.future;
    final auth = await tester.runAsync(
      () => testAuth(authenticated: true, adapter: server),
    );
    addTearDown(auth!.dispose);
    final router = createAppRouter(initialLocation: '/problems/generate');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(CobipApp(router: router), auth: auth);
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('ai-generate'));
    await tester.dragUntilVisible(
      button.hitTestable(),
      find.byType(ListView),
      const Offset(0, -140),
    );
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    response.complete(jsonResponse({'detail': []}, 422));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.textContaining('입력 내용을 확인').hitTestable(),
      find.byType(ListView),
      const Offset(0, -140),
    );
    expect(find.textContaining('입력 내용을 확인'), findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    expect(server.calls('/ai/quiz/generate'), hasLength(1));
  });

  testWidgets('Java AI 재시도는 저장된 답안을 중복 제출하지 않는다', (tester) async {
    final server = AiTestServer()
      ..aiHandler = (_) async => jsonResponse({}, 500);
    final auth = await tester.runAsync(
      () => testAuth(authenticated: true, adapter: server),
    );
    addTearDown(auth!.dispose);
    final store = LearningStore(api: LearningApi(auth.api.dio));
    final router = createAppRouter(initialLocation: '/problems/42');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(
      CobipApp(router: router, learningStore: store),
      auth: auth,
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('answer-42')),
      'class Main {}',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('답안 제출'));
    expect(store.latest(42)!.pending, isTrue);
    server.aiHandler = null;
    await tapVisible(tester, find.text('AI 채점 다시 요청'));
    expect(server.calls('/ai/java/grade'), hasLength(2));
    expect(
      server.requests.where(
        (r) => r.path == '/api/questions/42/submissions' && r.method == 'POST',
      ),
      hasLength(1),
    );
    expect(find.text('정답 · 90점'), findsOneWidget);
    expect(
      store.latest(42)!.pending,
      isTrue,
    ); // Do not fabricate a persisted BE grade.
    expect(find.text('Java 피드백'), findsNothing);
    await tapVisible(tester, find.text('풀이 보기'));
    expect(find.text('Java 피드백'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('챗봇 전송 로딩과 fallback 재시도를 표시한다', (tester) async {
    final server = AiTestServer();
    final response = Completer<ResponseBody>();
    server.aiHandler = (_) => response.future;
    final auth = await tester.runAsync(
      () => testAuth(authenticated: true, adapter: server),
    );
    addTearDown(auth!.dispose);
    final router = createAppRouter(initialLocation: '/chat');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(CobipApp(router: router), auth: auth);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('chat-input')), '캐시가 뭐야?');
    await tester.pump();
    await tester.tap(find.byTooltip('메시지 보내기'));
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == '메시지 보내기',
            ),
          )
          .onPressed,
      isNull,
    );
    response.complete(
      aiResponse({
        'answer': '기본 안내',
        'source': 'fallback',
        'ragUsed': false,
        'references': [],
        'intent': null,
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('기본 안내'), findsNothing);
    server.aiHandler = null;
    await tapVisible(tester, find.text('답변 다시 요청'));
    expect(find.text('서버 챗봇 답변'), findsOneWidget);
    expect(find.text('캐시가 뭐야?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

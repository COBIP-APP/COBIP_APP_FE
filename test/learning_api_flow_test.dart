import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/learning/data/learning_api.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_store.dart';
import 'package:flutter/material.dart';
import 'package:cobip_app_fe/features/learning/presentation/template_preview_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';
import 'learning_test_support.dart';
import 'section_flow_test_support.dart' as section_support;

void main() {
  Future<void> reveal(WidgetTester tester, String text) async {
    await tester.dragUntilVisible(
      find.text(text).hitTestable(),
      find.byType(ListView).first,
      const Offset(0, -180),
    );
    await tester.tap(find.text(text).hitTestable());
    await tester.pumpAndSettle();
  }

  testWidgets('실제 저장소로 서버 ID 화면을 열고 진도·답안을 저장한다', (tester) async {
    final server = LearningServer();
    server.handle = (r) async {
      if (r.path == '/api/questions') {
        return jsonResponse([standaloneQuestion(41)], 200);
      }
      if (r.path == '/api/questions/41') {
        return jsonResponse(standaloneQuestion(41), 200);
      }
      return server.respond(r);
    };
    final auth = await tester.runAsync(
      () => testAuth(authenticated: true, adapter: server),
    );
    addTearDown(auth!.dispose);
    final store = LearningStore(api: LearningApi(auth.api.dio));
    final router = createAppRouter(initialLocation: '/grammar');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(
      CobipApp(router: router, learningStore: store),
      auth: auth,
    );
    await tester.pumpAndSettle();
    await reveal(tester, '서버 조건문');
    expect(
      tester
          .widget<TemplatePreviewScreen>(find.byType(TemplatePreviewScreen))
          .templateId,
      31,
    );
    expect(find.text('서버 본문'), findsOneWidget);
    expect(server.savedProgress?['lastSectionId'], 311);
    await tester.tap(find.byTooltip('북마크 저장'));
    await tester.pumpAndSettle();
    expect(server.bookmarked, isTrue);
    router.go('/problems/41');
    await tester.pumpAndSettle();
    await reveal(tester, 'B. 두 번째');
    await reveal(tester, '답 확인');
    expect(store.latest(41)!.score, 100);
    expect(store.solved(41), isTrue);
    expect(find.text('서버 해설'), findsNothing);
    await reveal(tester, '풀이 보기');
    expect(find.text('서버 해설'), findsOneWidget);
    await reveal(tester, '목록으로 돌아가기');
    await reveal(tester, '서버 문제 41');
    expect(find.text('최근 제출 결과 보기'), findsOneWidget);
    expect(find.text('서버 해설'), findsNothing);
    expect(
      server.requests
          .where((r) => r.extra['authRequired'] == true)
          .every((r) => r.headers['Authorization'] == 'Bearer test-access-1'),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('빈 서버 목록에 더미가 없고 당겨서 다시 조회한다', (tester) async {
    final server = LearningServer();
    server.handle = (r) =>
        r.path == '/api/templates' || r.path == '/api/questions'
        ? Future.value(jsonResponse([], 200))
        : server.respond(r);
    final auth = await tester.runAsync(
      () => testAuth(authenticated: true, adapter: server),
    );
    addTearDown(auth!.dispose);
    final store = LearningStore(api: LearningApi(auth.api.dio));
    final router = createAppRouter(initialLocation: '/grammar');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(
      CobipApp(router: router, learningStore: store),
      auth: auth,
    );
    await tester.pumpAndSettle();
    expect(store.templates, isEmpty);
    expect(find.text('아직 등록된 학습이 없어요.'), findsOneWidget);
    final before = server.requests
        .where((r) => r.path == '/api/templates')
        .length;
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(
      server.requests.where((r) => r.path == '/api/templates').length,
      greaterThan(before),
    );
    router.go('/problems');
    await tester.pumpAndSettle();
    expect(find.text('아직 등록된 문제가 없어요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('연결 문제 일부 실패 후 재시도는 성공한 동일 답안을 중복 제출하지 않는다', (tester) async {
    final server = LearningServer();
    final auth = await tester.runAsync(
      () => testAuth(authenticated: true, adapter: server),
    );
    addTearDown(auth!.dispose);
    final store = LearningStore(api: LearningApi(auth.api.dio));
    final router = createAppRouter(
      initialLocation: '/grammar-practice/31?section=311',
    );
    addTearDown(router.dispose);
    await tester.pumpWithAuth(
      CobipApp(router: router, learningStore: store),
      auth: auth,
    );
    await tester.pumpAndSettle();
    await reveal(tester, 'B. 두 번째');
    for (final id in [42, 43]) {
      final input = find.byKey(ValueKey('answer-$id'));
      await tester.dragUntilVisible(
        input.hitTestable(),
        find.byType(ListView).first,
        const Offset(0, -180),
      );
      await tester.enterText(input, '직접 작성한 답안');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
    }
    server.failure = 500;
    server.failurePath = '/api/questions/42/submissions';
    for (final id in [41, 42, 43]) {
      final submit = find.byKey(ValueKey('submit-$id'));
      await section_support.reveal(tester, submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
    }
    expect(store.latest(41), isNotNull);
    expect(store.latest(42), isNull);
    expect(store.latest(43), isNotNull);
    server.failure = null;
    final retry = find.byKey(const ValueKey('submit-42'));
    await section_support.reveal(tester, retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    int submissions(int id) => server.requests
        .where(
          (r) =>
              r.method == 'POST' && r.path == '/api/questions/$id/submissions',
        )
        .length;
    expect(submissions(41), 1);
    expect(submissions(42), 2);
    expect(submissions(43), 1);
    expect(store.latest(42)!.pending, isTrue);
    expect(store.progress(31)?.completedAt, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('언어가 없는 문법도 공통 학습 경로에서 상세를 표시한다', (tester) async {
    final server = LearningServer();
    server.handle = (r) async {
      if (r.path == '/api/templates') {
        return jsonResponse([serverTemplate()..['languageId'] = null], 200);
      }
      if (r.path == '/api/templates/31') {
        return jsonResponse(serverTemplate()..['languageId'] = null, 200);
      }
      return server.respond(r);
    };
    final auth = await tester.runAsync(
      () => testAuth(authenticated: true, adapter: server),
    );
    addTearDown(auth!.dispose);
    final store = LearningStore(api: LearningApi(auth.api.dio));
    final router = createAppRouter(initialLocation: '/grammar');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(
      CobipApp(router: router, learningStore: store),
      auth: auth,
    );
    await tester.pumpAndSettle();
    expect(
      store.templateLocation(store.template(31)!),
      '/grammar/common/chapters/31',
    );
    await reveal(tester, '서버 조건문');
    await reveal(tester, '첫 목차');
    expect(find.text('서버 본문'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

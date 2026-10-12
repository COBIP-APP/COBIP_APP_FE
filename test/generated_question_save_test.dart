import 'dart:async';

import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/learning/data/learning_api.dart';
import 'package:cobip_app_fe/features/learning/data/learning_models.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_store.dart';
import 'package:cobip_app_fe/features/problems/data/ai_api.dart';
import 'package:cobip_app_fe/features/problems/data/ai_models.dart';
import 'package:cobip_app_fe/features/problems/presentation/ai_quiz_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ai_test_support.dart';
import 'auth_test_support.dart';
import 'learning_test_support.dart';

Map<String, dynamic> ownQuestion({
  int owner = 1,
  String type = 'MULTIPLE_CHOICE',
}) => serverQuestion(41)
  ..addAll({
    'id': 501,
    'createdBy': owner,
    'creatorNickname': '테스트학습자',
    'published': false,
    'prompt': '저장한 내 문제',
    'questionType': type,
    'relatedTemplateId': null,
    'relatedSectionId': null,
    'choiceOptions': [
      {'key': '1', 'text': '첫 보기'},
      {'key': '2', 'text': '두 번째 보기'},
    ],
  });

Future<void> generate(AiQuizViewModel vm) => vm.generate(
  category: 'Java',
  difficulty: '중급',
  types: [AiQuizType.multipleChoice],
  countPerType: 1,
  domain: '',
);

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
  test('명시적 저장만 전송하고 중복 클릭·타임아웃 재시도에 같은 UUID를 사용한다', () async {
    final server = AiTestServer();
    final dio = testApi(server).dio;
    final store = LearningStore(api: LearningApi(dio))..bindUser(1);
    addTearDown(store.dispose);
    await store.load();
    final vm = AiQuizViewModel(AiApi(dio), userId: '1', learningStore: store);
    addTearDown(vm.dispose);
    await generate(vm);
    expect(server.calls('/api/users/me/questions'), isEmpty);
    final delayed = Completer<ResponseBody>();
    final started = Completer<void>();
    server.handle = (r) {
      if (r.path == '/api/users/me/questions') {
        started.complete();
        return delayed.future;
      }
      return server.respondAll(r);
    };
    final pending = vm.save();
    await started.future;
    await vm.save();
    vm.select(1);
    expect(vm.index, 0);
    expect(vm.busy, isTrue);
    final first = server.calls('/api/users/me/questions').single;
    delayed.completeError(
      DioException(
        requestOptions: first,
        type: DioExceptionType.receiveTimeout,
      ),
    );
    await pending;
    expect(vm.savedQuestion, isNull);
    expect(vm.error, isNotNull);
    expect(store.myQuestions, isEmpty);
    server.handle = (r) async => r.path == '/api/users/me/questions'
        ? jsonResponse(ownQuestion(), 200)
        : server.respondAll(r);
    await vm.save();
    await vm.save();
    final calls = server.calls('/api/users/me/questions');
    expect(calls, hasLength(2));
    expect(calls.last.data, calls.first.data);
    expect(calls.last.extra['authRequired'], isTrue);
    final body = calls.last.data as Map;
    expect(
      body.keys,
      unorderedEquals([
        'clientRequestId',
        'category',
        'difficulty',
        'question',
      ]),
    );
    expect(
      body['clientRequestId'],
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(body['question']['id'], 1); // AI local ID is not the DB ID.
    expect(vm.savedQuestion!.id, 501);
    expect(store.myQuestions.single.createdBy, 1);
    vm.select(1);
    expect(vm.savedQuestion, isNull);
    vm.select(0);
    expect(vm.savedQuestion!.id, 501);
    vm.retry();
    expect(vm.savedQuestion!.id, 501);
    vm.newBatch();
    await generate(vm);
    await vm.save();
    expect(
      server.calls('/api/users/me/questions').last.data['clientRequestId'],
      isNot(body['clientRequestId']),
    );
  });

  test('미구현 API 오류를 빈 목록·저장 성공으로 표시하지 않는다', () async {
    final server = AiTestServer();
    final dio = testApi(server).dio;
    final store = LearningStore(api: LearningApi(dio))..bindUser(1);
    addTearDown(store.dispose);
    await store.load();
    final vm = AiQuizViewModel(AiApi(dio), userId: '1', learningStore: store);
    addTearDown(vm.dispose);
    await generate(vm);
    await vm.save();
    expect(vm.error, contains('아직 서버에 준비되지'));
    expect(vm.savedQuestion, isNull);
    await store.loadMyQuestions();
    expect(store.myQuestionsState, PreviewLoadState.error);
    expect(store.myQuestionsError, contains('아직 서버에 준비되지'));
    expect(store.state, PreviewLoadState.ready);
    expect(store.questions, hasLength(3));
  });

  test('내 문제는 재접속 시 조회하며 다른 작성자의 공개·비공개 응답을 거절한다', () async {
    final server = AiTestServer();
    final api = LearningApi(testApi(server).dio);
    server.handle = (r) async => r.path == '/api/users/me/questions'
        ? jsonResponse([ownQuestion()], 200)
        : r.path == '/api/questions/501'
        ? jsonResponse(ownQuestion(), 200)
        : server.respondAll(r);
    final store = LearningStore(api: api)..bindUser(1);
    addTearDown(store.dispose);
    await store.load();
    await store.loadMyQuestions();
    expect(store.myQuestions.single.id, 501);
    await store.ensureDetail('q:501');
    expect(store.detailReady('q:501'), isTrue);
    expect(store.question(501)!.published, isFalse);
    await expectLater(api.question(501), throwsA(isA<LearningApiException>()));
    for (final published in [false, true]) {
      server.handle = (_) async =>
          jsonResponse([ownQuestion(owner: 2)..['published'] = published], 200);
      await expectLater(
        api.myQuestions(1),
        throwsA(isA<LearningApiException>()),
      );
    }
    store.bindUser(null);
    expect(store.myQuestions, isEmpty);
    expect(store.question(501), isNull);
  });

  test('사용자 변경 뒤 늦게 도착한 저장 응답을 새 계정에 적용하지 않는다', () async {
    final server = AiTestServer();
    final dio = testApi(server).dio;
    final store = LearningStore(api: LearningApi(dio))..bindUser(1);
    addTearDown(store.dispose);
    await store.load();
    final vm = AiQuizViewModel(AiApi(dio), userId: '1', learningStore: store);
    addTearDown(vm.dispose);
    await generate(vm);
    final delayed = Completer<ResponseBody>();
    final started = Completer<void>();
    server.handle = (r) {
      if (r.path == '/api/users/me/questions') {
        started.complete();
        return delayed.future;
      }
      return server.respondAll(r);
    };
    final pending = vm.save();
    await started.future;
    store.bindUser(2);
    delayed.complete(jsonResponse(ownQuestion(), 201));
    await pending;
    expect(store.myQuestions, isEmpty);
    expect(vm.savedQuestion, isNull);
  });

  test('저장된 OX·단답·빈칸·서술형을 기존 제출 API의 답안 필드로 전달한다', () async {
    final server = AiTestServer();
    final api = LearningApi(testApi(server).dio);
    for (final type in [
      LearningQuestionType.ox,
      LearningQuestionType.shortAnswer,
      LearningQuestionType.fillBlank,
      LearningQuestionType.descriptive,
    ]) {
      server.handle = (r) async => r.path == '/api/questions/501'
          ? jsonResponse(ownQuestion(type: type.code), 200)
          : server.respondAll(r);
      final q = await api.question(501, ownerId: 1);
      final answer = type.hasChoices ? '2' : '작성 답안';
      await api.submit(1, q, answer);
      expect(server.requests.last.data, {
        'userId': 1,
        type.hasChoices ? 'selectedChoiceKey' : 'answerText': answer,
      });
    }
  });

  testWidgets('생성 문제 저장 후 기존 풀이로 이동하고 작성자 필터에서 다시 찾는다', (tester) async {
    final server = AiTestServer();
    var persisted = false;
    server.handle = (r) async {
      if (r.path == '/api/users/me/questions') {
        if (r.method == 'POST') {
          persisted = true;
          return jsonResponse(ownQuestion(), 201);
        }
        return jsonResponse([if (persisted) ownQuestion()], 200);
      }
      if (r.path == '/api/questions/501') {
        return jsonResponse(ownQuestion(), 200);
      }
      return server.respondAll(r);
    };
    final auth = await tester.runAsync(
      () => testAuth(authenticated: true, adapter: server),
    );
    addTearDown(auth!.dispose);
    final router = createAppRouter(initialLocation: '/problems/generate');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(
      CobipApp(
        router: router,
        learningStore: LearningStore(api: LearningApi(auth.api.dio)),
      ),
      auth: auth,
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('ai-generate')));
    await tapVisible(tester, find.byKey(const ValueKey('ai-save-question')));
    expect(find.text('저장 완료'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('ai-save-question')),
          )
          .onPressed,
      isNull,
    );
    await tapVisible(tester, find.text('저장한 문제 풀기'));
    expect(find.text('저장한 내 문제'), findsOneWidget);
    expect(find.text('작성자: 테스트학습자 (나)'), findsOneWidget);
    expect(find.byKey(const ValueKey('choice-501-2')), findsOneWidget);
    router.go('/problems');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('필터'));
    await tester.tap(find.text('내가 만든 문제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();
    expect(find.text('서버 문제 41'), findsNothing);
    await tester.dragUntilVisible(
      find.text('저장한 내 문제'),
      find.byType(ListView).first,
      const Offset(0, -140),
    );
    expect(find.text('저장한 내 문제'), findsOneWidget);
    expect(
      server.calls('/api/users/me/questions').where((r) => r.method == 'GET'),
      hasLength(1),
    );
    expect(tester.takeException(), isNull);
  });
}

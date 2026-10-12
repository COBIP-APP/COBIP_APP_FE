import 'dart:async';

import 'package:cobip_app_fe/features/learning/data/learning_api.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';
import 'learning_test_support.dart';

void main() {
  late LearningServer server;
  late LearningApi api;
  setUp(() {
    server = LearningServer();
    api = LearningApi(testApi(server).dio);
  });

  test('서버 언어·계층 분류 ID를 사용하고 요약과 상세를 분리한다', () async {
    final store = LearningStore(api: api)..bindUser(1);
    addTearDown(store.dispose);
    await store.load();
    expect(store.state, PreviewLoadState.ready);
    expect(store.categoryIds('PRACTICAL'), {202, 204});
    expect(store.languages.single.id, 101);
    expect(store.template(31)!.sections, isEmpty);
    expect(
      store.templateLocation(store.template(31)!),
      '/grammar/java/chapters/31',
    );
    await store.ensureDetail('t:31');
    expect(store.template(31)!.allSections.single.body, '서버 본문');
    expect(store.detailReady('t:31'), isTrue);
    expect(
      server.requests.every((r) => r.extra['authRequired'] == true),
      isTrue,
    );
    expect(
      server.requests
          .firstWhere((r) => r.path == '/api/templates')
          .queryParameters,
      {'publishedOnly': true},
    );
  });

  test('저장·제출 후 새 저장소에서도 서버 기록으로 복원한다', () async {
    final store = LearningStore(api: api)..bindUser(1);
    addTearDown(store.dispose);
    await store.load();
    await store.ensureDetail('t:31');
    await store.toggleBookmark(31);
    await store.saveProgress(31, 311, completed: true);
    await store.saveProgress(31, 311);
    expect(
      (server.requests.last.data as Map).containsKey('completed'),
      isFalse,
    );
    await store.submit(41, 'B');
    final restarted = LearningStore(api: api)..bindUser(1);
    addTearDown(restarted.dispose);
    await restarted.load();
    expect(restarted.bookmarked(31), isTrue);
    expect(restarted.progress(31)!.completedAt, isNotNull);
    expect(restarted.solved(41), isTrue);
    await restarted.toggleBookmark(31);
    expect(server.bookmarked, isFalse);
  });

  test('답안은 유형별 필드 하나와 본인 ID만 보내고 서버 점수를 사용한다', () async {
    final questions = await api.questions();
    for (final q in questions) {
      final result = await api.submit(1, q, q.id == 41 ? 'A' : '직접 작성한 답안');
      final data = server.requests.last.data as Map;
      expect(data.length, 2);
      expect(data['userId'], 1);
      expect(
        data.containsKey(
          q.id == 41
              ? 'selectedChoiceKey'
              : q.id == 42
              ? 'sourceCode'
              : 'answerText',
        ),
        isTrue,
      );
      expect(result.score, q.id == 41 ? 0 : null);
      expect(result.pending, q.id != 41);
    }
  });

  test('제출 조회의 404만 미제출로 처리하고 권한/서버 오류는 전파한다', () async {
    expect(await api.latest(1, 41), isNull);
    for (final status in [401, 403, 500]) {
      server.failure = status;
      await expectLater(
        api.latest(1, 41),
        throwsA(isA<LearningApiException>()),
      );
    }
    server.failure = 404;
    await expectLater(api.template(31), throwsA(isA<LearningApiException>()));
  });

  test('제출 응답의 정답과 해설을 읽고 새 세션에서도 복원한다', () async {
    final question = (await api.questions()).first;
    await api.submit(1, question, 'B');
    server.saved[41]!.addAll({
      'correctAnswer': 'B',
      'explanation': '생성 당시의 기본 해설',
    });
    final freshApi = LearningApi(testApi(server).dio);
    final restored = await freshApi.latest(1, 41);
    expect(restored!.correctAnswer, 'B');
    expect(restored.explanation, '생성 당시의 기본 해설');
  });

  test('실패한 저장은 북마크·진도·제출 상태에 반영하지 않는다', () async {
    final store = LearningStore(api: api)..bindUser(1);
    addTearDown(store.dispose);
    await store.load();
    await store.ensureDetail('t:31');
    server.failure = 500;
    await expectLater(
      store.toggleBookmark(31),
      throwsA(isA<LearningApiException>()),
    );
    await expectLater(
      store.saveProgress(31, 311),
      throwsA(isA<LearningApiException>()),
    );
    await expectLater(
      store.submit(41, 'B'),
      throwsA(isA<LearningApiException>()),
    );
    expect(store.bookmarked(31), isFalse);
    expect(store.progress(31), isNull);
    expect(store.latest(41), isNull);
  });

  test('null 마지막 목차를 허용하며 다른 사용자의 제출 응답은 거부한다', () async {
    server.savedProgress = {
      'templateId': 31,
      'lastSectionId': null,
      'startedAt': stamp,
      'lastStudiedAt': stamp,
      'completedAt': null,
    };
    expect((await api.progress()).single.lastSectionId, isNull);
    await api.submit(1, (await api.questions()).first, 'A');
    server.saved[41]!['userId'] = 2;
    await expectLater(api.latest(1, 41), throwsA(isA<LearningApiException>()));
  });

  test('지원하지 않는 선택지 형식을 가짜 답안으로 바꾸지 않는다', () async {
    server.handle = (r) async => jsonResponse([
      serverQuestion(41)..['choiceOptions'] = ['A', 'B'],
    ], 200);
    await expectLater(api.questions(), throwsA(isA<LearningApiException>()));
  });

  test('늦게 도착한 이전 계정 응답을 버리고 요청을 취소한다', () async {
    final waiting = Completer<ResponseBody>();
    server.handle = (r) =>
        r.path == '/api/languages' ? waiting.future : server.respond(r);
    final store = LearningStore(api: api)..bindUser(1);
    addTearDown(store.dispose);
    final pending = store.load();
    await Future<void>.delayed(Duration.zero);
    store.bindUser(null);
    waiting.complete(
      jsonResponse([
        {'id': 101, 'code': 'JAVA', 'name': 'Java'},
      ], 200),
    );
    await pending;
    expect(store.languages, isEmpty);
    expect(store.templates, isEmpty);
    expect(store.userId, isNull);
  });

  test('같은 문제 중복 제출을 막는다', () async {
    final store = LearningStore(api: api)..bindUser(1);
    addTearDown(store.dispose);
    await store.load();
    final gate = Completer<ResponseBody>();
    server.handle = (r) => r.method == 'POST' ? gate.future : server.respond(r);
    final first = store.submit(41, 'B');
    await expectLater(store.submit(41, 'B'), throwsStateError);
    gate.complete(
      jsonResponse({
        'id': 1,
        'userId': 1,
        'questionId': 41,
        'selectedChoiceKey': 'B',
        'gradingStatus': 'COMPLETED',
        'score': 100,
        'submittedAt': stamp,
        'gradedAt': stamp,
      }, 201),
    );
    await first;
    expect(store.solved(41), isTrue);
  });

  test('학습 답안 제출의 401은 토큰을 갱신하고 동일 답안으로 한 번 재시도한다', () async {
    final tokens = MemoryTokenStore();
    final auth = await testAuth(
      authenticated: true,
      adapter: server,
      store: tokens,
    );
    addTearDown(auth.dispose);
    final authenticatedApi = LearningApi(auth.api.dio);
    final question = await authenticatedApi.question(41);
    final attempts = <Map<String, Object?>>[];
    server.handle = (r) async {
      if (r.path == '/api/auth/refresh') {
        return jsonResponse(testTokens(2), 200);
      }
      if (r.path == '/api/questions/41/submissions') {
        attempts.add({
          'authorization': r.headers['Authorization'],
          'body': Map.of(r.data as Map),
        });
        if (attempts.length == 1) {
          return jsonResponse({'code': 'UNAUTHORIZED'}, 401);
        }
      }
      return server.respond(r);
    };
    final result = await authenticatedApi.submit(
      auth.user!.userId,
      question,
      'B',
    );
    expect(result.score, 100);
    expect(attempts, [
      {
        'authorization': 'Bearer test-access-1',
        'body': {'userId': 1, 'selectedChoiceKey': 'B'},
      },
      {
        'authorization': 'Bearer test-access-2',
        'body': {'userId': 1, 'selectedChoiceKey': 'B'},
      },
    ]);
    expect(
      server.requests.where((r) => r.path == '/api/auth/refresh').length,
      1,
    );
    expect(tokens.value, contains('test-refresh-2'));
  });

  test('학습 API의 반복 401은 세션을 종료하고 403은 토큰 재발급 없이 실패한다', () async {
    for (final status in [401, 403]) {
      final adapter = LearningServer();
      final auth = await testAuth(authenticated: true, adapter: adapter);
      addTearDown(auth.dispose);
      var reads = 0;
      adapter.handle = (r) async {
        if (r.path == '/api/auth/refresh') {
          return jsonResponse(testTokens(2), 200);
        }
        reads++;
        return jsonResponse({}, status);
      };
      await expectLater(
        LearningApi(auth.api.dio).templates(),
        throwsA(isA<LearningApiException>()),
      );
      expect(reads, status == 401 ? 2 : 1);
      expect(auth.isAuthenticated, status == 403);
      expect(
        adapter.requests.where((r) => r.path == '/api/auth/refresh').length,
        status == 401 ? 1 : 0,
      );
    }
  });

  test('중첩 목차·첨부와 null 선택 필드를 BE 응답 그대로 해석한다', () async {
    final detail = serverTemplate();
    final root = (detail['sections'] as List).single as Map<String, dynamic>;
    root['body'] = null;
    root['exampleCode'] = null;
    root['children'] = [
      {
        'id': 312,
        'parentId': 311,
        'title': '하위 목차',
        'body': '본문',
        'exampleCode': null,
        'media': [
          {
            'id': 51,
            'originalName': 'diagram.png',
            'objectKey': 'private/diagram.png',
            'altText': null,
          },
        ],
        'children': [],
      },
    ];
    server.handle = (r) async => jsonResponse(detail, 200);
    final result = await api.template(31);
    expect(result.allSections.map((s) => s.id), [311, 312]);
    expect(result.sections.single.body, isNull);
    expect(result.allSections.last.parentId, 311);
    expect(
      result.allSections.last.media.single.objectKey,
      'private/diagram.png',
    );
    expect(result.allSections.last.media.single.altText, isNull);
  });
}

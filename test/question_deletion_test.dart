import 'dart:async';

import 'package:cobip_app_fe/features/learning/data/learning_api.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';
import 'learning_test_support.dart';

Map<String, dynamic> ownQuestion() => serverQuestion(41)
  ..addAll({
    'id': 501,
    'createdBy': 1,
    'published': false,
    'prompt': '내 삭제 테스트 문제',
  });
void main() {
  late LearningServer server;
  late LearningApi api;
  late LearningStore store;
  var status = 204;
  setUp(() async {
    status = 204;
    server = LearningServer();
    server.handle = (r) async {
      if (r.path == '/api/users/me/questions') {
        return jsonResponse([ownQuestion()], 200);
      }
      if (r.path == '/api/users/me/questions/501') {
        return ResponseBody.fromString('', status);
      }
      if (r.path == '/api/questions/501') {
        return jsonResponse(ownQuestion(), 200);
      }
      return server.respond(r);
    };
    api = LearningApi(testApi(server).dio);
    store = LearningStore(api: api)..bindUser(1);
    await store.load();
    await store.loadMyQuestions();
  });
  tearDown(() => store.dispose());

  test('204 빈 응답을 처리하고 목록·상세·제출 캐시에서 제거한다', () async {
    await store.ensureDetail('q:501');
    await store.submit(501, 'B');
    expect(store.latest(501), isNotNull);
    await store.deleteMyQuestion(501);
    expect(store.myQuestions, isEmpty);
    expect(store.question(501), isNull);
    expect(store.latest(501), isNull);
    expect(store.detailReady('q:501'), isFalse);
    final request = server.requests.last;
    expect(request.method, 'DELETE');
    expect(request.path, '/api/users/me/questions/501');
    expect(request.data, isNull);
    expect(request.queryParameters, isEmpty);
    expect(request.extra['authRequired'], isTrue);
    await expectLater(store.submit(501, 'B'), throwsStateError);
  });
  for (final code in [404, 403, 500]) {
    test('$code 삭제 실패는 카드를 제거하지 않고 오류를 보존한다', () async {
      status = code;
      await expectLater(
        store.deleteMyQuestion(501),
        throwsA(
          isA<LearningApiException>().having((e) => e.status, 'status', code),
        ),
      );
      expect(store.myQuestions.single.id, 501);
      expect(store.question(501), isNotNull);
    });
  }
  test('공개 문제는 DELETE 요청 없이 거부한다', () async {
    await expectLater(
      store.deleteMyQuestion(41),
      throwsA(isA<LearningApiException>()),
    );
    expect(server.requests.where((r) => r.method == 'DELETE'), isEmpty);
  });
  test('삭제와 겹친 오래된 목록·상세 응답이 문제를 복구하지 않는다', () async {
    final listGate = Completer<ResponseBody>();
    final detailGate = Completer<ResponseBody>();
    final listEntered = Completer<void>();
    final detailEntered = Completer<void>();
    server.handle = (r) async {
      if (r.path == '/api/users/me/questions') {
        listEntered.complete();
        return listGate.future;
      }
      if (r.path == '/api/questions/501') {
        detailEntered.complete();
        return detailGate.future;
      }
      if (r.path == '/api/users/me/questions/501') {
        return ResponseBody.fromString('', 204);
      }
      return server.respond(r);
    };
    final list = store.loadMyQuestions();
    final detail = store.ensureDetail('q:501');
    await Future.wait([listEntered.future, detailEntered.future]);
    await store.deleteMyQuestion(501);
    listGate.complete(jsonResponse([ownQuestion()], 200));
    detailGate.complete(jsonResponse(ownQuestion(), 200));
    await Future.wait([list, detail]);
    expect(store.myQuestions, isEmpty);
    expect(store.question(501), isNull);
    expect(store.detailReady('q:501'), isFalse);
  });
  test('204 이외 성공 응답을 삭제 성공으로 오인하지 않는다', () async {
    status = 200;
    await expectLater(
      store.deleteMyQuestion(501),
      throwsA(isA<LearningApiException>()),
    );
    expect(store.question(501), isNotNull);
  });
}

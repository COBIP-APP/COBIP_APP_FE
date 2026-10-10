import 'package:cobip_app_fe/features/home/data/home_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';

const _template = {
  'id': 42,
  'title': '서버 학습',
  'summary': '학습 설명',
  'categoryCode': 'GRAMMAR',
  'categoryName': '문법',
  'languageCode': 'python',
  'languageName': 'Python',
  'published': true,
};

Map<String, Object?> _progress() => {
  'userId': 1,
  'templateId': 42,
  'lastSectionId': 101,
  'startedAt': '2026-10-01T09:00:00Z',
  'lastStudiedAt': '2026-10-10T10:00:00Z',
  'completedAt': null,
};

void main() {
  test('공개 템플릿과 본인 진도 계약을 파싱한다', () async {
    final adapter = TestAuthAdapter(
      handle: (options) async => options.path == '/api/templates'
          ? jsonResponse([
              _template,
              {..._template, 'id': 43, 'published': false},
            ], 200)
          : jsonResponse(_progress(), 200),
    );
    final api = HomeApi(testApi(adapter).dio);

    final templates = await api.fetchTemplates();
    expect(templates.single.id, 42);
    expect(templates.single.title, '서버 학습');
    expect(templates.single.summary, '학습 설명');
    expect(templates.single.categoryName, '문법');
    expect(templates.single.languageCode, 'python');
    expect(templates.single.published, isTrue);
    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.path, '/api/templates');
    expect(adapter.requests.single.queryParameters['publishedOnly'], true);

    final progress = await api.fetchProgress(1, 42);
    expect(progress?.lastSectionId, 101);
    expect(progress?.lastStudiedAt, DateTime.utc(2026, 10, 10, 10));
    expect(progress?.completedAt, isNull);
    expect(adapter.requests.last.method, 'GET');
    expect(adapter.requests.last.path, '/api/users/1/progress/templates/42');
  });

  test('위치가 없는 진도와 완료 시간을 파싱한다', () async {
    final api = HomeApi(
      testApi(
        TestAuthAdapter(
          handle: (_) async => jsonResponse({
            ..._progress(),
            'lastSectionId': null,
            'completedAt': '2026-10-10T10:01:00Z',
          }, 200),
        ),
      ).dio,
    );
    final progress = await api.fetchProgress(1, 42);
    expect(progress?.lastSectionId, isNull);
    expect(progress?.completedAt, DateTime.utc(2026, 10, 10, 10, 1));
  });

  test('진도 404만 미시작으로 처리하고 서버 오류는 전달한다', () async {
    final adapter = TestAuthAdapter(
      handle: (_) async => jsonResponse({'status': 404}, 404),
    );
    final api = HomeApi(testApi(adapter).dio);
    expect(await api.fetchProgress(1, 42), isNull);
    adapter.handle = (_) async => jsonResponse({'status': 503}, 503);
    await expectLater(
      api.fetchProgress(1, 42),
      throwsA(isA<HomeApiException>().having((e) => e.status, 'status', 503)),
    );
    adapter.handle = (_) async => jsonResponse({'status': 404}, 404);
    await expectLater(api.fetchTemplates(), throwsA(isA<HomeApiException>()));
  });

  test('잘못된 목록·식별자·문구·타입을 성공으로 처리하지 않는다', () async {
    for (final data in [
      {
        'templates': [_template],
      },
      [null],
      [
        {..._template, 'id': 0},
      ],
      [
        {..._template, 'id': '42'},
      ],
      [
        {..._template, 'title': ''},
      ],
      [
        {..._template, 'published': 'true'},
      ],
    ]) {
      final api = HomeApi(
        testApi(TestAuthAdapter(handle: (_) async => jsonResponse(data, 200)))
            .dio,
      );
      await expectLater(
        api.fetchTemplates(),
        throwsA(
          isA<HomeApiException>().having(
            (e) => e.code,
            'code',
            'INVALID_RESPONSE',
          ),
        ),
      );
    }
  });

  test('다른 사용자·템플릿 진도와 잘못된 날짜·위치를 거부한다', () async {
    for (final change in [
      {'userId': 2},
      {'templateId': 43},
      {'lastSectionId': 0},
      {'startedAt': 'invalid-date'},
      {'startedAt': '2026-10-10T10:00:00'},
      {'lastStudiedAt': null},
      {'completedAt': 'invalid-date'},
    ]) {
      final api = HomeApi(
        testApi(
          TestAuthAdapter(
            handle: (_) async => jsonResponse({..._progress(), ...change}, 200),
          ),
        ).dio,
      );
      await expectLater(
        api.fetchProgress(1, 42),
        throwsA(
          isA<HomeApiException>().having(
            (e) => e.code,
            'code',
            'INVALID_RESPONSE',
          ),
        ),
      );
    }
  });

  test('공유 Dio는 Bearer 인증과 401 갱신·재시도를 유지한다', () async {
    final adapter = TestAuthAdapter();
    final auth = await testAuth(authenticated: true, adapter: adapter);
    addTearDown(auth.dispose);
    adapter.handle = (options) async {
      if (options.path == '/api/auth/refresh') {
        return jsonResponse(testTokens(2), 200);
      }
      if (options.headers['Authorization'] == 'Bearer test-access-1') {
        return jsonResponse({'code': 'UNAUTHORIZED'}, 401);
      }
      return options.path == '/api/templates'
          ? jsonResponse([_template], 200)
          : jsonResponse(_progress(), 200);
    };
    final api = HomeApi(auth.api.dio);
    expect((await api.fetchTemplates()).single.id, 42);
    expect((await api.fetchProgress(1, 42))?.userId, 1);
    expect(auth.isAuthenticated, isTrue);
    final requests = adapter.requests
        .where((request) => request.path == '/api/templates')
        .toList();
    expect(requests, hasLength(2));
    expect(requests.last.headers['Authorization'], 'Bearer test-access-2');
    expect(
      adapter.requests.where((request) => request.path == '/api/auth/refresh'),
      hasLength(1),
    );
  });

  test('미설정 주소와 잘못된 요청 식별자는 요청 전에 거부한다', () async {
    await expectLater(
      HomeApi(Dio()).fetchTemplates(),
      throwsA(
        isA<HomeApiException>().having(
          (e) => e.code,
          'code',
          'API_NOT_CONFIGURED',
        ),
      ),
    );
    final adapter = TestAuthAdapter();
    final api = HomeApi(testApi(adapter).dio);
    for (final (userId, templateId) in [(0, 42), (1, 0), (-1, 42)]) {
      await expectLater(
        api.fetchProgress(userId, templateId),
        throwsA(
          isA<HomeApiException>().having(
            (e) => e.code,
            'code',
            'INVALID_REQUEST',
          ),
        ),
      );
    }
    expect(adapter.requests, isEmpty);
  });

  test('네트워크·JSON 오류와 잘못된 성공 상태를 빈 목록으로 바꾸지 않는다', () async {
    final adapter = TestAuthAdapter(
      handle: (options) async => throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ),
    );
    final api = HomeApi(testApi(adapter).dio);
    await expectLater(api.fetchTemplates(), throwsA(isA<HomeApiException>()));
    adapter.handle = (_) async => jsonResponse([], 202);
    await expectLater(
      api.fetchTemplates(),
      throwsA(
        isA<HomeApiException>().having(
          (e) => e.code,
          'code',
          'INVALID_RESPONSE',
        ),
      ),
    );
    adapter.handle = (_) async => ResponseBody.fromString(
      '{',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
    await expectLater(
      api.fetchTemplates(),
      throwsA(
        isA<HomeApiException>().having(
          (e) => e.code,
          'code',
          'INVALID_RESPONSE',
        ),
      ),
    );
  });
}

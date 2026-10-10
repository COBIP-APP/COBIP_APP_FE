import 'dart:async';
import 'dart:convert';

import 'package:cobip_app_fe/features/auth/data/auth_api.dart';
import 'package:cobip_app_fe/features/auth/presentation/auth_validators.dart';
import 'package:cobip_app_fe/features/auth/presentation/auth_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';

void main() {
  test('닉네임 공백·2~50자, 이메일 255자, 비밀번호 8~64자를 검증한다', () {
    for (final value in ['', '   ', 'a', 'x' * 51]) {
      expect(validateNickname(value), isNotNull);
    }
    for (final value in [' 두리 ', 'x' * 50]) {
      expect(validateNickname(value), isNull);
    }
    expect(validateEmail('${'x' * 244}@example.com'), isNotNull);
    expect(validateEmail('${'x' * 243}@example.com'), isNull);
    for (final value in ['', 'x' * 7, 'x' * 65]) {
      expect(validatePassword(value), isNotNull);
    }
    for (final value in ['x' * 8, 'x' * 64]) {
      expect(validatePassword(value), isNull);
    }
  });

  test('9개 POST 계약과 선행 0·닉네임·동의·204 빈 본문을 처리한다', () async {
    final adapter = TestAuthAdapter();
    final api = testApi(adapter);
    final delivery = await api.sendCode(' member@example.com ');
    expect(delivery.expiresInSeconds, 300);
    expect(delivery.resendAfterSeconds, 60);
    await api.confirmEmail('member@example.com', '012345');
    final user = await api.register(
      email: 'member@example.com',
      nickname: ' 두리 ',
      password: 'password-123',
      serviceTermsAgreed: true,
      privacyTermsAgreed: true,
    );
    expect(user.userId, 1);
    final session = await api.login('member@example.com', 'password-123');
    final rotated = await api.refresh(session.refreshToken);
    expect(rotated.refreshToken, isNot(session.refreshToken));
    await api.logout(rotated.refreshToken, rotated.accessToken);
    await api.sendCode('member@example.com', passwordReset: true);
    final grant = await api.confirmReset('member@example.com', '012345');
    await api.completeReset(grant.token, 'new-password-123');
    expect(adapter.requests.length, 9);
    expect(
      adapter.requests.every((request) => request.method == 'POST'),
      isTrue,
    );
    expect(adapter.requests[1].data, {
      'email': 'member@example.com',
      'code': '012345',
    });
    expect(adapter.requests[2].data, {
      'email': 'member@example.com',
      'nickname': '두리',
      'password': 'password-123',
      'serviceTermsAgreed': true,
      'privacyTermsAgreed': true,
    });
    expect(
      adapter.requests[5].headers['Authorization'],
      'Bearer ${rotated.accessToken}',
    );
    expect(adapter.requests.last.data, {
      'resetToken': 'test-reset',
      'newPassword': 'new-password-123',
    });
  });

  for (final (status, code) in [
    (400, 'INVALID_REQUEST'),
    (409, 'NICKNAME_ALREADY_USED'),
    (429, 'CODE_RATE_LIMITED'),
    (503, 'MAIL_UNAVAILABLE'),
  ]) {
    test('$status $code와 필드 오류를 구분한다', () async {
      final api = testApi(
        TestAuthAdapter(
          handle: (_) async => jsonResponse({
            'code': code,
            'message': 'server',
            'fieldErrors': {'nickname': '입력값을 확인해주세요.'},
          }, status),
        ),
      );
      await expectLater(
        api.sendCode('member@example.com'),
        throwsA(
          isA<AuthApiException>()
              .having((error) => error.status, 'status', status)
              .having((error) => error.code, 'code', code)
              .having(
                (error) => error.fieldErrors.containsKey('nickname'),
                'fieldErrors',
                true,
              ),
        ),
      );
    });
  }

  test('네트워크 오류를 성공으로 바꾸지 않는다', () async {
    final api = testApi(
      TestAuthAdapter(
        handle: (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      ),
    );
    await expectLater(
      api.sendCode('member@example.com'),
      throwsA(
        isA<AuthApiException>().having((error) => error.status, 'status', null),
      ),
    );
  });

  test('주소 미설정 및 잘못된 성공 상태를 거부한다', () async {
    await expectLater(
      AuthApi(Dio()).sendCode('member@example.com'),
      throwsA(
        isA<AuthApiException>().having(
          (error) => error.code,
          'code',
          'API_NOT_CONFIGURED',
        ),
      ),
    );
    final api = testApi(
      TestAuthAdapter(
        handle: (_) async => jsonResponse({'verified': true}, 202),
      ),
    );
    await expectLater(
      api.confirmEmail('member@example.com', '012345'),
      throwsA(
        isA<AuthApiException>().having(
          (error) => error.code,
          'code',
          'INVALID_RESPONSE',
        ),
      ),
    );
  });

  test('로그인 사용자·안전 저장·회전·재시작 복원을 처리한다', () async {
    final store = MemoryTokenStore();
    final adapter = TestAuthAdapter();
    final auth = await testAuth(store: store, adapter: adapter);
    expect(await auth.login('member@example.com', 'password-123'), isTrue);
    expect(auth.user?.nickname, '테스트학습자');
    expect(store.value, isNot(contains('password-123')));
    final before = jsonDecode(store.value!)['refreshToken'];
    expect(await auth.refresh(), isTrue);
    expect(jsonDecode(store.value!)['refreshToken'], isNot(before));
    final restored = AuthViewModel(api: testApi(adapter), tokenStore: store);
    await restored.restore();
    expect(restored.isAuthenticated, isTrue);
    expect(adapter.requests.last.path, '/api/auth/refresh');
    await restored.logout();
    expect(restored.isAuthenticated, isFalse);
    expect(store.value, isNull);
    restored.dispose();
    auth.dispose();
  });

  test('갱신 실패는 토큰·사용자를 지우며 한 번만 요청한다', () async {
    final adapter = TestAuthAdapter();
    final store = MemoryTokenStore();
    final auth = await testAuth(
      authenticated: true,
      adapter: adapter,
      store: store,
    );
    adapter.handle = (_) async =>
        jsonResponse({'code': 'INVALID_REFRESH_TOKEN'}, 401);
    expect(await auth.refresh(), isFalse);
    expect(auth.user, isNull);
    expect(store.value, isNull);
    expect(
      adapter.requests
          .where((request) => request.path == '/api/auth/refresh')
          .length,
      1,
    );
    auth.dispose();
  });

  test('동시 보호 요청의 401은 단일 갱신 후 각각 한 번만 재시도한다', () async {
    final adapter = TestAuthAdapter();
    final auth = await testAuth(authenticated: true, adapter: adapter);
    final refresh = Completer<ResponseBody>();
    adapter.handle = (options) async {
      if (options.path == '/api/auth/refresh') return refresh.future;
      return options.headers['Authorization'] == 'Bearer test-access-2'
          ? jsonResponse({'ok': true}, 200)
          : jsonResponse({'code': 'UNAUTHORIZED'}, 401);
    };
    final requests = [
      auth.api.dio.get<Object?>('/api/protected/a'),
      auth.api.dio.get<Object?>('/api/protected/b'),
    ];
    for (var turn = 0; turn < 10; turn++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(
      adapter.requests
          .where((request) => request.path == '/api/auth/refresh')
          .length,
      1,
    );
    refresh.complete(jsonResponse(testTokens(2), 200));
    expect(
      (await Future.wait(requests))
          .every((response) => response.statusCode == 200),
      isTrue,
    );
    expect(
      adapter.requests
          .where((request) => request.path.startsWith('/api/protected'))
          .length,
      4,
    );
    auth.dispose();
  });

  test('재시도도 401이면 무한 반복 없이 세션을 정리한다', () async {
    final adapter = TestAuthAdapter();
    final auth = await testAuth(authenticated: true, adapter: adapter);
    adapter.handle = (options) async => options.path == '/api/auth/refresh'
        ? jsonResponse(testTokens(2), 200)
        : jsonResponse({'code': 'UNAUTHORIZED'}, 401);
    await expectLater(
      auth.api.dio.get<Object?>('/api/protected'),
      throwsA(isA<DioException>()),
    );
    expect(
      adapter.requests
          .where((request) => request.path == '/api/auth/refresh')
          .length,
      1,
    );
    expect(auth.isAuthenticated, isFalse);
    auth.dispose();
  });

  test('저장 실패·로그인 실패·취소한 늦은 로그인은 인증되지 않는다', () async {
    final store = MemoryTokenStore()..failWrites = true;
    final adapter = TestAuthAdapter();
    final auth = await testAuth(store: store, adapter: adapter);
    expect(await auth.login('member@example.com', 'password-123'), isFalse);
    expect(auth.isAuthenticated, isFalse);
    store.failWrites = false;
    adapter.handle = (_) async =>
        jsonResponse({'code': 'INVALID_CREDENTIALS'}, 401);
    expect(await auth.login('member@example.com', 'wrong'), isFalse);
    expect(
      adapter.requests.where((request) => request.path == '/api/auth/refresh'),
      isEmpty,
    );
    adapter.handle = (_) async => jsonResponse(testTokens(), 200);
    expect(
      await auth.login(
        'member@example.com',
        'password-123',
        isCurrent: () => false,
      ),
      isFalse,
    );
    expect(store.value, isNull);
    auth.dispose();
  });

  test('세션 정리 후 도착한 갱신이 세션을 되살리지 않는다', () async {
    final adapter = TestAuthAdapter();
    final store = MemoryTokenStore();
    final auth = await testAuth(
      authenticated: true,
      adapter: adapter,
      store: store,
    );
    final refresh = Completer<ResponseBody>();
    adapter.handle = (options) async => options.path == '/api/auth/refresh'
        ? refresh.future
        : jsonResponse(null, 204);
    final pending = auth.refresh();
    await Future<void>.delayed(Duration.zero);
    await auth.clearSession();
    refresh.complete(jsonResponse(testTokens(2), 200));
    expect(await pending, isFalse);
    expect(store.value, isNull);
    expect(auth.user, isNull);
    auth.dispose();
  });

  test('로그아웃은 진행 중인 회전을 기다리고 최신 토큰 쌍으로 204를 처리한다', () async {
    final adapter = TestAuthAdapter();
    final store = MemoryTokenStore();
    final auth = await testAuth(
      authenticated: true,
      adapter: adapter,
      store: store,
    );
    final refresh = Completer<ResponseBody>();
    adapter.handle = (options) async => options.path == '/api/auth/refresh'
        ? refresh.future
        : jsonResponse(null, 204);
    final pending = auth.refresh();
    final logout = auth.logout();
    await Future<void>.delayed(Duration.zero);
    expect(
      adapter.requests.where((request) => request.path == '/api/auth/logout'),
      isEmpty,
    );
    refresh.complete(jsonResponse(testTokens(2), 200));
    expect(await pending, isTrue);
    await logout;
    expect(adapter.requests.last.data, {'refreshToken': 'test-refresh-2'});
    expect(
      adapter.requests.last.headers['Authorization'],
      'Bearer test-access-2',
    );
    expect(auth.user, isNull);
    expect(store.value, isNull);
    auth.dispose();
  });

  test('만료된 access는 먼저 갱신하고 14일 지난 refresh는 서버 요청 없이 삭제한다', () async {
    final adapter = TestAuthAdapter();
    final store = MemoryTokenStore();
    final auth = await testAuth(
      authenticated: true,
      adapter: adapter,
      store: store,
    );
    adapter.elapsed = const Duration(minutes: 16);
    adapter.handle = (options) async => options.path == '/api/auth/refresh'
        ? jsonResponse(testTokens(2), 200)
        : jsonResponse({'ok': true}, 200);
    await auth.api.dio.get<Object?>('/api/protected');
    expect(adapter.requests[1].path, '/api/auth/refresh');
    expect(
      adapter.requests.last.headers['Authorization'],
      'Bearer test-access-2',
    );
    final count = adapter.requests.length;
    adapter.elapsed = const Duration(days: 15);
    expect(await auth.refresh(), isFalse);
    expect(adapter.requests.length, count);
    expect(store.value, isNull);
    expect(auth.isAuthenticated, isFalse);
    auth.dispose();
  });

  test('앱 복원 시 서버 갱신 실패 또는 손상된 저장값은 인증 상태를 남기지 않는다', () async {
    final store = MemoryTokenStore();
    final adapter = TestAuthAdapter();
    final auth = await testAuth(
      authenticated: true,
      adapter: adapter,
      store: store,
    );
    auth.dispose();
    adapter.handle = (_) async =>
        jsonResponse({'code': 'INVALID_REFRESH_TOKEN'}, 401);
    final restored = AuthViewModel(api: testApi(adapter), tokenStore: store);
    await restored.restore();
    expect(restored.isRestoring, isFalse);
    expect(restored.isAuthenticated, isFalse);
    expect(store.value, isNull);
    restored.dispose();
    store.value = 'invalid';
    final invalid = AuthViewModel(
      api: testApi(TestAuthAdapter()),
      tokenStore: store,
    );
    await invalid.restore();
    expect(invalid.user, isNull);
    expect(store.value, isNull);
    invalid.dispose();
  });
}

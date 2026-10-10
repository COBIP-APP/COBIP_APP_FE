import 'dart:convert';
import 'dart:typed_data';

import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/features/auth/data/auth_api.dart';
import 'package:cobip_app_fe/features/auth/data/token_store.dart';
import 'package:cobip_app_fe/features/auth/presentation/auth_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const testUser = {
  'userId': 1,
  'email': 'member@example.com',
  'nickname': '테스트학습자',
  'role': 'USER',
};
Map<String, Object> testTokens([int rotation = 1]) => {
  'accessToken': 'test-access-$rotation',
  'refreshToken': 'test-refresh-$rotation',
  'tokenType': 'Bearer',
  'accessExpiresInSeconds': 900,
  'user': testUser,
};

ResponseBody jsonResponse(Object? data, int status) => ResponseBody.fromString(
  data == null ? '' : jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

class TestAuthAdapter implements HttpClientAdapter {
  TestAuthAdapter({this.handle});
  Future<ResponseBody> Function(RequestOptions)? handle;
  final requests = <RequestOptions>[];
  int rotation = 0;
  Duration elapsed = Duration.zero;
  DateTime now() => DateTime.now().add(elapsed);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (handle != null) return handle!(options);
    if (options.method == 'GET' && options.path == '/api/templates') {
      return jsonResponse([], 200);
    }
    if (options.path.endsWith('/send')) {
      return jsonResponse({
        'message': '메일함을 확인해 주세요.',
        'expiresInSeconds': 300,
        'resendAfterSeconds': 60,
      }, 202);
    }
    if (options.path == '/api/auth/email-verifications/confirm') {
      return jsonResponse({'verified': true}, 200);
    }
    if (options.path == '/api/auth/password-resets/confirm') {
      return jsonResponse({
        'resetToken': 'test-reset',
        'expiresInSeconds': 600,
      }, 200);
    }
    if (options.path == '/api/auth/register') {
      return jsonResponse(testUser, 201);
    }
    if (options.path == '/api/auth/login' ||
        options.path == '/api/auth/refresh') {
      return jsonResponse(testTokens(++rotation), 200);
    }
    if (options.path == '/api/auth/logout' ||
        options.path == '/api/auth/password-resets/complete') {
      return jsonResponse(null, 204);
    }
    return jsonResponse({'code': 'NOT_FOUND'}, 404);
  }

  @override
  void close({bool force = false}) {}
}

class MemoryTokenStore implements TokenStore {
  String? value;
  bool failWrites = false;
  final writes = <String>[];
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String session) async {
    if (failWrites) throw StateError('test storage failure');
    value = session;
    writes.add(session);
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

AuthApi testApi(TestAuthAdapter adapter) => AuthApi(
  Dio(
    BaseOptions(
      baseUrl: 'https://api.test',
      contentType: 'application/json; charset=utf-8',
    ),
  )..httpClientAdapter = adapter,
);

Future<AuthViewModel> testAuth({
  bool authenticated = false,
  TestAuthAdapter? adapter,
  MemoryTokenStore? store,
}) async {
  final transport = adapter ?? TestAuthAdapter();
  final auth = AuthViewModel(
    api: testApi(transport),
    tokenStore: store ?? MemoryTokenStore(),
    now: transport.now,
  );
  await auth.restore();
  if (authenticated) {
    await auth.login('member@example.com', 'test-password-123');
  }
  return auth;
}

extension AuthWidgetTester on WidgetTester {
  Future<void> advanceAuthTime(Finder screen, Duration duration) async {
    final screenElement = element(screen);
    final adapter =
        screenElement.read<AuthViewModel>().api.dio.httpClientAdapter
            as TestAuthAdapter;
    adapter.elapsed += duration;
    await pump(const Duration(seconds: 1));
  }

  Future<void> pumpWithAuth(
    Widget widget, {
    bool authenticated = false,
    AuthViewModel? auth,
  }) async {
    final session =
        auth ?? (await runAsync(() => testAuth(authenticated: authenticated)))!;
    if (auth == null) addTearDown(session.dispose);
    await pumpWidget(
      widget is CobipApp
          ? CobipApp(
              key: ObjectKey(session),
              auth: session,
              router: widget.router,
            )
          : ChangeNotifierProvider.value(value: session, child: widget),
    );
  }

  Future<void> pumpLearningWidget(Widget widget) =>
      pumpWithAuth(widget, authenticated: true);
}

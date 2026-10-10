import 'dart:async';

import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/auth/presentation/login_screen.dart';
import 'package:cobip_app_fe/features/auth/presentation/sign_up_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';

Future<void> reveal(
  WidgetTester tester,
  Finder finder, {
  bool upward = false,
}) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      upward ? -250 : 250,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> drainAuth(WidgetTester tester) async {
  // 저장소 fixture의 Future는 실제 async zone에서 생성됩니다.
  for (var turn = 0; turn < 4; turn++) {
    await tester.pump(const Duration(milliseconds: 10));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
}

Future<void> tapVisible(
  WidgetTester tester,
  Finder finder, {
  bool settle = true,
}) async {
  await reveal(tester, finder);
  await tester.tap(finder);
  await drainAuth(tester);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> fillSignUp(WidgetTester tester) async {
  await tester.enterText(
    find.byType(TextFormField).first,
    'member@example.com',
  );
  await tester.pump();
  await tapVisible(tester, find.text('인증 요청'));
  await tester.enterText(find.byKey(const Key('signUpCodeField')), '012345');
  await tapVisible(tester, find.text('확인'));
  for (final (key, value) in [
    ('signUpNicknameField', ' 두리 '),
    ('signUpPasswordField', 'password-123'),
    ('signUpPasswordConfirmationField', 'password-123'),
  ]) {
    final field = find.byKey(Key(key));
    await reveal(tester, field);
    await tester.enterText(field, value);
  }
  tester.testTextInput.hide();
  await tester.pump();
  await reveal(tester, find.byType(Checkbox).first);
  tester.widget<Checkbox>(find.byType(Checkbox).first).onChanged!(true);
  await tester.pump();
}

void main() {
  testWidgets('320px·200% 글씨·키보드에서 닉네임 입력과 필수 약관 검증을 유지한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWithAuth(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
            viewInsets: EdgeInsets.only(bottom: 260),
          ),
          child: const SignUpScreen(),
        ),
      ),
    );
    await fillSignUp(tester);
    final submit = find.byKey(const Key('signUpSubmitButton'));
    await reveal(tester, submit);
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    await reveal(tester, find.byType(Checkbox).last, upward: true);
    tester.widget<Checkbox>(find.byType(Checkbox).last).onChanged!(false);
    await tester.pump();
    await reveal(tester, submit);
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('닉네임과 모든 필수 조건은 가입 버튼에 반영된다', (tester) async {
    await tester.pumpWithAuth(const MaterialApp(home: SignUpScreen()));
    await fillSignUp(tester);
    final submit = find.byKey(const Key('signUpSubmitButton'));
    for (final value in ['', '   ', 'x', 'x' * 51]) {
      await reveal(
        tester,
        find.byKey(const Key('signUpNicknameField')),
        upward: true,
      );
      await tester.enterText(
        find.byKey(const Key('signUpNicknameField')),
        value,
      );
      await tester.pump();
      await reveal(tester, submit);
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    }
    await reveal(
      tester,
      find.byKey(const Key('signUpNicknameField')),
      upward: true,
    );
    await tester.enterText(
      find.byKey(const Key('signUpNicknameField')),
      ' 두리 ',
    );
    await tester.pump();
    await reveal(tester, submit);
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
  });

  testWidgets('가입 실제 성공 응답 이후 완료·로그인으로 이동하며 자동 로그인하지 않는다', (tester) async {
    final adapter = TestAuthAdapter();
    final auth = (await tester.runAsync(() => testAuth(adapter: adapter)))!;
    addTearDown(auth.dispose);
    final router = createAppRouter(initialLocation: '/sign-up');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(CobipApp(router: router), auth: auth);
    await tester.pumpAndSettle();
    await fillSignUp(tester);
    final register = Completer<ResponseBody>();
    adapter.handle = (_) => register.future;
    final button = find.byKey(const Key('signUpSubmitButton'));
    await reveal(tester, button);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tapVisible(tester, button, settle: false);
    await tester.tap(button);
    await tester.pump();
    expect(
      adapter.requests
          .where((request) => request.path == '/api/auth/register')
          .length,
      1,
    );
    expect(router.routeInformationProvider.value.uri.path, '/sign-up');
    expect(adapter.requests.last.data['nickname'], '두리');
    expect(
      adapter.requests.last.data.containsKey('passwordConfirmation'),
      isFalse,
    );
    register.complete(jsonResponse(testUser, 201));
    await drainAuth(tester);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/sign-up/complete');
    expect(auth.isAuthenticated, isFalse);
    await tapVisible(tester, find.text('로그인하기'));
    expect(router.routeInformationProvider.value.uri.path, '/login');
  });

  testWidgets('409 닉네임 오류는 필드에 표시하고 가입 완료로 이동하지 않는다', (tester) async {
    final adapter = TestAuthAdapter();
    final auth = (await tester.runAsync(() => testAuth(adapter: adapter)))!;
    addTearDown(auth.dispose);
    final router = createAppRouter(initialLocation: '/sign-up');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(CobipApp(router: router), auth: auth);
    await tester.pumpAndSettle();
    await fillSignUp(tester);
    adapter.handle = (_) async =>
        jsonResponse({'code': 'NICKNAME_ALREADY_USED'}, 409);
    await tapVisible(tester, find.byKey(const Key('signUpSubmitButton')));
    await reveal(
      tester,
      find.byKey(const Key('signUpNicknameField')),
      upward: true,
    );
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('signUpNicknameField')),
              matching: find.byType(TextField),
            ),
          )
          .decoration
          ?.errorText,
      '이미 사용 중인 닉네임입니다.',
    );
    expect(router.routeInformationProvider.value.uri.path, '/sign-up');
  });

  testWidgets('보호 화면 직접 접근은 로그인으로 보내고 로그인 성공 후 홈을 연다', (tester) async {
    final adapter = TestAuthAdapter();
    final auth = (await tester.runAsync(() => testAuth(adapter: adapter)))!;
    addTearDown(auth.dispose);
    final router = createAppRouter(initialLocation: '/grammar/java/chapters');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(CobipApp(router: router), auth: auth);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    await tester.enterText(
      find.byType(TextFormField).first,
      'member@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password-123');
    await tapVisible(tester, find.widgetWithText(FilledButton, '로그인'));
    expect(router.routeInformationProvider.value.uri.path, '/home');
    expect(auth.user?.nickname, '테스트학습자');
    router.go('/my-page');
    await tester.pumpAndSettle();
    expect(find.text('테스트학습자'), findsOneWidget);
    expect(find.text('영진'), findsNothing);
    await tapVisible(tester, find.text('계정 관리'));
    expect(find.text('닉네임: 테스트학습자'), findsOneWidget);
    await tapVisible(tester, find.text('로그아웃'));
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(auth.user, isNull);
    expect(adapter.requests.last.path, '/api/auth/logout');
  });

  testWidgets('로그인 실패와 늦은 로그인 응답은 홈을 열지 않는다', (tester) async {
    final adapter = TestAuthAdapter(
      handle: (_) async => jsonResponse({'code': 'INVALID_CREDENTIALS'}, 401),
    );
    final auth = (await tester.runAsync(() => testAuth(adapter: adapter)))!;
    addTearDown(auth.dispose);
    final router = createAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWithAuth(CobipApp(router: router), auth: auth);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'member@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'wrong');
    await tapVisible(tester, find.widgetWithText(FilledButton, '로그인'));
    expect(find.text('이메일 또는 비밀번호를 확인해 주세요.'), findsOneWidget);
    expect(auth.isAuthenticated, isFalse);
    final login = Completer<ResponseBody>();
    adapter.handle = (_) => login.future;
    await tapVisible(
      tester,
      find.widgetWithText(FilledButton, '로그인'),
      settle: false,
    );
    router.go('/sign-up');
    await tester.pump();
    login.complete(jsonResponse(testTokens(), 200));
    await drainAuth(tester);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/sign-up');
    expect(auth.isAuthenticated, isFalse);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('비밀번호 재설정은 204 이후 완료와 기존 세션 정리를 수행한다', (tester) async {
    final adapter = TestAuthAdapter();
    final auth = (await tester.runAsync(
      () => testAuth(adapter: adapter, authenticated: true),
    ))!;
    addTearDown(auth.dispose);
    final router = createAppRouter(initialLocation: '/password-reset');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(CobipApp(router: router), auth: auth);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('resetEmailField')),
      'member@example.com',
    );
    await tester.pump();
    await tapVisible(tester, find.text('인증번호 받기'));
    await tester.enterText(find.byKey(const Key('resetCodeField')), '012345');
    await tapVisible(tester, find.text('인증 확인'));
    for (final key in ['newPasswordField', 'newPasswordConfirmationField']) {
      final field = find.byKey(Key(key));
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, 'new-password-123');
    }
    tester.testTextInput.hide();
    await tester.pump();
    final complete = Completer<ResponseBody>();
    adapter.handle = (_) => complete.future;
    await tapVisible(tester, find.text('비밀번호 변경'), settle: false);
    expect(router.routeInformationProvider.value.uri.path, '/password-reset');
    expect(auth.isAuthenticated, isTrue);
    complete.complete(jsonResponse(null, 204));
    await drainAuth(tester);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/password-reset/complete',
    );
    expect(auth.isAuthenticated, isFalse);
    await tapVisible(tester, find.text('로그인하기'));
    expect(router.routeInformationProvider.value.uri.path, '/login');
  });

  testWidgets('503 및 네트워크 오류는 발송·가입 성공으로 처리하지 않는다', (tester) async {
    final adapter = TestAuthAdapter(
      handle: (_) async => jsonResponse({'code': 'MAIL_UNAVAILABLE'}, 503),
    );
    final auth = (await tester.runAsync(() => testAuth(adapter: adapter)))!;
    addTearDown(auth.dispose);
    final router = createAppRouter(initialLocation: '/sign-up');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(CobipApp(router: router), auth: auth);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'member@example.com',
    );
    await tester.pump();
    await tapVisible(tester, find.text('인증 요청'));
    expect(find.text('현재 인증 메일을 보낼 수 없습니다. 잠시 후 다시 시도해 주세요.'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('signUpCodeField')))
          .enabled,
      isFalse,
    );
    adapter.handle = (options) async => throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
    await tapVisible(tester, find.text('인증 요청'));
    expect(find.text('서버에 연결할 수 없습니다. 네트워크와 API 주소를 확인해 주세요.'), findsOneWidget);
    await reveal(tester, find.byKey(const Key('signUpSubmitButton')));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('signUpSubmitButton')))
          .onPressed,
      isNull,
    );
    expect(router.routeInformationProvider.value.uri.path, '/sign-up');
  });

  testWidgets('다른 화면으로 이동한 뒤 도착한 가입 응답은 완료 화면을 열지 않는다', (tester) async {
    final adapter = TestAuthAdapter();
    final auth = (await tester.runAsync(() => testAuth(adapter: adapter)))!;
    addTearDown(auth.dispose);
    final router = createAppRouter(initialLocation: '/sign-up');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(CobipApp(router: router), auth: auth);
    await tester.pumpAndSettle();
    await fillSignUp(tester);
    final register = Completer<ResponseBody>();
    adapter.handle = (_) => register.future;
    await tapVisible(
      tester,
      find.byKey(const Key('signUpSubmitButton')),
      settle: false,
    );
    expect(adapter.requests.last.path, '/api/auth/register');
    router.go('/login');
    await tester.pumpAndSettle();
    register.complete(jsonResponse(testUser, 201));
    await drainAuth(tester);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(auth.isAuthenticated, isFalse);
    expect(tester.takeException(), isNull);
  });
}

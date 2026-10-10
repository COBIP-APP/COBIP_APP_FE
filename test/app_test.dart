import 'dart:async';

import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/app_ui_tokens.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/auth/presentation/password_reset_screen.dart';
import 'package:cobip_app_fe/features/auth/presentation/login_screen.dart';
import 'package:cobip_app_fe/features/auth/presentation/password_reset_complete_screen.dart';
import 'package:cobip_app_fe/features/auth/presentation/sign_up_complete_screen.dart';
import 'package:cobip_app_fe/features/auth/presentation/sign_up_screen.dart';
import 'package:cobip_app_fe/features/auth/presentation/terms_screen.dart';
import 'package:cobip_app_fe/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cobip_app_fe/features/auth/presentation/auth_view_model.dart';
import 'package:dio/dio.dart';

import 'auth_test_support.dart';

void main() {
  testWidgets('로그인 화면에서 비밀번호 찾기로 이동한다', (tester) async {
    appRouter.go('/login');
    await tester.pumpWithAuth(const CobipApp());

    expect(find.text('다시 만나 반가워요'), findsOneWidget);

    await tester.tap(find.text('비밀번호 찾기'));
    await tester.pumpAndSettle();

    expect(find.text('가입한 이메일을 입력해 주세요'), findsOneWidget);
  });

  testWidgets('비밀번호 찾기 인증과 새 비밀번호 일치를 검증한다', (tester) async {
    await tester.pumpWithAuth(const MaterialApp(home: PasswordResetScreen()));

    await tester.enterText(
      find.byKey(const Key('resetEmailField')),
      'member@example.com',
    );
    await tester.pump();
    await tester.tap(find.text('인증번호 받기'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('resetCodeField')), '123');
    tester.testTextInput.hide();
    await tester.scrollUntilVisible(
      find.text('인증 확인'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('인증 확인'));
    await tester.pump();
    expect(find.text('인증번호 6자리를 입력해 주세요'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('resetCodeField')), '123456');
    tester.testTextInput.hide();
    await tester.scrollUntilVisible(
      find.text('인증 확인'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('인증 확인'));
    await tester.pumpAndSettle();
    expect(find.text('새 비밀번호를 설정해 주세요'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'password');
    await tester.enterText(find.byType(TextFormField).last, 'different');
    tester.testTextInput.hide();
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('비밀번호 변경'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('비밀번호가 일치하지 않습니다'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '비밀번호 변경'))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextFormField).last, 'password');
    await tester.pump();
    expect(find.text('비밀번호가 일치합니다'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '비밀번호 변경'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('회원가입 버튼은 필수 조건이 모두 충족될 때 활성화된다', (tester) async {
    await tester.pumpWithAuth(const MaterialApp(home: SignUpScreen()));

    await tester.enterText(
      find.byType(TextFormField).first,
      'member@example.com',
    );
    await tester.pump();
    await tester.tap(find.text('인증 요청'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('signUpCodeField')), '12ab34');
    await tester.tap(find.text('확인'));
    await tester.pump();
    expect(find.text('인증번호 6자리를 입력해 주세요'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('signUpCodeField')), '123456');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();

    FilledButton submitButton = tester.widget(
      find.byKey(const Key('signUpSubmitButton')),
    );
    expect(submitButton.onPressed, isNull);

    await tester.scrollUntilVisible(
      find.byKey(const Key('signUpNicknameField')),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('signUpNicknameField')),
      '테스트학습자',
    );

    await tester.enterText(
      find.byKey(const Key('signUpPasswordField')),
      'password',
    );
    await tester.enterText(
      find.byKey(const Key('signUpPasswordConfirmationField')),
      'password',
    );
    tester.testTextInput.hide();
    await tester.pump();
    final allTermsCheckbox = tester.widget<Checkbox>(
      find.byType(Checkbox).first,
    );
    allTermsCheckbox.onChanged!(true);
    await tester.pump();

    submitButton = tester.widget(find.byKey(const Key('signUpSubmitButton')));
    expect(submitButton.onPressed, isNotNull);

    tester.widget<Checkbox>(find.byType(Checkbox).at(1)).onChanged!(false);
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('signUpSubmitButton')))
          .onPressed,
      isNull,
    );
    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isFalse);

    final emailField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.keyboardType == TextInputType.emailAddress,
    );
    await tester.scrollUntilVisible(
      emailField,
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(emailField, 'changed@example.com');
    await tester.pumpAndSettle();
    expect(find.text('이메일 인증이 완료되었습니다.'), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('signUpCodeField')))
          .controller!
          .text,
      isEmpty,
    );

    await tester.tap(find.text('인증 요청'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('signUpCodeField')), '123');
    tester.testTextInput.hide();
    await tester.advanceAuthTime(
      find.byType(SignUpScreen),
      const Duration(seconds: 61),
    );
    final adapter =
        tester
                .element(find.byType(SignUpScreen))
                .read<AuthViewModel>()
                .api
                .dio
                .httpClientAdapter
            as TestAuthAdapter;
    final resend = Completer<ResponseBody>();
    adapter.handle = (_) => resend.future;
    await tester.tap(find.text('재전송'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('signUpCodeField')))
          .controller!
          .text,
      isEmpty,
    );
    resend.complete(
      jsonResponse({
        'message': '메일함을 확인해 주세요.',
        'expiresInSeconds': 300,
        'resendAfterSeconds': 60,
      }, 202),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('메인화면은 빈 상태와 실패 후 재시도를 표시한다', (tester) async {
    final adapter = TestAuthAdapter();
    final auth = (await tester.runAsync(
      () => testAuth(authenticated: true, adapter: adapter),
    ))!;
    addTearDown(auth.dispose);
    await tester.pumpWithAuth(
      const MaterialApp(home: HomeScreen(key: ValueKey('emptyHome'))),
      auth: auth,
    );
    await tester.pumpAndSettle();
    expect(find.text('등록된 학습이 없어요'), findsOneWidget);

    adapter.handle = (_) async => jsonResponse({'status': 503}, 503);
    await tester.pumpWithAuth(
      const MaterialApp(home: HomeScreen(key: ValueKey('errorHome'))),
      auth: auth,
    );
    await tester.pumpAndSettle();
    expect(find.text('학습 정보를 불러오지 못했어요'), findsOneWidget);

    adapter.handle = (_) async => jsonResponse([], 200);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('등록된 학습이 없어요'), findsOneWidget);
    expect(find.text('학습 정보를 불러오지 못했어요'), findsNothing);
    expect(
      adapter.requests.where((request) => request.path == '/api/templates'),
      hasLength(3),
    );
  });

  testWidgets('계정 전환 뒤 늦은 이전 계정 응답을 홈에 표시하지 않는다', (tester) async {
    final adapter = TestAuthAdapter();
    final auth = (await tester.runAsync(
      () => testAuth(authenticated: true, adapter: adapter),
    ))!;
    addTearDown(auth.dispose);
    final oldResponse = Completer<ResponseBody>();
    adapter.handle = (options) async {
      if (options.path == '/api/auth/login') {
        return jsonResponse({
          ...testTokens(2),
          'user': {...testUser, 'userId': 2},
        }, 200);
      }
      if (options.path == '/api/templates') {
        if (options.headers['Authorization'] == 'Bearer test-access-1') {
          return oldResponse.future;
        }
        return jsonResponse([
          {'id': 43, 'title': '새 계정 학습', 'published': true},
        ], 200);
      }
      return jsonResponse({'status': 404}, 404);
    };
    await tester.pumpWithAuth(
      const MaterialApp(home: HomeScreen()),
      auth: auth,
    );
    await tester.pumpAndSettle();
    expect(adapter.requests.last.path, '/api/templates');
    expect(
      await tester.runAsync(
        () => auth.login('other@example.com', 'password-123'),
      ),
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(find.text('새 계정 학습'), findsOneWidget);
    expect(find.text('아직 시작한 학습이 없어요'), findsOneWidget);
    oldResponse.complete(
      jsonResponse([
        {'id': 42, 'title': '이전 계정 학습', 'published': true},
      ], 200),
    );
    await tester.pumpAndSettle();
    expect(find.text('새 계정 학습'), findsOneWidget);
    expect(find.text('이전 계정 학습'), findsNothing);
    expect(
      adapter.requests.any(
        (request) => request.path == '/api/users/2/progress/templates/43',
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  for (final layout in [
    (const Size(360, 800), 1.0, 0.0),
    (const Size(320, 640), 1.0, 0.0),
    (const Size(320, 640), 2.0, 0.0),
    (const Size(360, 800), 1.0, 260.0),
    (const Size(640, 320), 1.0, 0.0),
    (const Size(640, 320), 1.0, 140.0),
  ]) {
    for (final screen in const <Widget>[
      LoginScreen(),
      SignUpScreen(),
      TermsScreen(type: 'service'),
      TermsScreen(type: 'privacy'),
      SignUpCompleteScreen(),
      PasswordResetScreen(),
      PasswordResetCompleteScreen(),
      HomeScreen(),
    ]) {
      testWidgets(
        '${screen.runtimeType} ${screen is TermsScreen ? screen.type : ''} ${layout.$1} 글씨 ${layout.$2} 키보드 ${layout.$3}',
        (tester) async {
          tester.view.physicalSize = layout.$1;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWithAuth(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(layout.$2),
                  viewInsets: EdgeInsets.only(bottom: layout.$3),
                ),
                child: child!,
              ),
              home: screen,
            ),
            authenticated: screen is HomeScreen,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (screen is TermsScreen) {
            await tester.scrollUntilVisible(
              find.widgetWithText(FilledButton, '닫기'),
              200,
            );
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  testWidgets('로그인 공통 토큰과 링크 순서가 컨벤션과 일치한다', (tester) async {
    await tester.pumpWithAuth(const MaterialApp(home: LoginScreen()));
    final theme = Theme.of(tester.element(find.byType(TextFormField).first));
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.appBarTheme.titleTextStyle!.color, AppColors.textPrimary);
    expect(theme.inputDecorationTheme.enabledBorder!.borderSide.width, 1);
    expect(theme.inputDecorationTheme.focusedBorder!.borderSide.width, 2);
    expect(
      tester.getTopLeft(find.text('비밀번호 찾기')).dy,
      lessThan(tester.getTopLeft(find.widgetWithText(FilledButton, '로그인')).dy),
    );
    expect(
      tester.getTopLeft(find.widgetWithText(FilledButton, '로그인')).dy,
      lessThan(tester.getTopLeft(find.text('회원가입 하기')).dy),
    );
    expect(find.text('COBIA'), findsOneWidget);
  });

  testWidgets('회원가입 완료는 홈이 아닌 로그인으로 이동한다', (tester) async {
    final router = createAppRouter(initialLocation: '/sign-up/complete');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('로그인하기'));
    await tester.tap(find.text('로그인하기'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');
  });

  testWidgets('새 비밀번호는 200% 글씨에서 입력·일치·뒤로가기가 동작한다', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWithAuth(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const PasswordResetScreen(),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('resetEmailField')),
      'member@example.com',
    );
    tester.testTextInput.hide();
    await tester.scrollUntilVisible(
      find.text('인증번호 받기'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('인증번호 받기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('resetCodeField')), '123456');
    tester.testTextInput.hide();
    await tester.scrollUntilVisible(
      find.text('인증 확인'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('인증 확인'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('newPasswordField')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('newPasswordField')),
      'password',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('newPasswordConfirmationField')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('newPasswordConfirmationField')),
      'password',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('비밀번호 변경'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('비밀번호가 일치합니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('resetCodeField')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('resetCodeField')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('resetCodeField')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('홈은 서버 학습과 위치를 표시하고 샘플 상세로 이동하지 않는다', (tester) async {
    final adapter = TestAuthAdapter();
    final auth = (await tester.runAsync(
      () => testAuth(authenticated: true, adapter: adapter),
    ))!;
    addTearDown(auth.dispose);
    adapter.handle = (options) async => options.path == '/api/templates'
        ? jsonResponse([
            {
              'id': 42,
              'title': '서버에서 받은 학습',
              'summary': '서버에서 받은 설명',
              'categoryCode': 'GRAMMAR',
              'categoryName': '문법 학습',
              'languageCode': 'python',
              'languageName': 'Python',
              'published': true,
            },
          ], 200)
        : jsonResponse({
            'userId': 1,
            'templateId': 42,
            'lastSectionId': 101,
            'startedAt': '2026-10-01T09:00:00Z',
            'lastStudiedAt': '2026-10-10T10:00:00Z',
            'completedAt': null,
          }, 200);
    final router = createAppRouter(initialLocation: '/home');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(
      MaterialApp.router(routerConfig: router),
      auth: auth,
    );
    await tester.pumpAndSettle();
    expect(find.text('서버에서 받은 학습'), findsNWidgets(2));
    expect(find.text('마지막 위치: 섹션 101'), findsOneWidget);
    expect(find.text('학습 중'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('현재 학습 기록은 UI 확인용 예시입니다.'), findsNothing);
    expect(
      adapter.requests.any(
        (request) =>
            request.path == '/api/users/1/progress/templates/42' &&
            request.headers['Authorization'] == 'Bearer test-access-1',
      ),
      isTrue,
    );
    await tester.tap(find.text('학습 상세 연결 준비 중'));
    await tester.pumpAndSettle();
    expect(find.text('학습 상세 화면의 서버 연동은 준비 중입니다.'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/home');
    ScaffoldMessenger.of(tester.element(find.byType(HomeScreen)))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();
    expect(find.text('학습 상세 화면의 서버 연동은 준비 중입니다.'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('서버에서 받은 학습').last,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(
      find.byKey(const Key('homeContentList')),
      const Offset(0, -140),
    );
    await tester.pumpAndSettle();
    final recommendation = find.text('서버에서 받은 학습').last.hitTestable();
    expect(recommendation, findsOneWidget);
    await tester.tap(recommendation);
    await tester.pumpAndSettle();
    expect(find.text('학습 상세 화면의 서버 연동은 준비 중입니다.'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/home');
  });

  for (final (size, textScale) in [
    (const Size(320, 640), 2.0),
    (const Size(640, 320), 1.0),
  ]) {
    testWidgets('서버 학습이 있는 홈 $size 글씨 $textScale에서 넘침이 없다', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final adapter = TestAuthAdapter();
      final auth = (await tester.runAsync(
        () => testAuth(authenticated: true, adapter: adapter),
      ))!;
      addTearDown(auth.dispose);
      adapter.handle = (options) async => options.path == '/api/templates'
          ? jsonResponse([
              {
                'id': 42,
                'title': '서버 학습의 긴 제목으로 반응형 배치를 확인합니다',
                'summary': '서버에서 받은 긴 설명으로 작은 화면의 줄바꿈을 확인합니다.',
                'categoryName': '프로그래밍 문법',
                'languageName': 'Python',
                'published': true,
              },
            ], 200)
          : jsonResponse({
              'userId': 1,
              'templateId': 42,
              'lastSectionId': 101,
              'startedAt': '2026-10-01T09:00:00Z',
              'lastStudiedAt': '2026-10-10T10:00:00Z',
              'completedAt': '2026-10-10T10:00:00Z',
            }, 200);
      await tester.pumpWithAuth(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const HomeScreen(),
        ),
        auth: auth,
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('학습 완료'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('학습 완료'), findsOneWidget);
      expect(find.text('마지막 위치: 섹션 101'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('서버 학습의 긴 제목으로 반응형 배치를 확인합니다').last,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('학습 정보를 불러오지 못했어요'), findsNothing);
    });
  }
}

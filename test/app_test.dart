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

void main() {
  testWidgets('로그인 화면에서 비밀번호 찾기로 이동한다', (tester) async {
    appRouter.go('/login');
    await tester.pumpWidget(const CobipApp());

    expect(find.text('다시 만나 반가워요'), findsOneWidget);

    await tester.tap(find.text('비밀번호 찾기'));
    await tester.pumpAndSettle();

    expect(find.text('가입한 이메일을 입력해 주세요'), findsOneWidget);
  });

  testWidgets('비밀번호 찾기 인증과 새 비밀번호 일치를 검증한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PasswordResetScreen()));

    await tester.enterText(
      find.byKey(const Key('resetEmailField')),
      'member@example.com',
    );
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
    await tester.pump();
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
    await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));

    await tester.enterText(
      find.byType(TextFormField).first,
      'member@example.com',
    );
    await tester.tap(find.text('인증 요청'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('signUpCodeField')), '12ab34');
    await tester.tap(find.text('확인'));
    await tester.pump();
    expect(find.text('인증번호 6자리를 입력해 주세요'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('signUpCodeField')), '123456');
    await tester.tap(find.text('확인'));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();

    FilledButton submitButton = tester.widget(
      find.byKey(const Key('signUpSubmitButton')),
    );
    expect(submitButton.onPressed, isNull);

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
    await tester.pumpAndSettle();
  });

  testWidgets('메인화면은 빈 상태와 실패 후 재시도를 표시한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(
          key: ValueKey('emptyHome'),
          initialContentState: HomeContentState.empty,
        ),
      ),
    );
    expect(find.text('아직 시작한 학습이 없어요'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(
          key: ValueKey('errorHome'),
          initialContentState: HomeContentState.error,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('학습 정보를 불러오지 못했어요'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('학습 추천'), findsOneWidget);
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
          await tester.pumpWidget(
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
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
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
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
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
    await tester.pumpWidget(
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

  testWidgets('홈 이어하기와 세 추천 카드는 기존 경로로 연결된다', (tester) async {
    final router = createAppRouter(initialLocation: '/home');
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('완료 1 / 3 단계'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      1 / 3,
    );
    await tester.tap(find.text('이어하기 →'));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.last.route.name,
      AppRouteNames.grammarExample,
    );
    for (final entry in [
      ('조건문 기본 원리', AppRouteNames.grammar),
      ('실무 기술 학습', AppRouteNames.practical),
      ('문제로 복습하기', AppRouteNames.problems),
    ]) {
      router.go('/home');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(entry.$1),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.$1));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.last.route.name,
        entry.$2,
      );
    }
  });
}

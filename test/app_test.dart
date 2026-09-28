import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/auth/presentation/password_reset_screen.dart';
import 'package:cobip_app_fe/features/auth/presentation/sign_up_screen.dart';
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

  testWidgets('비밀번호 찾기에서 인증번호를 검증한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PasswordResetScreen()));

    await tester.enterText(
      find.byKey(const Key('resetEmailField')),
      'member@example.com',
    );
    await tester.tap(find.text('인증번호 받기'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('resetCodeField')), '123');
    await tester.tap(find.text('인증 확인'));
    await tester.pump();
    expect(find.text('인증번호 6자리를 입력해 주세요'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('resetCodeField')), '123456');
    await tester.tap(find.text('인증 확인'));
    await tester.pump();
    expect(find.text('새 비밀번호를 설정해 주세요'), findsOneWidget);
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
}

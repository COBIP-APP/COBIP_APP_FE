import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_flow_test.dart' show fillSignUp, reveal, tapVisible;
import 'auth_test_support.dart';

void main() {
  testWidgets('8개 담당 화면의 실제 위젯과 가입·재설정 완료 흐름을 렌더링한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final adapter = TestAuthAdapter();
    final auth = (await tester.runAsync(() => testAuth(adapter: adapter)))!;
    addTearDown(auth.dispose);
    final router = createAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(CobipApp(auth: auth, router: router));
    await tester.pumpAndSettle();

    Future<void> checkScreen() async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await checkScreen();
    router.go('/sign-up');
    await tester.pumpAndSettle();
    await checkScreen();
    router.pushNamed(AppRouteNames.terms, pathParameters: {'type': 'service'});
    await tester.pumpAndSettle();
    await checkScreen();
    router.pop();
    await tester.pumpAndSettle();
    await fillSignUp(tester);
    await tapVisible(tester, find.byKey(const Key('signUpSubmitButton')));
    expect(router.routeInformationProvider.value.uri.path, '/sign-up/complete');
    await checkScreen();
    await tapVisible(tester, find.text('로그인하기'));
    await tester.enterText(
      find.byType(TextFormField).first,
      'member@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password-123');
    await tapVisible(tester, find.widgetWithText(FilledButton, '로그인'));
    expect(router.routeInformationProvider.value.uri.path, '/home');
    await checkScreen();
    router.go('/password-reset');
    await tester.pumpAndSettle();
    await checkScreen();
    await tester.enterText(
      find.byKey(const Key('resetEmailField')),
      'member@example.com',
    );
    await tester.pump();
    await tapVisible(tester, find.text('인증번호 받기'));
    await tester.enterText(find.byKey(const Key('resetCodeField')), '012345');
    await tapVisible(tester, find.text('인증 확인'));
    for (final key in ['newPasswordField', 'newPasswordConfirmationField']) {
      await reveal(tester, find.byKey(Key(key)));
      await tester.enterText(find.byKey(Key(key)), 'new-password-123');
    }
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await checkScreen();
    await tapVisible(tester, find.text('비밀번호 변경'));
    expect(
      router.routeInformationProvider.value.uri.path,
      '/password-reset/complete',
    );
    await checkScreen();
  });
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import 'auth_widgets.dart';

class SignUpCompleteScreen extends StatelessWidget {
  const SignUpCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      decorated: true,
      body: AuthCompletionBody(
        illustration: 'sign_up_complete',
        title: '가입을 환영해요!',
        subtitle: 'COBIA와 함께 첫 학습을 시작해 보세요.',
        note: '로그인하고 학습을 시작해 주세요.',
        buttonLabel: '로그인하기',
        onContinue: () => context.goNamed(AppRouteNames.login),
      ),
    );
  }
}

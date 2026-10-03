import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import 'auth_widgets.dart';

class PasswordResetCompleteScreen extends StatelessWidget {
  const PasswordResetCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      appBar: AppBar(
        title: const Text('비밀번호 찾기'),
        leading: BackButton(
          onPressed: () => context.goNamed(AppRouteNames.login),
        ),
      ),
      decorated: true,
      body: AuthCompletionBody(
        illustration: 'password_complete',
        title: '비밀번호 변경 완료',
        subtitle: '비밀번호가 변경되었습니다.',
        note: '새 비밀번호로 다시 로그인해 주세요.',
        buttonLabel: '로그인하기',
        onContinue: () => context.goNamed(AppRouteNames.login),
      ),
    );
  }
}

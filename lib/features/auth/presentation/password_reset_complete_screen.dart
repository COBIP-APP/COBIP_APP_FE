import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';

class PasswordResetCompleteScreen extends StatelessWidget {
  const PasswordResetCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 96,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  '비밀번호 변경 완료',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('새 비밀번호로 다시 로그인해 주세요.'),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => context.goNamed(AppRouteNames.login),
                  child: const Text('로그인하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

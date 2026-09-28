import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';

class SignUpCompleteScreen extends StatelessWidget {
  const SignUpCompleteScreen({super.key});

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
                  Icons.verified_rounded,
                  size: 96,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  '가입을 환영해요!',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('COBIP과 함께 첫 학습을 시작해 보세요.'),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => context.goNamed(AppRouteNames.home),
                  child: const Text('학습 시작하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

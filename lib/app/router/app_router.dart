import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/password_reset_complete_screen.dart';
import '../../features/auth/presentation/password_reset_screen.dart';
import '../../features/auth/presentation/sign_up_complete_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/auth/presentation/terms_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/grammar/presentation/grammar_home_screen.dart';

abstract final class AppRouteNames {
  static const login = 'login';
  static const passwordReset = 'password-reset';
  static const passwordResetComplete = 'password-reset-complete';
  static const signUp = 'sign-up';
  static const signUpComplete = 'sign-up-complete';
  static const terms = 'terms';
  static const home = 'home';
  static const grammar = 'grammar';
}

final appRouter = GoRouter(
  initialLocation: '/login',
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: FilledButton(
        onPressed: () => context.goNamed(AppRouteNames.login),
        child: const Text('로그인으로 이동'),
      ),
    ),
  ),
  routes: [
    GoRoute(
      path: '/grammar',
      name: AppRouteNames.grammar,
      builder: (context, state) => const GrammarHomeScreen(),
    ),
    GoRoute(
      path: '/login',
      name: AppRouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/sign-up',
      name: AppRouteNames.signUp,
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/password-reset',
      name: AppRouteNames.passwordReset,
      builder: (context, state) => const PasswordResetScreen(),
    ),
    GoRoute(
      path: '/password-reset/complete',
      name: AppRouteNames.passwordResetComplete,
      builder: (context, state) => const PasswordResetCompleteScreen(),
    ),
    GoRoute(
      path: '/sign-up/complete',
      name: AppRouteNames.signUpComplete,
      builder: (context, state) => const SignUpCompleteScreen(),
    ),
    GoRoute(
      path: '/terms/:type',
      name: AppRouteNames.terms,
      builder: (context, state) =>
          TermsScreen(type: state.pathParameters['type']!),
    ),
    GoRoute(
      path: '/home',
      name: AppRouteNames.home,
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);

import '../../features/chat/presentation/chat_screen.dart';
import '../../features/problems/data/problem_sample_data.dart';
import '../../features/problems/presentation/problems_home_screen.dart';
import '../../features/problems/presentation/problem_mission_screen.dart';
import '../../features/practical/presentation/practical_chapter_screen.dart';
import '../../features/practical/data/practical_sample_data.dart';
import '../../features/practical/presentation/practical_chapters_screen.dart';
import '../../features/practical/presentation/practical_home_screen.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/auth_view_model.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/password_reset_complete_screen.dart';
import '../../features/auth/presentation/password_reset_screen.dart';
import '../../features/auth/presentation/sign_up_complete_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/auth/presentation/terms_screen.dart';
import '../../features/grammar/data/grammar_sample_data.dart';
import '../../features/grammar/presentation/grammar_chapters_screen.dart';
import '../../features/grammar/presentation/grammar_home_screen.dart';
import '../../features/grammar/presentation/grammar_quiz_screen.dart';
import '../../features/grammar/presentation/grammar_concept_screen.dart';
import '../../features/grammar/presentation/grammar_example_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/my_page/presentation/my_page_screen.dart';

abstract final class AppRouteNames {
  static const chat = 'chat';
  static const login = 'login';
  static const passwordReset = 'password-reset';
  static const passwordResetComplete = 'password-reset-complete';
  static const signUp = 'sign-up';
  static const signUpComplete = 'sign-up-complete';
  static const terms = 'terms';
  static const problems = 'problems';
  static const problemMission = 'problem-mission';
  static const home = 'home';
  static const myPage = 'my-page';
  static const practical = 'practical';
  static const practicalChapters = 'practical-chapters';
  static const practicalChapter = 'practical-chapter';
  static const grammar = 'grammar';
  static const grammarChapters = 'grammar-chapters';
  static const grammarConcept = 'grammar-concept';
  static const grammarExample = 'grammar-example';
  static const grammarQuiz = 'grammar-quiz';
}

// 새 챕터의 상세 경로를 여기에 등록하면 메인과 전체 목록에 함께 연결됩니다.
final grammarChapterRoutes = <String, GoRoute>{
  'conditions': GoRoute(
    path: 'conditions',
    name: AppRouteNames.grammarConcept,
    routes: [
      GoRoute(
        path: 'example',
        name: AppRouteNames.grammarExample,
        routes: [
          GoRoute(
            path: 'quiz',
            name: AppRouteNames.grammarQuiz,
            builder: (context, state) => GrammarQuizScreen(
              language: GrammarLanguage.fromId(
                state.pathParameters['language']!,
              )!,
            ),
          ),
        ],
        builder: (context, state) => GrammarExampleScreen(
          language: GrammarLanguage.fromId(state.pathParameters['language']!)!,
        ),
      ),
    ],
    builder: (context, state) => GrammarConceptScreen(
      language: GrammarLanguage.fromId(state.pathParameters['language']!)!,
    ),
  ),
};

void openGrammarChapter(
  BuildContext context,
  GrammarLanguage language,
  GrammarChapter chapter,
) {
  final route = grammarChapterRoutes[chapter.id];
  if (route == null) return;
  FocusScope.of(context).unfocus();
  // 중첩 경로가 메인 → 전체 목록 → 상세의 뒤로가기 순서를 구성합니다.
  context.goNamed(route.name!, pathParameters: {'language': language.id});
}

final appRouter = createAppRouter();

GoRouter createAppRouter({String initialLocation = '/login'}) => GoRouter(
  initialLocation: initialLocation,
  redirect: (context, state) {
    final auth = context.read<AuthViewModel?>();
    final path = state.uri.path;
    const publicPaths = [
      '/login',
      '/sign-up',
      '/sign-up/complete',
      '/password-reset',
      '/password-reset/complete',
    ];
    final isPublic = publicPaths.contains(path) || path.startsWith('/terms/');
    if (auth?.isRestoring == true) {
      return path == '/session-loading'
          ? null
          : '/session-loading?from=${Uri.encodeComponent(state.uri.toString())}';
    }
    if (path == '/session-loading') {
      final from = state.uri.queryParameters['from'] ?? '/home';
      final destination = Uri.tryParse(from);
      if (auth?.isAuthenticated != true) return '/login';
      return destination != null &&
              !destination.hasAuthority &&
              from.startsWith('/') &&
              !publicPaths.contains(destination.path) &&
              destination.path != '/session-loading'
          ? from
          : '/home';
    }
    if (!isPublic && auth?.isAuthenticated != true) return '/login';
    if (auth?.isAuthenticated == true &&
        (path == '/login' || path == '/sign-up')) {
      return '/home';
    }
    return null;
  },
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
      path: '/session-loading',
      builder: (_, _) =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
    GoRoute(
      path: '/chat',
      name: AppRouteNames.chat,
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: '/problems',
      name: AppRouteNames.problems,
      builder: (context, state) => const ProblemsHomeScreen(),
      routes: [
        GoRoute(
          path: ':mission',
          name: AppRouteNames.problemMission,
          redirect: (context, state) =>
              ProblemMission.fromId(state.pathParameters['mission']) == null
              ? '/problems'
              : null,
          builder: (context, state) => ProblemMissionScreen(
            key: ValueKey(state.pathParameters['mission']),
            mission: ProblemMission.fromId(state.pathParameters['mission'])!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/my-page',
      name: AppRouteNames.myPage,
      builder: (context, state) => const MyPageScreen(),
    ),
    GoRoute(
      path: '/practical',
      name: AppRouteNames.practical,
      routes: [
        GoRoute(
          path: ':topic/chapters',
          name: AppRouteNames.practicalChapters,
          routes: [
            GoRoute(
              path: ':chapter',
              name: AppRouteNames.practicalChapter,
              redirect: (context, state) {
                final topic = PracticalTopic.fromId(
                  state.pathParameters['topic'],
                );
                if (topic == null) return '/practical';
                return topic.chapters.any(
                      (chapter) =>
                          chapter.id == state.pathParameters['chapter'],
                    )
                    ? null
                    : '/practical/${topic.id}/chapters';
              },
              builder: (context, state) {
                final topic = PracticalTopic.fromId(
                  state.pathParameters['topic'],
                )!;
                return PracticalChapterScreen(
                  topic: topic,
                  chapterIndex: topic.chapters.indexWhere(
                    (chapter) => chapter.id == state.pathParameters['chapter'],
                  ),
                );
              },
            ),
          ],
          redirect: (context, state) =>
              PracticalTopic.fromId(state.pathParameters['topic']) == null
              ? '/practical'
              : null,
          builder: (context, state) => PracticalChaptersScreen(
            topic: PracticalTopic.fromId(state.pathParameters['topic'])!,
          ),
        ),
      ],
      builder: (context, state) => const PracticalHomeScreen(),
    ),
    GoRoute(
      path: '/grammar',
      name: AppRouteNames.grammar,
      builder: (context, state) => const GrammarHomeScreen(),
      routes: [
        GoRoute(
          path: ':language/chapters',
          name: AppRouteNames.grammarChapters,
          routes: grammarChapterRoutes.values.toList(),
          redirect: (context, state) =>
              GrammarLanguage.fromId(state.pathParameters['language']!) == null
              ? '/grammar'
              : null,
          builder: (context, state) {
            return GrammarChaptersScreen(
              language: GrammarLanguage.fromId(
                state.pathParameters['language']!,
              )!,
            );
          },
        ),
      ],
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

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

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/password_reset_complete_screen.dart';
import '../../features/auth/presentation/password_reset_screen.dart';
import '../../features/auth/presentation/sign_up_complete_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/auth/presentation/terms_screen.dart';
import '../../features/grammar/data/grammar_sample_data.dart';
import '../../features/grammar/presentation/grammar_chapters_screen.dart';
import '../../features/grammar/presentation/grammar_chapter_screen.dart';
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
  static const grammarChapter = 'grammar-chapter';
  static const grammarConcept = 'grammar-concept';
  static const grammarExample = 'grammar-example';
  static const grammarQuiz = 'grammar-quiz';
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
          routes: [
            GoRoute(
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
                    language: GrammarLanguage.fromId(
                      state.pathParameters['language']!,
                    )!,
                  ),
                ),
              ],
              builder: (context, state) => GrammarConceptScreen(
                language: GrammarLanguage.fromId(
                  state.pathParameters['language']!,
                )!,
              ),
            ),
            GoRoute(
              path: ':chapter',
              name: AppRouteNames.grammarChapter,
              redirect: (context, state) {
                final language = GrammarLanguage.fromId(
                  state.pathParameters['language']!,
                );
                if (language == null) return '/grammar';
                return grammarSampleChapters[language]!.any(
                      (chapter) => chapter.id == state.pathParameters['chapter'],
                    )
                    ? null
                    : '/grammar/${language.id}/chapters';
              },
              builder: (context, state) {
                final language = GrammarLanguage.fromId(
                  state.pathParameters['language']!,
                )!;
                return GrammarChapterScreen(
                  language: language,
                  chapter: grammarSampleChapters[language]!.firstWhere(
                    (chapter) => chapter.id == state.pathParameters['chapter'],
                  ),
                );
              },
            ),
          ],
          redirect: (context, state) =>
              GrammarLanguage.fromId(state.pathParameters['language']!) == null
              ? '/grammar'
              : null,
          builder: (context, state) {
            return GrammarChaptersScreen(
              language: GrammarLanguage.fromId(state.pathParameters['language']!)!,
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

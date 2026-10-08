import '../../../app/widgets/learning_overview_content.dart';
import '../../../app/widgets/learning_card.dart';
import '../../../app/widgets/learning_ui.dart';
import '../../../app/app_ui_tokens.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/widgets/app_bottom_navigation.dart';
import '../data/problem_sample_data.dart';

class ProblemsHomeScreen extends StatelessWidget {
  const ProblemsHomeScreen({super.key});
  @override
  Widget build(BuildContext context) => LearningTheme(
    child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'COBIA',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: '프로필',
            onPressed: () => context.pushNamed(AppRouteNames.myPage),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(selectedIndex: 3),
      body: SafeArea(
        child: LearningBody(
          child: ListView(
            padding: AppSpacing.pagePadding(context),
            children: [
              LearningIntro(
                title: '문제 풀이',
                lines: ['배운 개념을 직접 확인해보세요.', '코드 작성과 간단한 문제로 기초를 다져요.'],
                icon: Icons.terminal_rounded,
              ),
              for (final mission in problemMissions)
                LearningCard(
                  emphasizedShadow: true,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () => context.pushNamed(
                      AppRouteNames.problemMission,
                      pathParameters: {'mission': mission.id},
                    ),
                    child: LearningOverviewContent(
                      label: mission.language,
                      title: mission.title,
                      description: '반복문과 기본 문법을 확인해보세요.',
                      icon: Icons.terminal_rounded,
                      tags: const ['코드 작성', '객관식', '출력값 입력'],
                      footer: '3문항 · 문제 풀기',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

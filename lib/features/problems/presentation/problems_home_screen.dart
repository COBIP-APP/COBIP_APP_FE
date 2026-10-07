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
                Card(
                  color: Colors.white,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: InkWell(
                    onTap: () => context.pushNamed(
                      AppRouteNames.problemMission,
                      pathParameters: {'mission': mission.id},
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.code, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Expanded(child: Text(mission.language)),
                              const Icon(Icons.arrow_forward),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(mission.title, style: AppTypography.card),
                          const SizedBox(height: 8),
                          const Text('반복문과 기본 문법을 확인해보세요.'),
                          const SizedBox(height: 16),
                          const Text(
                            '3문항 · 코드 작성 / 객관식 / 출력값 입력',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/widgets/app_bottom_navigation.dart';
import '../data/problem_sample_data.dart';

class ProblemsHomeScreen extends StatelessWidget {
  const ProblemsHomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        'COBIP',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        IconButton(
          tooltip: '프로필',
          onPressed: () => context.pushNamed(AppRouteNames.myPage),
          icon: const Icon(Icons.account_circle_outlined),
        ),
      ],
    ),
    bottomNavigationBar: AppBottomNavigation(selectedIndex: 3, onChat: () {}),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '문제 풀이',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('배운 개념을 직접 확인해보세요.\n코드 작성과 간단한 문제로 기초를 다져요.'),
          const SizedBox(height: 24),
          for (final mission in problemMissions)
            Card(
              color: Colors.white,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 16),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFECE8F5)),
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
                          Icon(
                            Icons.code,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(mission.language)),
                          const Icon(Icons.arrow_forward),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        mission.title,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('반복문과 기본 문법을 확인해보세요.'),
                      const SizedBox(height: 16),
                      const Text(
                        '3문항 · 코드 작성 / 객관식 / 출력값 입력',
                        style: TextStyle(color: Color(0xFF706B7F)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

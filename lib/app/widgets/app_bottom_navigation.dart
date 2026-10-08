import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../app_ui_tokens.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navigationBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.navigationShadow,
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == selectedIndex) return;
          switch (index) {
            case 0:
              context.goNamed(AppRouteNames.home);
            case 1:
              context.goNamed(AppRouteNames.grammar);
            case 2:
              context.goNamed(AppRouteNames.practical);
            case 3:
              context.goNamed(AppRouteNames.problems);
            case 4:
              context.pushNamed(AppRouteNames.chat);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '문법',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: '실무',
          ),
          NavigationDestination(icon: Icon(Icons.quiz_outlined), label: '문제'),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: '챗봇',
          ),
        ],
      ),
    );
  }
}

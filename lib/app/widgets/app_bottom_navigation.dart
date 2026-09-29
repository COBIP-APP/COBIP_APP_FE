import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onChat,
  });

  final int selectedIndex;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
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
          case 4:
            onChat();
          default:
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('문제 화면은 준비 중이에요.')));
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
          label: '챗봇',
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/widgets/app_bottom_navigation.dart';

class GrammarScaffold extends StatelessWidget {
  const GrammarScaffold({
    super.key,
    required this.title,
    required this.body,
    this.isOverview = false,
  });

  final String title;
  final Widget body;
  final bool isOverview;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isOverview
          ? AppBar(
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
                  icon: const Icon(Icons.account_circle_outlined),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('마이페이지는 담당 화면 연결 후 이용할 수 있습니다.'),
                    ),
                  ),
                ),
              ],
            )
          : AppBar(
              title: Text(title),
              leading: IconButton(
                tooltip: '뒤로가기',
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.goNamed(AppRouteNames.home);
                  }
                },
              ),
            ),
      body: SafeArea(child: body),
      bottomNavigationBar: isOverview
          ? AppBottomNavigation(
              selectedIndex: 1,
              onChat: () => _showChat(context),
            )
          : null,
      floatingActionButton: isOverview
          ? null
          : FloatingActionButton.small(
              tooltip: 'COBIP 챗봇',
              shape: const CircleBorder(),
              onPressed: () => _showChat(context),
              child: const Icon(Icons.smart_toy_outlined),
            ),
    );
  }

  void _showChat(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('COBIP 챗봇', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const Text('챗봇 대화 기능은 준비 중이에요. 학습을 계속 진행해 주세요.'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('학습 계속하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

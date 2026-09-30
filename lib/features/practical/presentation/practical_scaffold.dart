import '../../chat/presentation/chat_panel.dart';

import 'package:flutter/material.dart';

import '../../../app/widgets/app_bottom_navigation.dart';

class PracticalScaffold extends StatelessWidget {
  const PracticalScaffold({
    super.key,
    required this.body,
    this.isDetail = false,
    this.onBack,
  });
  final Widget body;
  final bool isDetail;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: isDetail
        ? AppBar(title: const Text('실무 기술 학습'), centerTitle: true)
        : AppBar(
            automaticallyImplyLeading: false,
            leading: onBack == null
                ? null
                : IconButton(
                    tooltip: '실무 목록으로 돌아가기',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
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
          ),
    body: SafeArea(child: body),
    bottomNavigationBar: isDetail
        ? null
        : AppBottomNavigation(selectedIndex: 2),
    floatingActionButton: isDetail
        ? FloatingActionButton.small(
            tooltip: 'COBIP 챗봇',
            shape: const CircleBorder(),
            onPressed: () => showChatPanel(context),
            child: const Icon(Icons.smart_toy_outlined),
          )
        : null,
  );
}

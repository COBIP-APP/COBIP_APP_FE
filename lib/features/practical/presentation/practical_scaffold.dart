import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/app_bottom_navigation.dart';

class PracticalScaffold extends StatelessWidget {
  const PracticalScaffold({
    super.key,
    required this.body,
    this.isDetail = false,
  });
  final Widget body;
  final bool isDetail;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('실무 기술 학습'), centerTitle: true),
    body: SafeArea(child: body),
    bottomNavigationBar: isDetail
        ? null
        : AppBottomNavigation(
            selectedIndex: 2,
            onChat: () => _showChat(context),
          ),
    floatingActionButton: isDetail
        ? FloatingActionButton.small(
            tooltip: 'COBIP 챗봇',
            shape: const CircleBorder(),
            onPressed: () => _showChat(context),
            child: const Icon(Icons.smart_toy_outlined),
          )
        : null,
  );

  void _showChat(BuildContext context) => showModalBottomSheet<void>(
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
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('학습 계속하기'),
            ),
          ],
        ),
      ),
    ),
  );
}

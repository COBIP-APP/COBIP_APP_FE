import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';

class GrammarScaffold extends StatelessWidget {
  const GrammarScaffold({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'COBIP 챗봇',
        shape: const CircleBorder(),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'COBIP 챗봇',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
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
        ),
        child: const Icon(Icons.smart_toy_outlined),
      ),
    );
  }
}

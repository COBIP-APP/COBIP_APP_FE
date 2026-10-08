import '../../../app/widgets/learning_ui.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/widgets/app_bottom_navigation.dart';
import 'chat_panel.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) => LearningTheme(
    child: Scaffold(
      appBar: AppBar(
        title: const Text('COBIA 챗봇'),
        leading: IconButton(
          tooltip: '이전 화면으로',
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
      body: const LearningBody(child: ChatPanel(isPage: true)),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 4),
    ),
  );
}

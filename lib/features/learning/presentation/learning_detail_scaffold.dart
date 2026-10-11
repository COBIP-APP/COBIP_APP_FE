import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/learning_ui.dart';
import '../../chat/presentation/chat_panel.dart';

class LearningDetailScaffold extends StatelessWidget {
  const LearningDetailScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.fallbackLocation,
    this.actions,
    this.showChat = true,
  });
  final String title, fallbackLocation;
  final Widget body;
  final List<Widget>? actions;
  final bool showChat;

  @override
  Widget build(BuildContext context) => Theme(
    data: learningUiTheme.copyWith(
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: learningUiTheme.outlinedButtonTheme.style!.copyWith(
          elevation: const WidgetStatePropertyAll(3),
          shadowColor: const WidgetStatePropertyAll(Colors.black26),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
    ),
    child: Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        leading: IconButton(
          tooltip: '뒤로가기',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(fallbackLocation),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(child: LearningBody(child: body)),
      floatingActionButton: showChat
          ? FloatingActionButton(
              tooltip: 'COBIA 챗봇',
              shape: const CircleBorder(),
              onPressed: () => showChatPanel(context),
              child: const Icon(Icons.smart_toy_outlined),
            )
          : null,
    ),
  );
}

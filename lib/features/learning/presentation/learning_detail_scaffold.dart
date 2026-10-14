import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_ui.dart';
import '../../chat/presentation/chat_panel.dart';
import '../../chat/presentation/chat_sessions.dart';

class LearningDetailScaffold extends StatelessWidget {
  const LearningDetailScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.fallbackLocation,
    this.actions,
    this.showChat = true,
    this.chatTemplateId,
  });
  final String title, fallbackLocation;
  final Widget body;
  final List<Widget>? actions;
  final bool showChat;
  final int? chatTemplateId;

  @override
  Widget build(BuildContext context) => LearningTheme(
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
      body: SafeArea(
        child: LearningBody(
          child: Stack(
            fit: StackFit.expand,
            children: [
              body,
              if (showChat)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 12,
                      right: AppSpacing.pagePadding(context).right,
                    ),
                    child: SizedBox.square(
                      dimension: 48,
                      child: FloatingActionButton(
                        tooltip: 'COBIA 챗봇',
                        shape: const CircleBorder(),
                        onPressed: () => showChatPanel(
                          context,
                          conversationKey: chatTemplateId == null
                              ? ChatSessions.mainKey
                              : ChatSessions.templateKey(chatTemplateId!),
                          learningTitle: chatTemplateId == null ? null : title,
                        ),
                        child: const Icon(Icons.smart_toy_outlined),
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

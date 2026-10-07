import '../../../app/widgets/learning_ui.dart';
import '../../../app/app_ui_tokens.dart';
import '../../chat/presentation/chat_panel.dart';

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
    this.footer,
  });

  final String title;
  final Widget body;
  final bool isOverview;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: learningUiTheme,
      child: Scaffold(
        appBar: isOverview
            ? AppBar(
                automaticallyImplyLeading: false,
                title: Text(
                  'COBIA',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
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
        body: SafeArea(child: LearningBody(child: body)),
        bottomNavigationBar: isOverview
            ? AppBottomNavigation(selectedIndex: 1)
            : footer == null
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: LearningBody(child: footer!),
                ),
              ),
        floatingActionButton: isOverview
            ? null
            : FloatingActionButton(
                tooltip: 'COBIA 챗봇',
                shape: const CircleBorder(),
                onPressed: () => showChatPanel(context),
                child: const Icon(Icons.smart_toy_outlined),
              ),
      ),
    );
  }
}

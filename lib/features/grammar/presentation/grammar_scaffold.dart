import '../../../app/widgets/app_home_header.dart';
import '../../../app/widgets/learning_ui.dart';
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
    this.actions,
  });

  final String title;
  final Widget body;
  final bool isOverview;
  final Widget? footer;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Theme(
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
        appBar: isOverview
            ? AppBar(
                automaticallyImplyLeading: false,
                title: const AppHomeHeader(),
              )
            : AppBar(
                title: Text(title),
                actions: actions,
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

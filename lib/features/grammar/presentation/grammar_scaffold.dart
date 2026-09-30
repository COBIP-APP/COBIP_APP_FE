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
    final theme = Theme.of(context);
    return Theme(
      data: isOverview
          ? theme
          : theme.copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6735FF),
              ).copyWith(primary: const Color(0xFF6735FF)),
              scaffoldBackgroundColor: const Color(0xFFFAF9FE),
              appBarTheme: AppBarTheme(
                backgroundColor: const Color(0xFFFAF9FE),
                surfaceTintColor: Colors.transparent,
                centerTitle: true,
                titleTextStyle: theme.textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF242034),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
      child: Scaffold(
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
            ? AppBottomNavigation(selectedIndex: 1)
            : footer == null
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: footer,
                ),
              ),
        floatingActionButton: isOverview
            ? null
            : FloatingActionButton.small(
                tooltip: 'COBIP 챗봇',
                shape: const CircleBorder(),
                onPressed: () => showChatPanel(context),
                child: const Icon(Icons.smart_toy_outlined),
              ),
      ),
    );
  }
}

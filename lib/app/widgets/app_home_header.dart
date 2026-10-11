import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_ui_tokens.dart';
import '../router/app_router.dart';

/// The home screen header, shared by the main learning tabs.
class AppHomeHeader extends StatelessWidget {
  const AppHomeHeader({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const SizedBox(width: 48),
      const Expanded(
        child: Text(
          'COBIA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ),
      IconButton(
        tooltip: '프로필',
        onPressed: () => context.pushNamed(AppRouteNames.myPage),
        icon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
      ),
    ],
  );
}

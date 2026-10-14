import 'package:flutter/material.dart';

import '../app_ui_tokens.dart';

class LearningButtonShadow extends StatelessWidget {
  const LearningButtonShadow({super.key, required this.child});

  final ButtonStyleButton child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadii.control),
      boxShadow: child.enabled ? AppShadows.learningCardEmphasized : null,
    ),
    child: child,
  );
}

import 'package:flutter/material.dart';

import '../../learning/presentation/learning_practice_screen.dart';

class GrammarPracticeScreen extends StatelessWidget {
  const GrammarPracticeScreen({super.key, required this.templateId});
  final int templateId;
  @override
  Widget build(BuildContext context) =>
      LearningPracticeScreen(templateId: templateId);
}

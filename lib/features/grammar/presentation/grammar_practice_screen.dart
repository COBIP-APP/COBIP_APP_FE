import 'package:flutter/material.dart';

import '../../learning/presentation/learning_practice_screen.dart';

class GrammarPracticeScreen extends StatelessWidget {
  const GrammarPracticeScreen({
    super.key,
    required this.templateId,
    this.sectionId,
  });
  final int templateId;
  final int? sectionId;
  @override
  Widget build(BuildContext context) =>
      LearningPracticeScreen(templateId: templateId, sectionId: sectionId);
}

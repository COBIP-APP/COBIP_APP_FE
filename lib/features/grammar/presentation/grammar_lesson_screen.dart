import 'package:flutter/material.dart';

import '../../learning/presentation/template_preview_screen.dart';

class GrammarLessonScreen extends StatelessWidget {
  const GrammarLessonScreen({
    super.key,
    required this.templateId,
    this.sectionId,
  });
  final int templateId;
  final int? sectionId;
  @override
  Widget build(BuildContext context) =>
      TemplatePreviewScreen(templateId: templateId, sectionId: sectionId);
}

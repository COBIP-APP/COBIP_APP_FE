import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../../learning/presentation/learning_preview_store.dart';
import '../../learning/presentation/learning_preview_widgets.dart';
import '../data/grammar_sample_data.dart';
import 'grammar_scaffold.dart';

class GrammarChaptersScreen extends StatelessWidget {
  const GrammarChaptersScreen({super.key, required this.language});
  final GrammarLanguage language;
  @override
  Widget build(BuildContext context) {
    final items = context
        .watch<LearningPreviewStore>()
        .templates
        .where((t) => t.categoryId == 1 && t.languageId == language.index + 1)
        .toList();
    return GrammarScaffold(
      title: '${language.label} 문법',
      body: PreviewContent(
        child: ListView(
          padding: AppSpacing.pagePadding(context).copyWith(bottom: 100),
          children: [
            LearningHero(
              title: '문법 챕터',
              description: '학습할 내용과 마지막 학습 상태를 확인해 보세요.',
              eyebrow: language.label,
              art: 'login_code',
            ),
            const SizedBox(height: 16),
            previewNotice,
            const SizedBox(height: 20),
            if (items.isEmpty) const LearningNotice('아직 등록된 학습이 없어요.'),
            for (final item in items) TemplatePreviewCard(item: item),
          ],
        ),
      ),
    );
  }
}

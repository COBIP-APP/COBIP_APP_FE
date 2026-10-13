import '../../../app/widgets/progressive_card_list.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../../learning/presentation/learning_store.dart';
import '../../learning/presentation/learning_preview_widgets.dart';
import 'grammar_scaffold.dart';

class GrammarChaptersScreen extends StatelessWidget {
  const GrammarChaptersScreen({super.key, required this.language});
  final String language;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningStore>();
    final selected = store.languages
        .where((l) => l.code.toLowerCase() == language.toLowerCase())
        .firstOrNull;
    final common = language.toLowerCase() == 'common';
    if (!common && store.state == PreviewLoadState.ready && selected == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/grammar');
      });
    }
    final items = store.templates
        .where(
          (t) =>
              store.isGrammar(t) &&
              (common
                  ? t.languageId == null
                  : selected != null &&
                        (t.languageId == null || t.languageId == selected.id)),
        )
        .toList();
    return GrammarScaffold(
      title: '${selected?.name ?? '언어 공통'} 문법',
      body: PreviewContent(
        child: ProgressiveCardList(
          padding: AppSpacing.pagePadding(context).copyWith(bottom: 100),
          resetKey: language,
          items: [for (final item in items) TemplatePreviewCard(item: item)],
          header: [
            LearningHero(
              title: '문법 챕터',
              description: '학습할 내용과 마지막 학습 상태를 확인해 보세요.',
              eyebrow: selected?.name ?? '언어 공통',
              art: 'login_code',
            ),
            const SizedBox(height: 20),
            if (items.isEmpty) const LearningNotice('아직 등록된 학습이 없어요.'),
          ],
        ),
      ),
    );
  }
}

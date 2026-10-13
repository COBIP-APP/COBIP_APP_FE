import '../../../app/widgets/progressive_card_list.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../../learning/presentation/learning_store.dart';
import '../../learning/presentation/learning_preview_widgets.dart';
import 'practical_scaffold.dart';

class PracticalChaptersScreen extends StatelessWidget {
  const PracticalChaptersScreen({super.key, required this.categoryId});
  final int categoryId;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningStore>();
    final items = context
        .watch<LearningStore>()
        .templates
        .where((t) => t.categoryId == categoryId)
        .toList();
    return PracticalScaffold(
      onBack: () => context.canPop() ? context.pop() : context.go('/practical'),
      body: PreviewContent(
        child: ProgressiveCardList(
          padding: AppSpacing.pagePadding(context),
          resetKey: categoryId,
          items: [for (final item in items) TemplatePreviewCard(item: item)],
          header: [
            LearningHero(
              title: '${store.categoryName(categoryId)} 학습',
              description: '학습할 내용과 마지막 학습 상태를 확인해 보세요.',
              eyebrow: '실무',
            ),
            const SizedBox(height: 20),
            if (items.isEmpty) const LearningNotice('아직 등록된 학습이 없어요.'),
          ],
        ),
      ),
    );
  }
}

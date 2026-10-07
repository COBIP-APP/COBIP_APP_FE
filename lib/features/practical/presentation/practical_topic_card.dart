import '../../../app/widgets/learning_card.dart';

import 'package:flutter/material.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_ui.dart';
import '../data/practical_sample_data.dart';

class PracticalTopicCard extends StatelessWidget {
  const PracticalTopicCard({
    super.key,
    required this.topic,
    required this.onTap,
  });
  final PracticalTopic topic;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final icon = switch (topic.id) {
      'cache' => Icons.layers_outlined,
      'database' => Icons.storage_rounded,
      'network' => Icons.language_rounded,
      _ => Icons.analytics_outlined,
    };
    return LearningCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LearningIcon(icon, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.category,
                        style: AppTypography.meta.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(topic.title, style: AppTypography.section),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const LearningCardArrow(),
              ],
            ),
            const SizedBox(height: 16),
            Text(topic.summary, style: AppTypography.helper),
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final tag in topic.tags) LearningBadge('#$tag')],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: AppColors.border),
            ),
            Row(
              children: [
                const Icon(
                  Icons.menu_book_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text('${topic.chapters.length}개 챕터', style: AppTypography.meta),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

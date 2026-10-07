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
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LearningIcon(icon),
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
                        Text(topic.title, style: AppTypography.card),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(topic.summary, style: AppTypography.helper),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in topic.tags) LearningBadge('#$tag'),
                ],
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
                  Text(
                    '${topic.chapters.length}개 챕터',
                    style: AppTypography.meta,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

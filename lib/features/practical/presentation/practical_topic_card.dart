import '../../../app/widgets/learning_card.dart';

import 'package:flutter/material.dart';

import '../../../app/widgets/learning_overview_content.dart';
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
      child: LearningOverviewContent(
        label: topic.category,
        title: topic.title,
        description: topic.summary,
        icon: icon,
        symbol: 'LAB',
        tags: topic.tags,
        footer: '${topic.chapters.length}개 챕터 · 실무 학습 시작',
      ),
    );
  }
}

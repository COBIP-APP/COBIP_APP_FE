import '../../../app/widgets/learning_visuals.dart';
import '../../../app/widgets/learning_card.dart';
import '../../../app/app_ui_tokens.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../data/practical_sample_data.dart';
import 'practical_scaffold.dart';

class PracticalChaptersScreen extends StatelessWidget {
  const PracticalChaptersScreen({super.key, required this.topic});
  final PracticalTopic topic;

  @override
  Widget build(BuildContext context) => PracticalScaffold(
    onBack: () {
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(AppRouteNames.practical);
      }
    },
    body: ListView(
      padding: AppSpacing.pagePadding(context),
      children: [
        LearningHero(
          title: topic.title,
          description: topic.summary,
          eyebrow: topic.category,
        ),
        const SizedBox(height: AppSpacing.section),
        Text('챕터 목록', style: AppTypography.section),
        const SizedBox(height: 8),
        const Text('궁금한 챕터부터 자유롭게 살펴보세요.'),
        const SizedBox(height: 16),
        for (var i = 0; i < topic.chapters.length; i++)
          LearningCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: ChapterNumber('${i + 1}'.padLeft(2, '0')),
              title: Text(
                topic.chapters[i].title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(topic.chapters[i].summary),
              ),
              trailing: const LearningCardArrow(),
              onTap: () => context.pushNamed(
                AppRouteNames.practicalChapter,
                pathParameters: {
                  'topic': topic.id,
                  'chapter': topic.chapters[i].id,
                },
              ),
            ),
          ),
      ],
    ),
  );
}

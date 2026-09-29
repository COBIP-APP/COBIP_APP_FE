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
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          topic.category,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 8),
        Text(
          topic.title,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(topic.summary),
        const SizedBox(height: 24),
        Text('챕터 목록', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('궁금한 챕터부터 자유롭게 살펴보세요.'),
        const SizedBox(height: 16),
        for (var i = 0; i < topic.chapters.length; i++)
          Card(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: CircleAvatar(child: Text('${i + 1}'.padLeft(2, '0'))),
              title: Text(
                topic.chapters[i].title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(topic.chapters[i].summary),
              ),
              trailing: const Icon(Icons.chevron_right),
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

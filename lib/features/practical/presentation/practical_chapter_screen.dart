import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../data/practical_sample_data.dart';
import 'practical_scaffold.dart';

class PracticalChapterScreen extends StatelessWidget {
  const PracticalChapterScreen({
    super.key,
    required this.topic,
    required this.chapterIndex,
  });
  final PracticalTopic topic;
  final int chapterIndex;

  void _move(BuildContext context, int index) => context.pushReplacementNamed(
    AppRouteNames.practicalChapter,
    pathParameters: {'topic': topic.id, 'chapter': topic.chapters[index].id},
  );

  @override
  Widget build(BuildContext context) {
    final chapter = topic.chapters[chapterIndex];
    return PracticalScaffold(
      isDetail: true,
      body: SingleChildScrollView(
        key: ValueKey('${topic.id}/${chapter.id}'),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${topic.category} · 챕터 ${chapterIndex + 1} / ${topic.chapters.length}',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              chapter.title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(chapter.summary),
            const SizedBox(height: 24),
            _Section(
              title: '핵심 개념',
              icon: Icons.lightbulb_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final point in chapter.points)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '• $point',
                        style: const TextStyle(height: 1.7),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: '예제로 이해하기',
              icon: Icons.code,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F2FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        chapter.code,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    chapter.explanation,
                    style: const TextStyle(height: 1.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: chapterIndex == 0
                        ? null
                        : () => _move(context, chapterIndex - 1),
                    child: const Text('이전 챕터'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: chapterIndex == topic.chapters.length - 1
                        ? null
                        : () => _move(context, chapterIndex + 1),
                    child: const Text('다음 챕터'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.goNamed(
                AppRouteNames.practicalChapters,
                pathParameters: {'topic': topic.id},
              ),
              child: const Text('챕터 목록으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: Color(0xFFECE8F5)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

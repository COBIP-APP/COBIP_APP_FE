import 'package:flutter/material.dart';

import '../../../app/router/app_router.dart';

import '../data/grammar_sample_data.dart';
import 'grammar_scaffold.dart';

class GrammarChaptersScreen extends StatelessWidget {
  const GrammarChaptersScreen({super.key, required this.language});

  final GrammarLanguage language;

  @override
  Widget build(BuildContext context) {
    final chapters = grammarSampleChapters[language]!;
    return GrammarScaffold(
      title: '${language.label} 문법',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 88),
        children: [
          Text(
            '문법 챕터',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('범위별로 학습할 내용과 진행 상태를 확인해 보세요.'),
          const SizedBox(height: 20),
          Text('${chapters.length}개 챕터 · 예시 진행률'),
          const SizedBox(height: 12),
          for (final chapter in chapters)
            _ChapterCard(
              chapter: chapter,
              onTap: grammarChapterRoutes.containsKey(chapter.id)
                  ? () => openGrammarChapter(context, language, chapter)
                  : null,
            ),
          const SizedBox(height: 16),
          const Text('학습 가능한 챕터를 눌러 개념을 학습해 보세요.'),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter, this.onTap});

  final GrammarChapter chapter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (chapter.category) {
      GrammarCategory.basics => Icons.code,
      GrammarCategory.control => Icons.alt_route,
      GrammarCategory.objects => Icons.account_tree_outlined,
      GrammarCategory.collections => Icons.data_array,
    };
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                child: Icon(icon),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (onTap != null) const Text('개념 학습하기 ›'),
                    const SizedBox(height: 4),
                    Text(
                      '${chapter.category.label} · ${chapter.status}',
                      style: TextStyle(color: colors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(chapter.description),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: chapter.progress,
                            semanticsLabel: '${chapter.title} 진행률',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('${(chapter.progress * 100).round()}%'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

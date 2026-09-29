import 'package:flutter/material.dart';

import '../data/grammar_sample_data.dart';
import 'grammar_scaffold.dart';

class GrammarChaptersScreen extends StatefulWidget {
  const GrammarChaptersScreen({
    super.key,
    required this.language,
    this.initialCategory,
  });

  final GrammarLanguage language;
  final GrammarCategory? initialCategory;

  @override
  State<GrammarChaptersScreen> createState() => _GrammarChaptersScreenState();
}

class _GrammarChaptersScreenState extends State<GrammarChaptersScreen> {
  GrammarCategory? _category;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  void didUpdateWidget(covariant GrammarChaptersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language ||
        oldWidget.initialCategory != widget.initialCategory) {
      _category = widget.initialCategory;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapters = grammarSampleChapters[widget.language]!
        .where((chapter) => _category == null || chapter.category == _category)
        .toList();

    return GrammarScaffold(
      title: '${widget.language.label} 문법',
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
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('전체'),
                selected: _category == null,
                onSelected: (_) => setState(() => _category = null),
              ),
              for (final category in GrammarCategory.values)
                ChoiceChip(
                  label: Text(category.label),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('${chapters.length}개 챕터 · 예시 진행률'),
          const SizedBox(height: 12),
          for (final chapter in chapters) _ChapterCard(chapter: chapter),
          const SizedBox(height: 16),
          const Text('개념·예제·퀴즈 학습 화면은 준비 중이에요.'),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter});

  final GrammarChapter chapter;

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
    );
  }
}

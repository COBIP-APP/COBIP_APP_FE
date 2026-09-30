import 'package:flutter/material.dart';

import '../data/grammar_sample_data.dart';
import 'grammar_scaffold.dart';

class GrammarChapterScreen extends StatelessWidget {
  const GrammarChapterScreen({
    super.key,
    required this.language,
    required this.chapter,
  });

  final GrammarLanguage language;
  final GrammarChapter chapter;

  @override
  Widget build(BuildContext context) {
    return GrammarScaffold(
      title: chapter.title,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('${language.label} · ${chapter.title}'),
          const SizedBox(height: 16),
          Text(chapter.description),
          const SizedBox(height: 24),
          const Text('이 챕터의 학습 내용을 준비 중이에요.'),
        ],
      ),
    );
  }
}

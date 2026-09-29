import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/condition_lesson_data.dart';
import '../data/grammar_sample_data.dart';
import 'grammar_scaffold.dart';
import 'lesson_widgets.dart';

class GrammarConceptScreen extends StatelessWidget {
  const GrammarConceptScreen({super.key, required this.language});
  final GrammarLanguage language;

  @override
  Widget build(BuildContext context) {
    final lesson = conditionLessons[language]!;
    return GrammarScaffold(
      title: '조건문',
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('이전'),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: FilledButton(onPressed: null, child: Text('예제 보기')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 88),
        children: [
          LessonPosition(language: language.label),
          const SizedBox(height: 24),
          LessonCard(
            title: '핵심 개념',
            icon: Icons.alt_route,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('조건문은 조건의 참과 거짓에 따라 실행할 코드를 선택합니다.'),
                const SizedBox(height: 16),
                for (final point in lesson.points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('• $point'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LessonCard(
            title: '간단 예제',
            icon: Icons.description_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('score가 이미 선언되어 있다고 가정합니다.'),
                const SizedBox(height: 12),
                LessonCode(code: lesson.shortCode),
                const SizedBox(height: 12),
                const Text(
                  'score가 60 이상이면 "합격"을 출력합니다. 조건이 거짓이면 이 블록은 실행하지 않습니다.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

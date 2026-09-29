import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/condition_lesson_data.dart';
import '../data/grammar_sample_data.dart';
import 'grammar_scaffold.dart';
import 'lesson_widgets.dart';

class GrammarExampleScreen extends StatelessWidget {
  const GrammarExampleScreen({super.key, required this.language});
  final GrammarLanguage language;

  @override
  Widget build(BuildContext context) {
    final lesson = conditionLessons[language]!;
    return GrammarScaffold(
      title: '예제 코드',
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('개념 다시 보기'),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: FilledButton(onPressed: null, child: Text('퀴즈 준비 중')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 88),
        children: [
          LessonPosition(language: language.label),
          const SizedBox(height: 24),
          LessonCard(
            title: '점수에 따른 조건 분기',
            icon: Icons.code,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('점수를 확인해 우수, 합격, 재도전 중 하나를 출력하는 예제입니다.'),
                const SizedBox(height: 16),
                LessonCode(code: lesson.code),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LessonCard(
            title: '코드 흐름',
            icon: Icons.format_list_numbered,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < lesson.flow.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(radius: 14, child: Text('${i + 1}')),
                        const SizedBox(width: 12),
                        Expanded(child: Text(lesson.flow[i])),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const LessonCard(
            title: '예상 출력',
            icon: Icons.terminal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  '합격',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text('예제의 예상 결과입니다. 코드를 실제로 실행하지는 않습니다.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

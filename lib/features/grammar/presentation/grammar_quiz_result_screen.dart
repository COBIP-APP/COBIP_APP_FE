import 'package:flutter/material.dart';

import '../data/condition_quiz_data.dart';
import 'grammar_scaffold.dart';
import 'lesson_widgets.dart';

class GrammarQuizResultScreen extends StatelessWidget {
  const GrammarQuizResultScreen({
    super.key,
    required this.questions,
    required this.answers,
    required this.onReturnToLearning,
  });
  final List<ConditionQuestion> questions;
  final List<int> answers;
  final VoidCallback onReturnToLearning;

  @override
  Widget build(BuildContext context) {
    final correct = [
      for (var i = 0; i < questions.length; i++)
        if (answers[i] == questions[i].correctIndex) i,
    ].length;
    final score = (correct / questions.length * 100).round();
    return GrammarScaffold(
      title: '학습 결과',
      footer: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onReturnToLearning,
          icon: const Icon(Icons.menu_book_outlined),
          label: const Text('학습으로 돌아가기'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
        children: [
          LessonCard(
            title: '조건문 복습 완료',
            icon: Icons.emoji_events_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '$score점',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: const Color(0xFF6735FF),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  correct == questions.length
                      ? '조건문의 흐름을 모두 이해했어요!'
                      : '해설을 확인하고 헷갈린 조건을 복습해 보세요.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text(
                      '맞힌 문제 $correct',
                      style: const TextStyle(color: Color(0xFF23815A)),
                    ),
                    Text(
                      '틀린 문제 ${questions.length - correct}',
                      style: const TextStyle(color: Color(0xFFC33F60)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('현재 풀이 결과이며 앱 종료 후에는 저장되지 않습니다.'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '해설 확인',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < questions.length; i++) ...[
            LessonCard(
              title:
                  '문제 ${i + 1} · ${answers[i] == questions[i].correctIndex ? '정답' : '오답'}',
              icon: answers[i] == questions[i].correctIndex
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    questions[i].question,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text('내 답: ${questions[i].options[answers[i]]}'),
                  const SizedBox(height: 4),
                  Text(
                    '정답: ${questions[i].options[questions[i].correctIndex]}',
                    style: const TextStyle(
                      color: Color(0xFF6735FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(questions[i].explanation),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

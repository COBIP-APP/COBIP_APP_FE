import 'package:flutter/material.dart';

import '../data/problem_sample_data.dart';

class ProblemResultScreen extends StatelessWidget {
  const ProblemResultScreen({
    super.key,
    required this.mission,
    required this.choice,
    required this.output,
    required this.onReturn,
  });
  final ProblemMission mission;
  final int choice;
  final String output;
  final VoidCallback onReturn;
  @override
  Widget build(BuildContext context) {
    final correct =
        (choice == mission.correctIndex ? 1 : 0) +
        (output.trim() == mission.outputAnswer ? 1 : 0);
    return Scaffold(
      appBar: AppBar(title: const Text('풀이 결과')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              Icons.fact_check_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              mission.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              '자동 확인 $correct / 2',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '코드 작성 문제는 실행·채점하지 않습니다. 예시 답안과 비교해보세요. 결과는 저장되지 않습니다.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _answer('1. 코드 작성 · 예시 답안', mission.sampleCode),
            _answer(
              '2. 객관식 · ${choice == mission.correctIndex ? '정답' : '오답'}',
              '내 답: ${mission.options[choice]}\n정답: ${mission.options[mission.correctIndex]}\n\n${mission.choiceExplanation}',
            ),
            _answer(
              '3. 출력값 · ${output.trim() == mission.outputAnswer ? '정답' : '오답'}',
              '내 답: $output\n정답: ${mission.outputAnswer}\n\n1 + 2 + 3의 합을 출력하므로 결과는 6입니다.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onReturn,
              child: const Text('문제 목록으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _answer(String title, String body) => Card(
    color: Colors.white,
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SelectableText(body, style: const TextStyle(height: 1.6)),
        ],
      ),
    ),
  );
}

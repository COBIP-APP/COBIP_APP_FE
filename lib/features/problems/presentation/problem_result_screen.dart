import 'package:flutter/material.dart';

import '../../chat/presentation/chat_panel.dart';
import '../data/problem_sample_data.dart';

class ProblemResultScreen extends StatelessWidget {
  const ProblemResultScreen({
    super.key,
    required this.mission,
    required this.code,
    required this.choice,
    required this.output,
    required this.onReturn,
    required this.onRetry,
  });
  final ProblemMission mission;
  final String code;
  final int choice;
  final String output;
  final VoidCallback onReturn;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final codeCorrect = mission.matchesSampleCode(code);
    final choiceCorrect = choice == mission.correctIndex;
    final outputCorrect = output.trim() == mission.outputAnswer;
    final correct = [
      codeCorrect,
      choiceCorrect,
      outputCorrect,
    ].where((value) => value).length;
    return Scaffold(
      appBar: AppBar(title: const Text('결과 확인'), centerTitle: true),
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'COBIP 챗봇',
        shape: const CircleBorder(),
        onPressed: () => showChatPanel(context),
        child: const Icon(Icons.smart_toy_outlined),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
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
              '정답 $correct / 3',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '더미 채점 결과입니다. 코드 문제는 실행 없이 예시 코드와 문자열을 비교합니다. 다른 올바른 코드도 오답으로 표시될 수 있습니다.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _ResultCard(
              title: '1. 코드 작성',
              isCorrect: codeCorrect,
              answer: '내 답안\n$code\n\n예시 정답\n${mission.sampleCode}',
            ),
            _ResultCard(
              title: '2. 객관식',
              isCorrect: choiceCorrect,
              answer:
                  '내 답: ${mission.options[choice]}\n정답: ${mission.options[mission.correctIndex]}\n\n${mission.choiceExplanation}',
            ),
            _ResultCard(
              title: '3. 출력값',
              isCorrect: outputCorrect,
              answer:
                  '내 답: $output\n정답: ${mission.outputAnswer}\n\n1 + 2 + 3의 합을 출력하므로 결과는 6입니다.',
            ),
            const SizedBox(height: 16),
            if (correct == 3)
              FilledButton(
                onPressed: onReturn,
                child: const Text('문제 목록으로 돌아가기'),
              )
            else ...[
              FilledButton(onPressed: onRetry, child: const Text('다시 풀기')),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: onReturn, child: const Text('나가기')),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatefulWidget {
  const _ResultCard({
    required this.title,
    required this.isCorrect,
    required this.answer,
  });
  final String title;
  final bool isCorrect;
  final String answer;
  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  bool _showAnswer = false;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: widget.isCorrect
            ? const Color(0xFF86B89A)
            : const Color(0xFFECE8F5),
        width: widget.isCorrect ? 1.2 : 1,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                widget.isCorrect
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isCorrect ? '정답' : '오답',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _showAnswer = !_showAnswer),
              child: Text(_showAnswer ? '풀이 숨기기' : '정답 및 풀이 보기'),
            ),
          ),
          if (_showAnswer)
            SelectableText(widget.answer, style: const TextStyle(height: 1.6)),
        ],
      ),
    ),
  );
}

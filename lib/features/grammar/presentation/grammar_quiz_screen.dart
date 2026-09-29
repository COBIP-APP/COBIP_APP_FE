import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../data/condition_quiz_data.dart';
import '../data/grammar_sample_data.dart';
import 'grammar_quiz_result_screen.dart';
import 'grammar_scaffold.dart';
import 'lesson_widgets.dart';

class GrammarQuizScreen extends StatefulWidget {
  const GrammarQuizScreen({super.key, required this.language});
  final GrammarLanguage language;

  @override
  State<GrammarQuizScreen> createState() => _GrammarQuizScreenState();
}

class _GrammarQuizScreenState extends State<GrammarQuizScreen> {
  late final _questions = conditionQuestions(widget.language);
  final _answers = <int>[];
  final _scrollController = ScrollController();
  int? _selected;
  bool _submitted = false;
  bool _showResult = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _submitOrNext() {
    if (!_submitted) {
      if (_selected == null) return;
      setState(() => _submitted = true);
      return;
    }
    setState(() {
      _answers.add(_selected!);
      _selected = null;
      _submitted = false;
      _showResult = _answers.length == _questions.length;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) {
      return GrammarQuizResultScreen(
        questions: _questions,
        answers: _answers,
        onExamples: () => context.pop(),
        onRetry: () => setState(() {
          _answers.clear();
          _selected = null;
          _submitted = false;
          _showResult = false;
        }),
      );
    }
    final question = _questions[_answers.length];
    return GrammarScaffold(
      title: '복습 퀴즈',
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pushNamed(
                AppRouteNames.grammarConcept,
                pathParameters: {'language': widget.language.id},
              ),
              child: const Text('개념 다시 보기'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _selected == null ? null : _submitOrNext,
              child: Text(
                !_submitted
                    ? '정답 제출'
                    : _answers.length == _questions.length - 1
                    ? '결과 보기'
                    : '다음 문제',
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
        children: [
          LessonPosition(
            language: widget.language.label,
            current: _answers.length + 1,
            total: _questions.length,
            label: '문제',
          ),
          const SizedBox(height: 20),
          LessonCard(
            title: '조건문',
            icon: Icons.alt_route,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  question.question,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                LessonCode(code: question.code),
                const SizedBox(height: 16),
                for (var i = 0; i < question.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AnswerOption(
                      key: ValueKey('answer-$i'),
                      label: question.options[i],
                      selected: _selected == i,
                      isCorrect: _submitted && i == question.correctIndex,
                      isWrong:
                          _submitted &&
                          _selected == i &&
                          i != question.correctIndex,
                      onTap: _submitted
                          ? null
                          : () => setState(() => _selected = i),
                    ),
                  ),
                const SizedBox(height: 8),
                if (_submitted)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2ECFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _selected == question.correctIndex
                              ? '정답이에요!'
                              : '다시 확인해 보세요',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('정답: ${question.options[question.correctIndex]}'),
                        const SizedBox(height: 8),
                        Text(question.explanation),
                      ],
                    ),
                  )
                else
                  const Text('보기를 선택하고 제출하면 해설을 확인할 수 있습니다.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    super.key,
    required this.label,
    required this.selected,
    required this.isCorrect,
    required this.isWrong,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect
        ? const Color(0xFF23815A)
        : isWrong
        ? const Color(0xFFC33F60)
        : const Color(0xFF6735FF);
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: selected || isCorrect
            ? color.withValues(alpha: .08)
            : const Color(0xFFF8F6FC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: selected || isCorrect ? color : const Color(0xFFECE8F3),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  isCorrect
                      ? Icons.check_circle_outline
                      : isWrong
                      ? Icons.cancel_outlined
                      : selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected || isCorrect
                      ? color
                      : const Color(0xFFA5A0B3),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(label)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

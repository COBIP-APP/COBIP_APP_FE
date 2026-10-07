import '../../../app/app_ui_tokens.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../data/condition_lesson_data.dart';
import '../data/grammar_sample_data.dart';
import 'grammar_scaffold.dart';
import 'lesson_widgets.dart';

class GrammarExampleScreen extends StatefulWidget {
  const GrammarExampleScreen({super.key, required this.language});
  final GrammarLanguage language;

  @override
  State<GrammarExampleScreen> createState() => _GrammarExampleScreenState();
}

class _GrammarExampleScreenState extends State<GrammarExampleScreen> {
  int _index = 0;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _select(int index) {
    setState(() => _index = index);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final examples = conditionExamples(widget.language);
    final example = examples[_index];
    return GrammarScaffold(
      title: '예제 코드',
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () =>
                  _index == 0 ? context.pop() : _select(_index - 1),
              child: Text(_index == 0 ? '개념 다시 보기' : '이전 예제'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: () {
                if (_index < examples.length - 1) {
                  _select(_index + 1);
                } else {
                  context.pushNamed(
                    AppRouteNames.grammarQuiz,
                    pathParameters: {'language': widget.language.id},
                  );
                }
              },
              child: Text(_index < examples.length - 1 ? '다음 예제' : '퀴즈 풀기'),
            ),
          ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        padding: AppSpacing.pagePadding(context).copyWith(bottom: 88),
        children: [
          LessonPosition(
            language: widget.language.label,
            current: _index + 1,
            total: examples.length,
            label: '예제',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < examples.length; i++)
                ChoiceChip(
                  label: Text('예제 ${i + 1}'),
                  selected: _index == i,
                  onSelected: (_) => _select(i),
                ),
            ],
          ),
          const SizedBox(height: 16),
          LessonCard(
            title: example.title,
            icon: Icons.code,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(example.description),
                const SizedBox(height: 16),
                LessonCode(code: example.code),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LessonCard(
            title: '코드 흐름',
            icon: Icons.description_outlined,
            child: Column(
              children: [
                for (var i = 0; i < example.flow.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primarySoft,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(example.flow[i])),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LessonCard(
            title: '예상 출력',
            icon: Icons.terminal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  example.output,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('코드 실행 없이 예상 결과를 보여주는 예제입니다.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

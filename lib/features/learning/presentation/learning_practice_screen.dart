import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../data/learning_models.dart';
import 'learning_store.dart';
import 'learning_preview_widgets.dart';
import 'learning_detail_scaffold.dart';
import 'learning_question_card.dart';

class LearningPracticeScreen extends StatefulWidget {
  const LearningPracticeScreen({super.key, required this.templateId});
  final int templateId;

  @override
  State<LearningPracticeScreen> createState() => _LearningPracticeScreenState();
}

class _LearningPracticeScreenState extends State<LearningPracticeScreen> {
  final _scroll = ScrollController();
  final _answers = <int, String>{};
  Map<int, LearningSubmission> _results = {};
  final _accepted = <int, LearningSubmission>{};
  final _acceptedAnswers = <int, String>{};
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _submit(List<LearningQuestion> questions) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final store = context.read<LearningStore>();
      final submissions = await Future.wait([
        for (final question in questions)
          () async {
            final answer = _answers[question.id]!;
            if (_acceptedAnswers[question.id] == answer &&
                _accepted.containsKey(question.id)) {
              return _accepted[question.id]!;
            }
            final result = await store.submit(question.id, answer);
            _accepted[question.id] = result;
            _acceptedAnswers[question.id] = answer;
            return result;
          }(),
      ]);
      if (!mounted) return;
      setState(() {
        _results = {
          for (final result in submissions) result.questionId: result,
        };
      });
      _scroll.jumpTo(0);
    } catch (_) {
      if (mounted) {
        setState(() => _error = '답안을 확인하지 못했어요. 선택한 답은 유지되니 다시 눌러 주세요.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish(String location) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final store = context.read<LearningStore>();
      final section = store.template(widget.templateId)?.allSections.lastOrNull;
      if (section == null) throw StateError('No lesson section');
      await store.saveProgress(
        widget.templateId,
        store.progress(widget.templateId)?.lastSectionId ?? section.id,
        completed: true,
      );
      if (mounted) context.go(location);
    } catch (_) {
      if (mounted) setState(() => _error = '학습 완료를 저장하지 못했어요. 다시 눌러 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningStore>();
    final questions = store.questions
        .where((question) => question.relatedTemplateId == widget.templateId)
        .toList();
    final answered = questions
        .where((q) => _answers[q.id]?.trim().isNotEmpty == true)
        .length;
    final allCorrect =
        questions.isNotEmpty &&
        questions.every((question) {
          final result = _results[question.id];
          return result?.gradingStatus == 'COMPLETED' &&
              result?.score != null &&
              result!.score! >= question.passScore;
        });
    final template = store.template(widget.templateId);
    final listLocation = template == null
        ? '/grammar'
        : store.templateListLocation(template);
    return LearningDetailScaffold(
      title: '학습 확인 문제',
      showChat: false,
      fallbackLocation: listLocation,
      body: LearningDetailContent(
        detailKey: 't:${widget.templateId}',
        child: ListView(
          controller: _scroll,
          padding: AppSpacing.pagePadding(context).copyWith(bottom: 100),
          children: [
            if (questions.isEmpty)
              const LearningNotice('이 학습에 연결된 문제는 아직 없어요.')
            else ...[
              Text(
                _results.isEmpty
                    ? '모든 문제를 풀고 한 번에 답을 확인해 보세요. ($answered / ${questions.length})'
                    : '결과를 확인하고, 풀이가 궁금하면 ‘풀이 보기’를 눌러 주세요.',
                style: AppTypography.body,
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < questions.length; i++) ...[
                LearningQuestionCard(
                  key: ValueKey(questions[i].id),
                  question: questions[i],
                  title: '문제 ${i + 1}',
                  answer: _answers[questions[i].id],
                  result: _results[questions[i].id],
                  locked: _busy || _results.isNotEmpty,
                  onChanged: (answer) =>
                      setState(() => _answers[questions[i].id] = answer),
                ),
                const SizedBox(height: 24),
              ],
              if (_error != null) ...[
                LearningNotice(_error!),
                const SizedBox(height: 12),
              ],
              if (_results.isEmpty)
                FilledButton(
                  onPressed: !_busy && answered == questions.length
                      ? () => _submit(questions)
                      : null,
                  child: Text(_busy ? '확인 중…' : '답 확인'),
                )
              else if (allCorrect)
                FilledButton(
                  onPressed: _busy ? null : () => _finish(listLocation),
                  child: Text(_busy ? '저장 중…' : '학습 끝내기'),
                )
              else
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _answers.clear();
                      _accepted.clear();
                      _acceptedAnswers.clear();
                      _results = {};
                      _error = null;
                    });
                    _scroll.jumpTo(0);
                  },
                  child: const Text('다시 풀기'),
                ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go(listLocation),
              child: const Text('학습으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}

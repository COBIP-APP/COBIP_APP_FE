import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_ui.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../../learning/data/learning_models.dart';
import '../../learning/data/learning_preview_data.dart' show previewLanguages;
import '../../learning/presentation/learning_preview_store.dart';
import '../../learning/presentation/learning_preview_widgets.dart';
import 'grammar_scaffold.dart';

class GrammarPracticeScreen extends StatefulWidget {
  const GrammarPracticeScreen({super.key, required this.templateId});
  final int templateId;

  @override
  State<GrammarPracticeScreen> createState() => _GrammarPracticeScreenState();
}

class _GrammarPracticeScreenState extends State<GrammarPracticeScreen> {
  final _scroll = ScrollController();
  final _answers = <int, String>{};
  final _expandedExplanations = <int>{};
  Map<int, LearningSubmission> _results = {};
  bool _busy = false;
  String? _error;
  int _attempt = 0;

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
      final store = context.read<LearningPreviewStore>();
      final submissions = await Future.wait([
        for (final question in questions)
          store.submit(question.id, _answers[question.id]!),
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

  Widget _questionCard(LearningQuestion question, int index) {
    final result = _results[question.id];
    final graded =
        result?.gradingStatus == 'COMPLETED' && result?.score != null;
    final correct = graded && result!.score! >= question.passScore;
    final color = graded
        ? (correct ? AppColors.success : AppColors.error)
        : AppColors.textSecondary;
    final locked = _busy || _results.isNotEmpty;
    return LearningSection(
      key: ValueKey('practice-question-${question.id}'),
      title: '문제 ${index + 1}',
      icon: Icons.quiz_outlined,
      emphasizedShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(question.prompt, style: AppTypography.body),
          PreviewMediaList(items: question.media),
          if (question.codeSnippet?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            LearningCode(question.codeSnippet!),
          ],
          const SizedBox(height: 16),
          if (question.questionType == LearningQuestionType.multipleChoice)
            for (final choice in question.choiceOptions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Semantics(
                  selected: _answers[question.id] == choice.key,
                  child: OutlinedButton(
                    key: ValueKey('choice-${question.id}-${choice.key}'),
                    onPressed: locked
                        ? null
                        : () => setState(
                            () => _answers[question.id] = choice.key,
                          ),
                    style: OutlinedButton.styleFrom(
                      disabledForegroundColor: AppColors.textPrimary,
                      backgroundColor: _answers[question.id] == choice.key
                          ? (graded
                                ? color.withValues(alpha: .1)
                                : AppColors.primarySoft)
                          : AppColors.surface,
                      side: BorderSide(
                        color: _answers[question.id] == choice.key
                            ? (graded ? color : AppColors.primary)
                            : AppColors.border,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('${choice.key}. ${choice.text}'),
                    ),
                  ),
                ),
              )
          else
            TextFormField(
              key: ValueKey('answer-${question.id}-$_attempt'),
              initialValue: _answers[question.id],
              enabled: !locked,
              onChanged: (value) =>
                  setState(() => _answers[question.id] = value),
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(hintText: '답안을 작성해 주세요.'),
            ),
          if (result != null) ...[
            const SizedBox(height: 12),
            Container(
              key: ValueKey('result-${question.id}'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                border: Border.all(color: color),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        graded
                            ? (correct
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined)
                            : Icons.schedule,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          graded ? (correct ? '정답' : '오답') : '채점 대기',
                          style: AppTypography.card.copyWith(color: color),
                        ),
                      ),
                    ],
                  ),
                  if (graded && question.explanation?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: ValueKey('explanation-toggle-${question.id}'),
                      onPressed: () => setState(() {
                        if (!_expandedExplanations.add(question.id)) {
                          _expandedExplanations.remove(question.id);
                        }
                      }),
                      icon: Icon(
                        _expandedExplanations.contains(question.id)
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                      label: Text(
                        _expandedExplanations.contains(question.id)
                            ? '풀이 접기'
                            : '풀이 보기',
                      ),
                    ),
                    if (_expandedExplanations.contains(question.id)) ...[
                      const SizedBox(height: 12),
                      Text(question.explanation!, style: AppTypography.body),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningPreviewStore>();
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
    final language = previewLanguages
        .where((language) => language.id == template?.languageId)
        .firstOrNull;
    return GrammarScaffold(
      title: '학습 확인 문제',
      body: PreviewContent(
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
                _questionCard(questions[i], i),
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
                  onPressed: () => context.go(
                    language == null
                        ? '/grammar'
                        : '/grammar/${language.code.toLowerCase()}/chapters',
                  ),
                  child: const Text('학습 끝내기'),
                )
              else
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _answers.clear();
                      _expandedExplanations.clear();
                      _results = {};
                      _error = null;
                      _attempt++;
                    });
                    _scroll.jumpTo(0);
                  },
                  child: const Text('다시 풀기'),
                ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/grammar'),
              child: const Text('학습으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}

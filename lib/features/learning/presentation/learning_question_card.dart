import 'package:flutter/material.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_ui.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../data/learning_models.dart';
import 'learning_preview_widgets.dart';

class LearningQuestionCard extends StatefulWidget {
  const LearningQuestionCard({
    super.key,
    required this.question,
    required this.title,
    required this.answer,
    required this.onChanged,
    this.result,
    this.locked = false,
    this.showSubmissionDetails = false,
  });
  final LearningQuestion question;
  final String title;
  final String? answer;
  final ValueChanged<String> onChanged;
  final LearningSubmission? result;
  final bool locked;
  final bool showSubmissionDetails;
  @override
  State<LearningQuestionCard> createState() => _LearningQuestionCardState();
}

class _LearningQuestionCardState extends State<LearningQuestionCard> {
  late final TextEditingController _controller;
  bool _expanded = false;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.answer ?? '');
  }

  @override
  void didUpdateWidget(covariant LearningQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != (widget.answer ?? '')) {
      _controller.text = widget.answer ?? '';
    }
    if (oldWidget.result != widget.result) _expanded = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final result = widget.result;
    final explanation = result?.explanation ?? question.explanation;
    final graded =
        result?.gradingStatus == 'COMPLETED' && result?.score != null;
    final correct = graded && result!.score! >= question.passScore;
    final color = graded
        ? (correct ? AppColors.success : AppColors.error)
        : AppColors.textSecondary;
    final locked = widget.locked;
    return LearningSection(
      key: ValueKey('practice-question-${question.id}'),
      title: widget.title,
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
          if (question.questionType.hasChoices)
            for (final choice in question.choiceOptions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Semantics(
                  selected: widget.answer == choice.key,
                  child: OutlinedButton(
                    key: ValueKey('choice-${question.id}-${choice.key}'),
                    onPressed: locked
                        ? null
                        : () => widget.onChanged(choice.key),
                    style: OutlinedButton.styleFrom(
                      disabledForegroundColor: AppColors.textPrimary,
                      backgroundColor: widget.answer == choice.key
                          ? (graded
                                ? color.withValues(alpha: .1)
                                : AppColors.primarySoft)
                          : AppColors.surface,
                      side: BorderSide(
                        color: widget.answer == choice.key
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
            TextField(
              key: ValueKey('answer-${question.id}'),
              controller: _controller,
              enabled: !locked,
              onChanged: widget.onChanged,
              minLines: 4,
              maxLines: 10,
              autocorrect: false,
              enableSuggestions: false,
              style: question.questionType == LearningQuestionType.codeWriting
                  ? const TextStyle(fontFamily: 'monospace', fontSize: 14)
                  : AppTypography.body,
              decoration: InputDecoration(
                hintText:
                    question.questionType == LearningQuestionType.codeWriting
                    ? '// 코드를 작성하세요.'
                    : question.questionType ==
                          LearningQuestionType.codeExplanation
                    ? '출력 결과와 코드의 동작 과정을 설명해 주세요.'
                    : question.questionType == LearningQuestionType.fillBlank
                    ? '빈칸이 여러 개면 쉼표로 구분해 주세요.'
                    : '답안을 작성해 주세요.',
              ),
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
                          graded
                              ? (correct ? '정답' : '오답')
                              : (result.pending ? '채점 대기' : '채점 실패'),
                          style: AppTypography.card.copyWith(color: color),
                        ),
                      ),
                    ],
                  ),
                  if (widget.showSubmissionDetails) ...[
                    const SizedBox(height: 8),
                    if (graded)
                      Text(
                        '${result.score}점 · 통과 기준 ${question.passScore}점',
                        style: AppTypography.meta,
                      ),
                    Text(
                      '제출 ${previewDate(result.submittedAt)}',
                      style: AppTypography.meta,
                    ),
                  ],
                  if (graded &&
                      (explanation?.isNotEmpty == true ||
                          result.correctAnswer?.isNotEmpty == true ||
                          result.feedback?.isNotEmpty == true)) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: ValueKey('explanation-toggle-${question.id}'),
                      onPressed: () => setState(() => _expanded = !_expanded),
                      icon: Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                      ),
                      label: Text(_expanded ? '풀이 접기' : '풀이 보기'),
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 12),
                      if (result.correctAnswer?.isNotEmpty == true) ...[
                        Text(
                          '정답: ${result.correctAnswer}',
                          style: AppTypography.card,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (explanation?.isNotEmpty == true)
                        Text(explanation!, style: AppTypography.body),
                      if (widget.showSubmissionDetails &&
                          result.feedback?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text(result.feedback!, style: AppTypography.body),
                      ],
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
}

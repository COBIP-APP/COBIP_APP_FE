import 'package:flutter/material.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_ui.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../../learning/data/learning_models.dart';
import '../../learning/presentation/learning_preview_widgets.dart';

class SubmissionPreviewResult extends StatelessWidget {
  const SubmissionPreviewResult({
    super.key,
    required this.question,
    required this.submission,
  });
  final LearningQuestion question;
  final LearningSubmission submission;
  @override
  Widget build(BuildContext context) {
    final answer = submission.selectedChoiceKey == null
        ? submission.answerText ?? submission.sourceCode ?? ''
        : question.choiceOptions
                  .where((c) => c.key == submission.selectedChoiceKey)
                  .map((c) => '${c.key}. ${c.text}')
                  .firstOrNull ??
              submission.selectedChoiceKey!;
    final complete = submission.gradingStatus == 'COMPLETED';
    final explanation = submission.explanation ?? question.explanation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LearningSection(
          title: submission.pending
              ? '채점 대기'
              : complete
              ? '채점 완료'
              : '채점 실패',
          icon: submission.pending
              ? Icons.hourglass_empty
              : Icons.fact_check_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (submission.pending)
                const Text(
                  '답안을 받았어요. 아직 점수와 피드백이 없습니다.',
                  style: AppTypography.body,
                ),
              if (!submission.pending && !complete)
                const Text(
                  '채점을 완료하지 못했어요. 제출한 답안을 확인하고 다시 제출해 주세요.',
                  style: AppTypography.body,
                ),
              if (complete && submission.score != null) ...[
                Text('${submission.score}점', style: AppTypography.title),
                LearningBadge(
                  submission.score! >= question.passScore ? '통과' : '다시 도전',
                ),
              ],
              const SizedBox(height: 12),
              Text(
                '제출 ${previewDate(submission.submittedAt)}',
                style: AppTypography.meta,
              ),
              if (submission.gradedAt != null)
                Text(
                  '채점 ${previewDate(submission.gradedAt!)}',
                  style: AppTypography.meta,
                ),
              if (submission.feedback?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(submission.feedback!, style: AppTypography.body),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        LearningSection(
          title: '제출한 답안',
          icon: Icons.description_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(question.prompt, style: AppTypography.body),
              const SizedBox(height: 16),
              if (submission.sourceCode != null)
                LearningCode(answer)
              else
                SelectableText(answer, style: AppTypography.body),
            ],
          ),
        ),
        if (complete &&
            (explanation?.isNotEmpty == true ||
                submission.correctAnswer?.isNotEmpty == true)) ...[
          const SizedBox(height: 20),
          LearningSection(
            title: '해설',
            icon: Icons.lightbulb_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (submission.correctAnswer?.isNotEmpty == true) ...[
                  Text(
                    '정답: ${submission.correctAnswer}',
                    style: AppTypography.card,
                  ),
                  const SizedBox(height: 8),
                ],
                if (explanation?.isNotEmpty == true)
                  Text(explanation!, style: AppTypography.body),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

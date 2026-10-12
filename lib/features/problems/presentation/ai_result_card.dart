import 'package:flutter/material.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_ui.dart';

class AiResultCard extends StatefulWidget {
  const AiResultCard({
    super.key,
    required this.isCorrect,
    required this.score,
    required this.feedback,
    this.correctAnswer,
    this.explanation,
    this.relatedSection,
    this.formattedCode,
    this.extra,
  });
  final bool isCorrect;
  final int score;
  final String feedback;
  final String? correctAnswer, explanation, relatedSection, formattedCode;
  final Widget? extra;
  @override
  State<AiResultCard> createState() => _AiResultCardState();
}

class _AiResultCardState extends State<AiResultCard> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final color = widget.isCorrect ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.isCorrect ? '정답' : '오답'} · ${widget.score}점',
            style: AppTypography.card.copyWith(color: color),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            label: Text(_expanded ? '풀이 접기' : '풀이 보기'),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            if (widget.correctAnswer?.isNotEmpty == true)
              Text('정답: ${widget.correctAnswer}', style: AppTypography.card),
            if (widget.feedback.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(widget.feedback, style: AppTypography.body),
            ],
            if (widget.explanation?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(widget.explanation!, style: AppTypography.body),
            ],
            if (widget.relatedSection?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                '관련 학습: ${widget.relatedSection}',
                style: AppTypography.meta,
              ),
            ],
            if (widget.formattedCode?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              const Text('정리된 코드', style: AppTypography.card),
              const SizedBox(height: 8),
              LearningCode(widget.formattedCode!),
            ],
            if (widget.extra != null) ...[
              const SizedBox(height: 12),
              widget.extra!,
            ],
          ],
        ],
      ),
    );
  }
}

class AiLoading extends StatelessWidget {
  const AiLoading(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 10),
          Text(message, style: AppTypography.helper),
        ],
      ),
    ),
  );
}

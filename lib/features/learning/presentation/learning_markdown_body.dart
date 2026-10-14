import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../app/app_ui_tokens.dart';

class LearningMarkdownBody extends StatelessWidget {
  const LearningMarkdownBody(this.body, {super.key});

  final String body;

  @override
  Widget build(BuildContext context) {
    if (body.trim().isEmpty) return const SizedBox.shrink();

    final textStyle = AppTypography.body.copyWith(color: AppColors.textPrimary);
    return MarkdownBody(
      data: body,
      // Keep legacy text line breaks and use the lesson's existing scroll view.
      softLineBreak: true,
      fitContent: false,
      styleSheet: MarkdownStyleSheet(
        p: textStyle,
        a: textStyle,
        h1: AppTypography.detail.copyWith(color: AppColors.textPrimary),
        h2: AppTypography.section.copyWith(color: AppColors.textPrimary),
        h3: AppTypography.card,
        h1Padding: const EdgeInsets.only(bottom: 4),
        h2Padding: const EdgeInsets.only(bottom: 4),
        h3Padding: const EdgeInsets.only(bottom: 4),
        strong: const TextStyle(fontWeight: FontWeight.w700),
        blockSpacing: 12,
        listIndent: 24,
        listBullet: textStyle,
        blockquote: textStyle.copyWith(color: AppColors.textSecondary),
        blockquotePadding: const EdgeInsets.all(12),
        blockquoteDecoration: const BoxDecoration(
          color: AppColors.surfaceSubtle,
          border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
        ),
        code: textStyle.copyWith(
          fontFamily: 'monospace',
          fontSize: 14,
          backgroundColor: AppColors.primarySoft,
        ),
      ),
      // Body images are unsupported, including remote, asset and file URLs.
      // The Markdown renderer does not execute HTML or scripts.
      imageBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}

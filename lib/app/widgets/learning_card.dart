import 'package:flutter/material.dart';

import '../app_ui_tokens.dart';

/// 학습 진입 카드의 표면. 탭 동작은 호출 화면에서 그대로 전달합니다.
class LearningCard extends StatelessWidget {
  const LearningCard({
    super.key,
    required this.child,
    this.onTap,
    this.emphasizedShadow = false,
    this.margin = EdgeInsets.zero,
  });
  final Widget child;
  final VoidCallback? onTap;
  final bool emphasizedShadow;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) => Padding(
    padding: margin,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: emphasizedShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .12),
                  blurRadius: 20,
                  offset: const Offset(0, 7),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: .05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: child),
      ),
    ),
  );
}

/// 카드는 하나의 탭 영역이며 화살표는 시각적 안내입니다.

class LearningCardArrow extends StatelessWidget {
  const LearningCardArrow({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.arrow_forward_rounded,
        size: 18,
        color: Colors.white,
      ),
    ),
  );
}

class ChapterNumber extends StatelessWidget {
  const ChapterNumber(this.number, {super.key});
  final String number;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 48, minHeight: 52),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: .18),
          offset: const Offset(0, 4),
          blurRadius: 8,
        ),
      ],
    ),
    child: Text(
      number,
      textAlign: TextAlign.center,
      style: AppTypography.section.copyWith(color: AppColors.primary),
    ),
  );
}

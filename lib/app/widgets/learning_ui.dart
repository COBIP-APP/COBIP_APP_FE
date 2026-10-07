import 'package:flutter/material.dart';

import '../app_ui_tokens.dart';

// 학습/문제/챗봇 영역 전용 시각 스타일. 전역 테마와 화면 동작은 변경하지 않습니다.
final learningUiTheme = appUiTheme.copyWith(
  chipTheme: appUiTheme.chipTheme.copyWith(
    backgroundColor: AppColors.surface,
    selectedColor: AppColors.primarySoft,
    checkmarkColor: AppColors.primary,
    labelStyle: AppTypography.link.copyWith(color: AppColors.primary),
    side: const BorderSide(color: AppColors.border),
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.primary,
    linearTrackColor: AppColors.primarySoft,
    linearMinHeight: 6,
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.pill)),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.surface,
    elevation: 3,
    shape: CircleBorder(),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.background,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    showDragHandle: true,
  ),
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.all(AppSpacing.card),
    titleTextStyle: AppTypography.card,
    subtitleTextStyle: AppTypography.helper,
    iconColor: AppColors.primary,
    minVerticalPadding: 12,
  ),
);

class LearningTheme extends StatelessWidget {
  const LearningTheme({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Theme(data: learningUiTheme, child: child);
}

class LearningBody extends StatelessWidget {
  const LearningBody({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSpacing.contentWidth),
      child: child,
    ),
  );
}

class LearningIcon extends StatelessWidget {
  const LearningIcon(this.icon, {super.key, this.size = 44});
  final IconData icon;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Icon(icon, color: AppColors.primary, size: size * .5),
    ),
  );
}

class LearningIntro extends StatelessWidget {
  const LearningIntro({
    super.key,
    required this.title,
    required this.lines,
    required this.icon,
  });
  final String title;
  final List<String> lines;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.section),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text(title, style: AppTypography.title)),
            const SizedBox(width: 12),
            LearningIcon(icon, size: 52),
          ],
        ),
        const SizedBox(height: 12),
        for (final line in lines) Text(line, style: AppTypography.helper),
      ],
    ),
  );
}

class LearningBadge extends StatelessWidget {
  const LearningBadge(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(AppRadii.pill),
    ),
    child: Text(
      label,
      style: AppTypography.meta.copyWith(color: AppColors.primary),
    ),
  );
}

class LearningCode extends StatelessWidget {
  const LearningCode(this.code, {super.key});
  final String code;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.card),
    decoration: BoxDecoration(
      color: AppColors.surfaceSubtle,
      borderRadius: BorderRadius.circular(AppRadii.control),
      border: Border.all(color: AppColors.border),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            List.generate(
              code.split('\n').length,
              (i) => '${i + 1}',
            ).join('\n'),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              height: 22 / 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          SelectableText(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              height: 22 / 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}

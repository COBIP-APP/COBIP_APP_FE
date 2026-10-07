import 'package:flutter/material.dart';

import '../app_ui_tokens.dart';

class LearningCodeFrame extends StatelessWidget {
  const LearningCodeFrame({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surfaceSubtle,
      borderRadius: BorderRadius.circular(AppRadii.control),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.code_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'CODE',
                style: AppTypography.meta.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              const ExcludeSemantics(
                child: Icon(
                  Icons.more_horiz,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Padding(padding: const EdgeInsets.all(16), child: child),
      ],
    ),
  );
}

class LearningArt extends StatelessWidget {
  const LearningArt(this.name, {super.key, this.size = 96});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'assets/images/auth/$name.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => SizedBox(
        width: size,
        height: size,
        child: const Icon(
          Icons.auto_awesome_outlined,
          color: AppColors.primary,
          size: 40,
        ),
      ),
    ),
  );
}

/// 대표 영역만 연보라색으로 강조하고 본문은 흰 카드로 분리합니다.
class LearningHero extends StatelessWidget {
  const LearningHero({
    super.key,
    required this.title,
    required this.description,
    this.eyebrow,
    this.art = 'home_learning',
    this.child,
  });
  final String title, description, art;
  final String? eyebrow;
  final Widget? child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.hero),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppRadii.hero),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eyebrow != null) ...[
                    Text(
                      eyebrow!,
                      style: AppTypography.meta.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(title, style: AppTypography.detail),
                ],
              ),
            ),
            if (MediaQuery.textScalerOf(context).scale(14) < 21) ...[
              const SizedBox(width: 8),
              LearningArt(art, size: 80),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(description, style: AppTypography.helper),
        if (child != null) ...[const SizedBox(height: 20), child!],
      ],
    ),
  );
}

class LearningSection extends StatelessWidget {
  const LearningSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.label,
  });
  final String title;
  final String? label;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surfaceSubtle,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (label != null)
                      Text(
                        label!,
                        style: AppTypography.meta.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    Text(title, style: AppTypography.card),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.all(16), child: child),
      ],
    ),
  );
}

class LearningNotice extends StatelessWidget {
  const LearningNotice(this.text, {super.key, this.icon = Icons.info_outline});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surfaceSubtle,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTypography.helper)),
      ],
    ),
  );
}

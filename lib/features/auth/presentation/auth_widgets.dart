import 'package:flutter/material.dart';

import '../../../app/app_ui_tokens.dart';
export '../../../app/app_ui_tokens.dart';

const authPrimary = AppColors.primary;
const authMuted = AppColors.textSecondary;
const authSuccess = AppColors.success;
const authInputFill = AppColors.surfaceSubtle;

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.decorated = false,
  });
  final Widget body;
  final PreferredSizeWidget? appBar;
  final bool decorated;

  @override
  Widget build(BuildContext context) => Theme(
    data: appUiTheme,
    child: Scaffold(
      appBar: appBar,
      body: Stack(
        children: [
          if (decorated) ...[
            Positioned(top: -80, left: -100, child: _backgroundShape(240)),
            Positioned(top: 70, right: -100, child: _backgroundShape(160)),
            Positioned(bottom: -200, right: -140, child: _backgroundShape(440)),
          ],
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.contentWidth + 40,
                ),
                child: body,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _backgroundShape(double size) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: AppColors.surfaceSubtle,
      shape: BoxShape.circle,
    ),
  );
}

class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key, this.size = 34});
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    'COBIA',
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: size,
      color: authPrimary,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.5,
    ),
  );
}

class AuthIllustration extends StatelessWidget {
  const AuthIllustration({super.key, required this.name, this.height = 132});
  final String name;
  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/auth/$name.png',
    height: height,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
    errorBuilder: (_, _, _) => ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: const Icon(Icons.image_outlined, size: 48, color: authMuted),
      ),
    ),
  );
}

class AuthLabeledField extends StatelessWidget {
  const AuthLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.icon,
  });
  final String label;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 24, color: authMuted),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: AppTypography.helper.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      child,
    ],
  );
}

// 큰 글씨/좁은 화면에서는 인증 버튼이 입력칸의 공간을 차지하지 않게 합니다.
class AuthFieldAction extends StatelessWidget {
  const AuthFieldAction({super.key, required this.field, required this.action});
  final Widget field;
  final Widget action;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(14) >= 21) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [field, const SizedBox(height: 8), action],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: field),
          const SizedBox(width: 8),
          action,
        ],
      );
    },
  );
}

class AuthButtonLabel extends StatelessWidget {
  const AuthButtonLabel({
    super.key,
    required this.label,
    required this.isLoading,
  });
  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => isLoading
      ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            const Flexible(child: Text('처리 중…')),
          ],
        )
      : Text(label, textAlign: TextAlign.center);
}

class AuthCompletionBody extends StatelessWidget {
  const AuthCompletionBody({
    super.key,
    required this.illustration,
    required this.title,
    required this.subtitle,
    required this.note,
    required this.buttonLabel,
    required this.onContinue,
  });
  final String illustration;
  final String title;
  final String subtitle;
  final String note;
  final String buttonLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: AppSpacing.pagePadding(context, top: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (constraints.maxHeight - 64).clamp(0, double.infinity),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthBrand(),
            Column(
              children: [
                const SizedBox(height: 32),
                AuthIllustration(
                  name: illustration,
                  height: constraints.maxHeight < 500 ? 120 : 210,
                ),
                const SizedBox(height: 32),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.title,
                ),
                const SizedBox(height: 12),
                Text(subtitle, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Text(
                  note,
                  textAlign: TextAlign.center,
                  style: AppTypography.helper,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: FilledButton(
                onPressed: onContinue,
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

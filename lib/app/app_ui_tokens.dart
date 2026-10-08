import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF5538F2);
  static const primaryPressed = Color(0xFF432BC7);
  static const primarySoft = Color(0xFFEEEAFE);
  static const accent = Color(0xFF8B5CF6);
  static const background = Color(0xFFF9F8FF);
  static const surface = Colors.white;
  static const surfaceSubtle = Color(0xFFF5F2FC);
  static const navigationBackground = Color(0xFF5338AD);
  static const navigationForeground = Colors.white;
  static const textPrimary = Color(0xFF292638);
  static const textSecondary = Color(0xFF706B7F);
  static const border = Color(0xFFE6E1F0);
  static const success = Color(0xFF23815A);
  static const error = Color(0xFFC33F60);
  static const warning = Color(0xFF8A5A12);
}

abstract final class AppSpacing {
  static const card = 16.0;
  static const hero = 20.0;
  static const section = 32.0;
  static const block = 40.0;
  static const contentWidth = 560.0;

  static EdgeInsets pagePadding(BuildContext context, {double top = 16}) =>
      EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width < 360 ? 16 : 20,
        top,
        MediaQuery.sizeOf(context).width < 360 ? 16 : 20,
        24,
      );
}

abstract final class AppRadii {
  static const card = 16.0;
  static const hero = 20.0;
  static const control = 12.0;
  static const pill = 999.0;
}

abstract final class AppTypography {
  static const title = TextStyle(
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w700,
  );
  static const detail = TextStyle(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
  );
  static const section = TextStyle(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w700,
  );
  static const card = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
  );
  static const body = TextStyle(fontSize: 16, height: 24 / 16);
  static const helper = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  static const button = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
  );
  static const link = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );
  static const meta = TextStyle(
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}

// 담당 인증/홈 화면에서만 사용합니다. 다른 팀원 화면의 테마는 유지합니다.
final appUiTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
    primary: AppColors.primary,
    onPrimary: AppColors.surface,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    error: AppColors.error,
    outline: AppColors.border,
  ),
  scaffoldBackgroundColor: AppColors.background,
  textTheme:
      const TextTheme(
        headlineLarge: AppTypography.title,
        headlineMedium: AppTypography.detail,
        titleLarge: AppTypography.section,
        titleMedium: AppTypography.card,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.helper,
        labelLarge: AppTypography.link,
        labelSmall: AppTypography.meta,
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.textPrimary,
    surfaceTintColor: Colors.transparent,
    centerTitle: true,
    iconTheme: IconThemeData(color: AppColors.textSecondary, size: 24),
    titleTextStyle: AppTypography.card,
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    constraints: const BoxConstraints(minHeight: 52),
    hintStyle: AppTypography.helper,
    errorStyle: AppTypography.helper.copyWith(color: AppColors.error),
    errorMaxLines: 3,
    contentPadding: const EdgeInsets.all(16),
    border: _inputBorder(AppColors.border),
    enabledBorder: _inputBorder(AppColors.border),
    disabledBorder: _inputBorder(AppColors.border),
    focusedBorder: _inputBorder(AppColors.primary, 2),
    errorBorder: _inputBorder(AppColors.error, 2),
    focusedErrorBorder: _inputBorder(AppColors.error, 2),
    suffixIconColor: AppColors.textSecondary,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style:
        FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primarySoft,
          disabledForegroundColor: AppColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          textStyle: AppTypography.button,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.primarySoft
                : states.contains(WidgetState.pressed)
                ? AppColors.primaryPressed
                : AppColors.primary,
          ),
        ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      foregroundColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      textStyle: AppTypography.link,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      minimumSize: const Size(48, 48),
      textStyle: AppTypography.link,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      side: const BorderSide(color: AppColors.border),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.navigationBackground,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    indicatorColor: AppColors.surface,
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(WidgetState.selected)
            ? AppColors.navigationBackground
            : AppColors.navigationForeground,
      ),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => AppTypography.meta.copyWith(
        color: AppColors.navigationForeground,
        fontWeight: states.contains(WidgetState.selected)
            ? FontWeight.w700
            : FontWeight.w500,
      ),
    ),
  ),
);

OutlineInputBorder _inputBorder(Color color, [double width = 1]) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
      borderSide: BorderSide(color: color, width: width),
    );

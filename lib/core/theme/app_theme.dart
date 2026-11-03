import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    fontFamily: AppTypography.fontFamily,
    scaffoldBackgroundColor: AppColors.white,
    colorScheme: _colorScheme,
    textTheme: _textTheme,
  );

  static const _colorScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.primaryTint,
    onPrimaryContainer: AppColors.primary,
    secondary: AppColors.gray700,
    onSecondary: AppColors.white,
    surface: AppColors.white,
    onSurface: AppColors.gray900,
    onSurfaceVariant: AppColors.gray700,
    surfaceContainerLowest: AppColors.white,
    surfaceContainerLow: AppColors.white,
    surfaceContainer: AppColors.white,
    surfaceContainerHigh: AppColors.white,
    surfaceContainerHighest: AppColors.gray100,
    // 기본값은 primary라서, 높이가 있는 표면에 경희레드가 섞여 보인다.
    surfaceTint: Colors.transparent,
    outline: AppColors.gray300,
    outlineVariant: AppColors.gray200,
  );

  // Material 위젯이 7단계 밖의 기본 스타일을 쓰지 않도록 모든 슬롯을 7단계 중 하나로 채운다.
  // 기본 Text가 bodyMedium을 쓰므로 bodyMedium은 본문(Body1)으로 둔다.
  static const _textTheme = TextTheme(
    displayLarge: AppTypography.h1,
    displayMedium: AppTypography.h1,
    displaySmall: AppTypography.h1,
    headlineLarge: AppTypography.h1,
    headlineMedium: AppTypography.h1,
    headlineSmall: AppTypography.h1,
    titleLarge: AppTypography.h2,
    titleMedium: AppTypography.h3,
    titleSmall: AppTypography.label,
    bodyLarge: AppTypography.body1,
    bodyMedium: AppTypography.body1,
    bodySmall: AppTypography.body2,
    labelLarge: AppTypography.label,
    labelMedium: AppTypography.label,
    labelSmall: AppTypography.caption,
  );
}

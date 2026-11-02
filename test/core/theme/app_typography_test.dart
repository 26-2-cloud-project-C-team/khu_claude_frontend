import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/theme/app_colors.dart';
import 'package:team_frontend/core/theme/app_typography.dart';

void main() {
  void expectStyle(
    TextStyle style, {
    required double size,
    required FontWeight weight,
    required double lineHeight,
    required double letterSpacing,
    required Color color,
  }) {
    expect(style.fontFamily, 'Pretendard');
    expect(style.fontSize, size);
    expect(style.fontWeight, weight);
    expect(style.fontSize! * style.height!, closeTo(lineHeight, 1e-9));
    expect(style.letterSpacing, closeTo(letterSpacing, 1e-9));
    expect(style.color, color);
  }

  test('H1은 24 / 700 / 34, 자간 -2%다', () {
    expectStyle(
      AppTypography.h1,
      size: 24,
      weight: FontWeight.w700,
      lineHeight: 34,
      letterSpacing: -0.48,
      color: AppColors.gray900,
    );
  });

  test('H2는 20 / 700 / 28, 자간 -2%다', () {
    expectStyle(
      AppTypography.h2,
      size: 20,
      weight: FontWeight.w700,
      lineHeight: 28,
      letterSpacing: -0.40,
      color: AppColors.gray900,
    );
  });

  test('H3는 17 / 600 / 24, 자간 -1%다', () {
    expectStyle(
      AppTypography.h3,
      size: 17,
      weight: FontWeight.w600,
      lineHeight: 24,
      letterSpacing: -0.17,
      color: AppColors.gray900,
    );
  });

  test('Body1은 15 / 400 / 22, 자간 -1%다', () {
    expectStyle(
      AppTypography.body1,
      size: 15,
      weight: FontWeight.w400,
      lineHeight: 22,
      letterSpacing: -0.15,
      color: AppColors.gray900,
    );
  });

  test('Body2는 14 / 400 / 20, 자간 -1%다', () {
    expectStyle(
      AppTypography.body2,
      size: 14,
      weight: FontWeight.w400,
      lineHeight: 20,
      letterSpacing: -0.14,
      color: AppColors.gray700,
    );
  });

  test('Label은 13 / 500 / 18, 자간 -1%다', () {
    expectStyle(
      AppTypography.label,
      size: 13,
      weight: FontWeight.w500,
      lineHeight: 18,
      letterSpacing: -0.13,
      color: AppColors.gray700,
    );
  });

  test('Caption은 12 / 400 / 16, 자간 -1%다', () {
    expectStyle(
      AppTypography.caption,
      size: 12,
      weight: FontWeight.w400,
      lineHeight: 16,
      letterSpacing: -0.12,
      color: AppColors.gray500,
    );
  });
}

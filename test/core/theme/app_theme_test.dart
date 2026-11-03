import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/theme/app_colors.dart';
import 'package:team_frontend/core/theme/app_theme.dart';
import 'package:team_frontend/core/theme/app_typography.dart';

void main() {
  final theme = AppTheme.light;

  test('Primary와 기본 배경이 토큰 값을 쓴다', () {
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.colorScheme.onSurface, AppColors.gray900);
    expect(theme.scaffoldBackgroundColor, AppColors.white);
  });

  test('TextTheme의 모든 슬롯이 7단계 중 하나다', () {
    final allowed = [
      AppTypography.h1,
      AppTypography.h2,
      AppTypography.h3,
      AppTypography.body1,
      AppTypography.body2,
      AppTypography.label,
      AppTypography.caption,
    ];
    final t = theme.textTheme;
    final slots = [
      t.displayLarge,
      t.displayMedium,
      t.displaySmall,
      t.headlineLarge,
      t.headlineMedium,
      t.headlineSmall,
      t.titleLarge,
      t.titleMedium,
      t.titleSmall,
      t.bodyLarge,
      t.bodyMedium,
      t.bodySmall,
      t.labelLarge,
      t.labelMedium,
      t.labelSmall,
    ];

    for (final slot in slots) {
      expect(
        allowed.any(
          (s) =>
              s.fontSize == slot!.fontSize &&
              s.fontWeight == slot.fontWeight &&
              s.height == slot.height &&
              s.color == slot.color,
        ),
        isTrue,
        reason: '$slot',
      );
    }
  });

  test('기본 Text 스타일은 Body1이다', () {
    expect(theme.textTheme.bodyMedium!.fontSize, AppTypography.body1.fontSize);
    expect(theme.textTheme.bodyMedium!.color, AppTypography.body1.color);
  });
}

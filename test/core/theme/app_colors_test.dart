import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/theme/app_colors.dart';

void main() {
  final cases = [
    ('Primary', AppColors.primary, 0xFFA40F16),
    ('Primary Pressed', AppColors.primaryPressed, 0xFF8B0D13),
    ('Primary Tint', AppColors.primaryTint, 0xFFFBEDEE),
    ('Gold', AppColors.gold, 0xFFC3A353),
    ('경희블루', AppColors.khuBlue, 0xFF0D326F),
    ('Positive', AppColors.positive, 0xFF0E8A5F),
    ('Positive Tint', AppColors.positiveTint, 0xFFE3F5EC),
    ('Gray 900', AppColors.gray900, 0xFF191F28),
    ('Gray 700', AppColors.gray700, 0xFF4E5968),
    ('Gray 600', AppColors.gray600, 0xFF6B7684),
    ('Gray 500', AppColors.gray500, 0xFF8B95A1),
    ('Gray 400', AppColors.gray400, 0xFFB0B8C1),
    ('Gray 300', AppColors.gray300, 0xFFD6DADF),
    ('Gray 200', AppColors.gray200, 0xFFE5E8EB),
    ('Gray 100', AppColors.gray100, 0xFFF2F4F6),
    ('Gray 50', AppColors.gray50, 0xFFF9FAFB),
    ('White', AppColors.white, 0xFFFFFFFF),
    ('Dim', AppColors.dim, 0x73191F28),
  ];

  for (final (name, color, argb) in cases) {
    test('$name 컬러가 디자인 시스템 값과 일치한다', () {
      expect(color.toARGB32(), argb);
    });
  }
}

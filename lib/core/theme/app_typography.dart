import 'package:flutter/painting.dart';

import 'app_colors.dart';

// 시안(CSS)의 line-height처럼 남는 높이를 글자 위아래에 똑같이 나누도록 leadingDistribution을 even으로 둔다.
abstract final class AppTypography {
  static const fontFamily = 'Pretendard';

  static const h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 34 / 24,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 24 * -0.02,
    color: AppColors.gray900,
  );

  static const h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 28 / 20,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 20 * -0.02,
    color: AppColors.gray900,
  );

  static const h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 24 / 17,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 17 * -0.01,
    color: AppColors.gray900,
  );

  static const body1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 22 / 15,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 15 * -0.01,
    color: AppColors.gray900,
  );

  static const body2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 14 * -0.01,
    color: AppColors.gray700,
  );

  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 18 / 13,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 13 * -0.01,
    color: AppColors.gray700,
  );

  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 12 * -0.01,
    color: AppColors.gray500,
  );
}

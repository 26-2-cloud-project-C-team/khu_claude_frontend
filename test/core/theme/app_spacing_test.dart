import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/theme/app_spacing.dart';

void main() {
  test('간격 토큰이 디자인 시스템 값과 일치한다', () {
    expect(AppSpacing.textLine, 4);
    expect(AppSpacing.inside, 8);
    expect(AppSpacing.between, 12);
    expect(AppSpacing.cardPadding, 16);
    expect(AppSpacing.screenHorizontal, 20);
    expect(AppSpacing.belowTitle, 24);
    expect(AppSpacing.item, 24);
    expect(AppSpacing.section, 32);
  });

  test('반경 토큰이 디자인 시스템 값과 일치한다', () {
    expect(AppRadius.control, 12);
    expect(AppRadius.option, 14);
    expect(AppRadius.card, 16);
    expect(AppRadius.bottomSheet, 24);
  });
}

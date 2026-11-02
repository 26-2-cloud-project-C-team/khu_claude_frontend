import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/theme/app_colors.dart';
import 'package:team_frontend/core/widgets/app_badge.dart';

import '../../helpers/pump_test_app.dart';

void main() {
  final cases = [
    ('공개', AppBadgeTone.positive, AppColors.positiveTint, AppColors.positive),
    ('비공개', AppBadgeTone.neutral, AppColors.gray100, AppColors.gray600),
    ('요청 3', AppBadgeTone.primary, AppColors.primaryTint, AppColors.primary),
  ];

  for (final (label, tone, background, foreground) in cases) {
    testWidgets('$label 배지는 정해진 배경·글자 색과 높이 24다', (tester) async {
      await tester.pumpTestApp(
        Center(
          child: AppBadge(label: label, tone: tone),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppBadge),
          matching: find.byType(Container),
        ),
      );
      final textColor = tester
          .renderObject<RenderParagraph>(find.text(label))
          .text
          .style!
          .color;
      expect((container.decoration! as BoxDecoration).color, background);
      expect(textColor, foreground);
      expect(tester.getSize(find.byType(AppBadge)).height, 24);
    });
  }
}

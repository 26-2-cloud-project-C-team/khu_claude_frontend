import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/theme/app_colors.dart';
import 'package:team_frontend/core/widgets/app_card.dart';

void main() {
  testWidgets('카드는 반경 16, 내부 여백 16, Gray 50 배경이다', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: AppCard(child: SizedBox(width: 100, height: 40))),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.gray50);
    expect(decoration.borderRadius, BorderRadius.circular(16));
    expect(tester.getSize(find.byType(AppCard)), const Size(132, 72));
  });
}

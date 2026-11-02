import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/theme/app_colors.dart';
import 'package:team_frontend/core/widgets/app_rating.dart';

import '../../helpers/pump_test_app.dart';

void main() {
  List<Color?> starColors(WidgetTester tester, Finder within) => tester
      .widgetList<Icon>(
        find.descendant(of: within, matching: find.byType(Icon)),
      )
      .map((icon) => icon.color)
      .toList();

  testWidgets('별점 배지는 평균을 소수 한 자리로, 개수를 괄호로 보여준다', (tester) async {
    await tester.pumpTestApp(
      const Center(child: AppRatingBadge(average: 4.56, count: 32)),
    );

    expect(find.text('4.6'), findsOneWidget);
    expect(find.text('(32)'), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.star_rounded)).color,
      AppColors.gold,
    );
  });

  testWidgets('별점 요약은 "★ 4.6 (32)"로 보여준다', (tester) async {
    await tester.pumpTestApp(
      const Center(child: AppRatingSummary(average: 4.6, count: 32)),
    );

    expect(find.text('★ 4.6 (32)', findRichText: true), findsOneWidget);
  });

  testWidgets('별점 표시는 점수만큼 Gold, 나머지는 회색이다', (tester) async {
    await tester.pumpTestApp(const Center(child: AppStars(rating: 3)));

    expect(starColors(tester, find.byType(AppStars)), [
      AppColors.gold,
      AppColors.gold,
      AppColors.gold,
      AppColors.gray200,
      AppColors.gray200,
    ]);
  });

  testWidgets('별점 입력은 누른 별의 점수를 알린다', (tester) async {
    final changes = <int>[];
    await tester.pumpTestApp(
      Center(child: AppRatingInput(value: null, onChanged: changes.add)),
    );

    await tester.tap(find.bySemanticsLabel('4점'));

    expect(changes, [4]);
  });

  testWidgets('별점 입력은 고른 점수까지 Gold로 채운다', (tester) async {
    await tester.pumpTestApp(
      Center(child: AppRatingInput(value: 2, onChanged: (_) {})),
    );

    expect(starColors(tester, find.byType(AppRatingInput)), [
      AppColors.gold,
      AppColors.gold,
      AppColors.gray200,
      AppColors.gray200,
      AppColors.gray200,
    ]);
  });

  testWidgets('고르기 전에는 모든 별이 회색이다', (tester) async {
    await tester.pumpTestApp(
      Center(child: AppRatingInput(value: null, onChanged: (_) {})),
    );

    expect(
      starColors(tester, find.byType(AppRatingInput)),
      everyElement(AppColors.gray200),
    );
  });

  testWidgets('별점 입력의 터치 영역이 44 이상이다', (tester) async {
    await tester.pumpTestApp(
      Center(child: AppRatingInput(value: null, onChanged: (_) {})),
    );

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  });
}

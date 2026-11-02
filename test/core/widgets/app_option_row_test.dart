import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/theme/app_colors.dart';
import 'package:team_frontend/core/widgets/app_option_row.dart';
import 'package:team_frontend/core/widgets/app_selection_mode.dart';

import '../../helpers/pump_test_app.dart';

void main() {
  Future<void> pump(WidgetTester tester, AppOptionRow row) {
    return tester.pumpTestApp(Center(child: row));
  }

  ShapeBorder? shapeOf(WidgetTester tester) => tester
      .widget<Material>(
        find.descendant(
          of: find.byType(AppOptionRow),
          matching: find.byType(Material),
        ),
      )
      .shape;

  Color? backgroundOf(WidgetTester tester) => tester
      .widget<Material>(
        find.descendant(
          of: find.byType(AppOptionRow),
          matching: find.byType(Material),
        ),
      )
      .color;

  Color? textColorOf(WidgetTester tester, String text) =>
      tester.renderObject<RenderParagraph>(find.text(text)).text.style!.color;

  testWidgets('선택 전에는 Gray 50 배경에 체크가 없다', (tester) async {
    await pump(
      tester,
      AppOptionRow(title: '사담', selected: false, onTap: () {}),
    );

    expect(backgroundOf(tester), AppColors.gray50);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(tester.getSize(find.byType(AppOptionRow)).height, 60);
  });

  testWidgets('선택하면 Primary Tint 배경, Primary 테두리·글자, 체크가 보인다', (tester) async {
    await pump(
      tester,
      AppOptionRow(title: '개인 작업', selected: true, onTap: () {}),
    );

    final shape = shapeOf(tester)! as RoundedRectangleBorder;
    expect(backgroundOf(tester), AppColors.primaryTint);
    expect(shape.side.color, AppColors.primary);
    expect(textColorOf(tester, '개인 작업'), AppColors.primary);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('보조 문구가 있으면 함께 보이고 높이가 64 이상이다', (tester) async {
    await pump(
      tester,
      AppOptionRow(
        title: '가까운 곳',
        subtitle: '출발점에서 직선거리가 짧은 순',
        selected: false,
        onTap: () {},
        mode: AppSelectionMode.multiple,
      ),
    );

    expect(find.text('출발점에서 직선거리가 짧은 순'), findsOneWidget);
    expect(textColorOf(tester, '출발점에서 직선거리가 짧은 순'), AppColors.gray500);
    expect(
      tester.getSize(find.byType(AppOptionRow)).height,
      greaterThanOrEqualTo(64),
    );
  });

  testWidgets('누르면 onTap이 호출된다', (tester) async {
    var tapped = 0;
    await pump(
      tester,
      AppOptionRow(title: '사담', selected: false, onTap: () => tapped++),
    );

    await tester.tap(find.byType(AppOptionRow));

    expect(tapped, 1);
  });

  testWidgets('선택 여부를 접근성 정보로 알린다', (tester) async {
    await pump(tester, AppOptionRow(title: '사담', selected: true, onTap: () {}));

    expect(
      tester.getSemantics(find.byType(AppOptionRow)),
      matchesSemantics(
        isChecked: true,
        hasCheckedState: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
        label: '사담',
      ),
    );
  });

  testWidgets('터치 영역이 44 이상이다', (tester) async {
    await pump(
      tester,
      AppOptionRow(title: '사담', selected: false, onTap: () {}),
    );

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  });
}

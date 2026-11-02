import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/theme/app_colors.dart';
import 'package:team_frontend/core/theme/app_theme.dart';
import 'package:team_frontend/core/widgets/app_chip.dart';
import 'package:team_frontend/core/widgets/app_selection_mode.dart';

void main() {
  Future<void> pump(WidgetTester tester, AppChip chip) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Center(child: chip)),
      ),
    );
  }

  Finder chipBody() => find.descendant(
    of: find.byType(AppChip),
    matching: find.byWidgetPredicate(
      (w) => w is Container && w.decoration is BoxDecoration,
    ),
  );

  Color? backgroundOf(WidgetTester tester) =>
      (tester.widget<Container>(chipBody()).decoration! as BoxDecoration).color;

  Color? textColorOf(WidgetTester tester, String text) =>
      tester.renderObject<RenderParagraph>(find.text(text)).text.style!.color;

  testWidgets('기본 상태는 Gray 100 배경, Gray 700 글자, 높이 36이다', (tester) async {
    await pump(tester, AppChip(label: '조용함', selected: false, onTap: () {}));

    expect(backgroundOf(tester), AppColors.gray100);
    expect(textColorOf(tester, '조용함'), AppColors.gray700);
    expect(tester.getSize(chipBody()).height, 36);
  });

  testWidgets('선택하면 Primary 배경에 흰 글자다', (tester) async {
    await pump(tester, AppChip(label: '조용함', selected: true, onTap: () {}));

    expect(backgroundOf(tester), AppColors.primary);
    expect(textColorOf(tester, '조용함'), AppColors.white);
  });

  testWidgets('단일 선택 칩은 선택돼도 체크가 없다', (tester) async {
    await pump(tester, AppChip(label: '조용함', selected: true, onTap: () {}));

    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('다중 선택 칩은 선택되면 체크가 보인다', (tester) async {
    await pump(
      tester,
      AppChip(
        label: '충전 가능',
        selected: true,
        onTap: () {},
        mode: AppSelectionMode.multiple,
      ),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('다중 선택 칩도 선택 전에는 체크가 없다', (tester) async {
    await pump(
      tester,
      AppChip(
        label: '충전 가능',
        selected: false,
        onTap: () {},
        mode: AppSelectionMode.multiple,
      ),
    );

    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('칩 바깥 여백을 눌러도 onTap이 호출된다', (tester) async {
    var tapped = 0;
    await pump(
      tester,
      AppChip(label: '조용함', selected: false, onTap: () => tapped++),
    );

    final body = tester.getRect(chipBody());
    await tester.tapAt(Offset(body.center.dx, body.top - 3));

    expect(tapped, 1);
  });

  testWidgets('터치 영역이 44 이상이다', (tester) async {
    await pump(tester, AppChip(label: '사담', selected: false, onTap: () {}));

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  });
}

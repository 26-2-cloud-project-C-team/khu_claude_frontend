import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/theme/app_colors.dart';
import 'package:team_frontend/core/theme/app_theme.dart';
import 'package:team_frontend/core/widgets/app_button.dart';

void main() {
  Future<void> pump(WidgetTester tester, AppButton button) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Center(child: button)),
      ),
    );
  }

  Color? backgroundOf(WidgetTester tester) => tester
      .widget<Material>(
        find.descendant(
          of: find.byType(TextButton),
          matching: find.byType(Material),
        ),
      )
      .color;

  TextStyle labelStyleOf(WidgetTester tester, String label) =>
      tester.renderObject<RenderParagraph>(find.text(label)).text.style!;

  testWidgets('Primary 버튼은 경희레드 배경에 흰 글자, 높이 56이다', (tester) async {
    await pump(tester, AppButton(label: '다음', onPressed: () {}));

    expect(backgroundOf(tester), AppColors.primary);
    expect(labelStyleOf(tester, '다음').color, AppColors.white);
    expect(tester.getSize(find.byType(AppButton)).height, 56);
  });

  testWidgets('Secondary 버튼은 Gray 100 배경에 Gray 900 글자다', (tester) async {
    await pump(
      tester,
      AppButton(
        label: '취소',
        onPressed: () {},
        variant: AppButtonVariant.secondary,
      ),
    );

    expect(backgroundOf(tester), AppColors.gray100);
    expect(labelStyleOf(tester, '취소').color, AppColors.gray900);
  });

  testWidgets('onPressed가 없으면 비활성 색으로 바뀌고 눌러도 반응하지 않는다', (tester) async {
    await pump(tester, const AppButton(label: '다음', onPressed: null));

    expect(backgroundOf(tester), AppColors.gray100);
    expect(labelStyleOf(tester, '다음').color, AppColors.gray400);
    expect(tester.widget<TextButton>(find.byType(TextButton)).enabled, isFalse);
  });

  testWidgets('누르면 onPressed가 호출된다', (tester) async {
    var pressed = 0;
    await pump(tester, AppButton(label: '다음', onPressed: () => pressed++));

    await tester.tap(find.text('다음'));

    expect(pressed, 1);
  });

  testWidgets('텍스트 버튼은 밑줄 친 Gray 600 글자, 높이 44다', (tester) async {
    await pump(
      tester,
      AppButton(
        label: '후기 없이 별점만 등록',
        onPressed: () {},
        variant: AppButtonVariant.text,
      ),
    );

    final style = labelStyleOf(tester, '후기 없이 별점만 등록');
    expect(style.color, AppColors.gray600);
    expect(style.decoration, TextDecoration.underline);
    expect(tester.getSize(find.byType(AppButton)).height, 44);
  });

  testWidgets('모든 변형의 터치 영역이 44 이상이다', (tester) async {
    for (final variant in AppButtonVariant.values) {
      await pump(
        tester,
        AppButton(label: '버튼', onPressed: () {}, variant: variant),
      );

      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    }
  });
}

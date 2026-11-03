import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/widgets/app_text_field.dart';

import '../../helpers/pump_test_app.dart';

void main() {
  Future<void> pump(WidgetTester tester, AppTextField field) {
    return tester.pumpTestApp(Center(child: field));
  }

  testWidgets('한 줄 입력은 높이 56이고 플레이스홀더를 보여준다', (tester) async {
    await pump(tester, const AppTextField(placeholder: '공간 이름'));

    expect(find.text('공간 이름'), findsOneWidget);
    expect(tester.getSize(find.byType(AppTextField)).height, 56);
  });

  testWidgets('여러 줄 입력은 글자 수를 "현재 / 최대"로 보여준다', (tester) async {
    await pump(tester, const AppTextField(lines: 5, maxLength: 200));

    expect(find.text('0 / 200'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '조용하고 좋아요');
    await tester.pump();

    expect(find.text('8 / 200'), findsOneWidget);
  });

  testWidgets('최대 글자 수를 넘겨 입력되지 않는다', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pump(
      tester,
      AppTextField(controller: controller, lines: 3, maxLength: 40),
    );

    await tester.enterText(find.byType(TextField), '가' * 45);
    await tester.pump();

    expect(controller.text.length, 40);
    expect(find.text('40 / 40'), findsOneWidget);
  });

  testWidgets('최대 글자 수가 없으면 카운터를 보여주지 않는다', (tester) async {
    await pump(tester, const AppTextField(lines: 3));

    expect(find.textContaining(' / '), findsNothing);
  });

  testWidgets('입력할 때마다 onChanged가 호출된다', (tester) async {
    final values = <String>[];
    await pump(tester, AppTextField(onChanged: values.add));

    await tester.enterText(find.byType(TextField), '열람실');

    expect(values, ['열람실']);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/widgets/app_toast.dart';

void main() {
  testWidgets('문구와 액션을 한 줄로 보여 주고 액션을 누르면 콜백을 부른다', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppToast(
            message: '비공개로 바꿨어요',
            actionLabel: '되돌리기',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('비공개로 바꿨어요'), findsOneWidget);
    await tester.tap(find.text('되돌리기'));
    expect(tapped, isTrue);
    expect(tester.getSize(find.byType(AppToast)).height, 44);
  });

  testWidgets('액션이 없으면 버튼을 그리지 않는다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppToast(message: '고친 내용을 반영했어요'))),
    );

    expect(find.byType(TextButton), findsNothing);
  });
}

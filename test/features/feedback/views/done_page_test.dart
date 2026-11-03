import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/features/feedback/views/done_page.dart';

void main() {
  testWidgets('종류에 맞는 제목을 보여주고 확인을 누르면 알린다', (tester) async {
    var confirmed = 0;
    await tester.pumpWidget(MaterialApp(
      home: DonePage(kind: DoneKind.reinspection, onConfirm: () => confirmed++),
    ));

    expect(find.text('요청을 보냈어요'), findsOneWidget);
    await tester.tap(find.text('확인'));

    expect(confirmed, 1);
  });

  testWidgets('시스템 뒤로가기도 확인과 같다', (tester) async {
    var confirmed = 0;
    await tester.pumpWidget(MaterialApp(
      home: DonePage(kind: DoneKind.review, onConfirm: () => confirmed++),
    ));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(confirmed, 1);
    expect(find.text('후기를 남겨주셔서 감사해요'), findsOneWidget);
  });
}

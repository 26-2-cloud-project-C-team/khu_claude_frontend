import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/features/feedback/viewmodels/reinspection_view_model.dart';
import 'package:team_frontend/features/feedback/views/reinspection_page.dart';

import '../../../fakes/fake_feedback_repository.dart';

void main() {
  testWidgets('항목을 하나 골라야 요청을 보낼 수 있다', (tester) async {
    final repo = FakeFeedbackRepository();
    var done = 0;
    await tester.pumpWidget(MaterialApp(
      home: ReinspectionPage(
        viewModel: ReinspectionViewModel(repository: repo, spaceId: 1),
        onDone: () => done++,
        onClose: () {},
      ),
    ));

    final send = find.widgetWithText(FilledButton, '요청 보내기');
    expect(tester.widget<FilledButton>(send).onPressed, isNull);

    await tester.tap(find.text('이용 가능 시간'));
    await tester.pump();
    await tester.tap(send);
    await tester.pumpAndSettle();

    expect(done, 1);
    expect(repo.reinspections, hasLength(1));
  });
}

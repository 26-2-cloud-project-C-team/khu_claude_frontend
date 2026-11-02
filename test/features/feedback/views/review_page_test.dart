import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/features/feedback/viewmodels/review_view_model.dart';
import 'package:team_frontend/features/feedback/views/review_page.dart';

import '../../../fakes/fake_feedback_repository.dart';

void main() {
  testWidgets('별점을 고르면 다음이 켜지고 별점만 등록할 수 있다', (tester) async {
    final repo = FakeFeedbackRepository();
    final vm = ReviewViewModel(repository: repo, spaceId: 1);
    var done = 0;
    await tester.pumpWidget(MaterialApp(
      home: ReviewPage(
        viewModel: vm,
        spaceName: '중앙도서관 4층 열람실',
        onDone: () => done++,
        onClose: () {},
      ),
    ));
    await tester.pumpAndSettle();

    final next = find.widgetWithText(FilledButton, '다음');
    expect(tester.widget<FilledButton>(next).onPressed, isNull);

    await tester.tap(find.byTooltip('4점'));
    await tester.pump();
    expect(find.text('4점 · 만족해요'), findsOneWidget);

    await tester.tap(next);
    await tester.pump();
    expect(find.text('간단한 후기 작성을 부탁드려요'), findsOneWidget);

    await tester.tap(find.text('후기 없이 별점만 등록'));
    await tester.pumpAndSettle();

    expect(done, 1);
    expect(repo.reviews.single.rating, 4);
    expect(repo.reviews.single.text, isNull);
  });
}

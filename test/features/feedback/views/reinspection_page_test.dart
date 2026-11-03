import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/widgets/app_chip.dart';
import 'package:team_frontend/core/widgets/app_button.dart';
import 'package:team_frontend/features/feedback/viewmodels/reinspection_view_model.dart';
import 'package:team_frontend/features/feedback/views/reinspection_page.dart';

import '../../../helpers/pump_test_app.dart';
import '../../../fakes/fake_feedback_repository.dart';

void main() {
  testWidgets('항목을 하나 골라야 요청을 보낼 수 있다', (tester) async {
    final repo = FakeFeedbackRepository();
    var done = 0;
    await tester.pumpTestApp(
      ReinspectionPage(
        viewModel: ReinspectionViewModel(repository: repo, spaceId: 1),
        onDone: () => done++,
        onClose: () {},
      ),
    );

    final send = find.widgetWithText(AppButton, '요청 보내기');
    expect(tester.widget<AppButton>(send).onPressed, isNull);
    for (final label in ['이용 시간 · 분위기', '테이블 · 시설', '위치 · 사진', '출입 · 취식 규칙', '폐쇄 · 이전', '기타']) {
      expect(find.widgetWithText(AppChip, label), findsOneWidget);
    }

    await tester.tap(find.text('이용 시간 · 분위기'));
    await tester.pump();
    await tester.tap(send);
    await tester.pumpAndSettle();

    expect(done, 1);
    expect(repo.reinspections, hasLength(1));
  });
}

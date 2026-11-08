import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:team_frontend/features/admin_spaces/data/admin_space_repository.dart';
import 'package:team_frontend/features/admin_spaces/data/mock_admin_space_repository.dart';
import 'package:team_frontend/features/admin_spaces/viewmodels/admin_space_list_view_model.dart';
import 'package:team_frontend/features/admin_spaces/views/admin_space_detail_page.dart';

import '../../../helpers/pump_test_app.dart';

void main() {
  group('AdminSpaceDetailPage (AD-04)', () {
    late MockAdminSpaceRepository repository;

    setUp(() {
      repository = MockAdminSpaceRepository();
    });

    Future<void> pumpDetailPage(
      WidgetTester tester, {
      required String spaceId,
    }) async {
      await tester.pumpTestApp(
        AdminSpaceDetailPage(spaceId: spaceId, onBack: () {}),
        providers: [
          Provider<AdminSpaceRepository>.value(value: repository),
          ChangeNotifierProvider<AdminSpaceListViewModel>(
            create: (_) => AdminSpaceListViewModel(repository),
          ),
        ],
      );
      await tester.pumpAndSettle();
    }

    testWidgets('미처리 요청이 있으면 요약과 처리 CTA를 표시한다', (tester) async {
      await pumpDetailPage(tester, spaceId: 'space-001');

      expect(find.text('중앙도서관 4층 열람실'), findsOneWidget);
      expect(find.text('공개 상태'), findsOneWidget);
      expect(find.text('재조사 요청 3건'), findsOneWidget);
      expect(find.text('공간 정보'), findsOneWidget);
      expect(find.text('작업 이력'), findsOneWidget);
      expect(find.text('09:00 – 22:00 · 조용함'), findsOneWidget);
      expect(find.text('10개 · 최대 4명'), findsOneWidget);
      expect(
        find.text('학생증 태그 후 입장할 수 있어요. 취식은 제한됩니다.'),
        findsOneWidget,
      );
      expect(find.text('재조사 요청 처리하기'), findsOneWidget);
    });

    testWidgets('미처리 요청이 없으면 완료 안내를 표시하고 CTA를 숨긴다', (tester) async {
      await pumpDetailPage(tester, spaceId: 'space-002');

      expect(find.text('처리할 재조사 요청이 없어요'), findsOneWidget);
      expect(find.text('재조사 요청 처리하기'), findsNothing);
      expect(find.text('이용 규칙과 소음'), findsOneWidget);
      expect(find.text('테이블과 시설'), findsOneWidget);
    });

    testWidgets('요청 처리 화면에서 결과를 공개하면 완료 상태로 돌아온다', (tester) async {
      await pumpDetailPage(tester, spaceId: 'space-001');

      await tester.tap(find.text('재조사 요청 처리하기'));
      await tester.pumpAndSettle();

      expect(find.text('현장 확인 결과를 알려주세요'), findsOneWidget);
      expect(find.text('사용자 제보 3건'), findsOneWidget);
      expect(find.text('확인 결과 (사용자에게 공개)'), findsOneWidget);
      expect(find.text('확인 결과 공개하기'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField).last,
        '현장 확인 결과 이용 시간을 21:30까지로 수정했어요.',
      );

      await tester.tap(find.text('확인 결과 공개하기'));
      await tester.pumpAndSettle();

      expect(find.text('처리할 재조사 요청이 없어요'), findsOneWidget);
      expect(find.text('재조사 요청 3건'), findsNothing);
      final detail = await repository.fetchSpaceDetailById('space-001');
      expect(
        detail!.reinspectionResult,
        '현장 확인 결과 이용 시간을 21:30까지로 수정했어요.',
      );
    });
  });
}

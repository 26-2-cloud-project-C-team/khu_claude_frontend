import 'package:flutter/foundation.dart';
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
      debugPrint('[AD-04 TEST] Repository 초기화 완료');
    });

    Future<void> pumpDetailPage(
      WidgetTester tester, {
      required String spaceId,
    }) async {
      debugPrint('[AD-04 TEST] 상세 화면 초기화 시작: $spaceId');

      await tester.pumpTestApp(
        AdminSpaceDetailPage(spaceId: spaceId, onBack: () {}),
        providers: [
          Provider<AdminSpaceRepository>.value(value: repository),
          ChangeNotifierProvider<AdminSpaceListViewModel>(
            create: (_) => AdminSpaceListViewModel(repository),
          ),
        ],
      );

      debugPrint('[AD-04 TEST] pumpTestApp 완료');

      // 초기 상세 정보 조회
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      debugPrint('[AD-04 TEST] 상세 화면 로딩 완료');
    }

    testWidgets('미처리 요청이 있으면 요약과 처리 CTA를 표시한다', (tester) async {
      debugPrint('[AD-04 TEST 1] 테스트 시작');

      await pumpDetailPage(tester, spaceId: 'space-001');

      expect(find.text('중앙도서관 4층 열람실'), findsOneWidget);
      expect(find.text('공개 상태'), findsOneWidget);
      expect(find.text('재조사 요청 3건'), findsOneWidget);
      expect(find.text('공간 정보'), findsOneWidget);
      expect(find.text('작업 이력'), findsOneWidget);
      expect(find.text('09:00 – 22:00 · 조용함'), findsOneWidget);
      expect(find.text('10개 · 최대 4명'), findsOneWidget);
      expect(find.text('학생증 태그 후 입장할 수 있어요. 취식은 제한됩니다.'), findsOneWidget);
      expect(find.text('재조사 요청 처리하기'), findsOneWidget);

      debugPrint('[AD-04 TEST 1] 테스트 통과');
    });

    testWidgets('미처리 요청이 없으면 완료 안내를 표시하고 CTA를 숨긴다', (tester) async {
      debugPrint('[AD-04 TEST 2] 테스트 시작');

      await pumpDetailPage(tester, spaceId: 'space-002');

      expect(find.text('처리할 재조사 요청이 없어요'), findsOneWidget);
      expect(find.text('재조사 요청 처리하기'), findsNothing);
      expect(find.text('이용 규칙과 소음'), findsOneWidget);
      expect(find.text('테이블과 시설'), findsOneWidget);

      debugPrint('[AD-04 TEST 2] 테스트 통과');
    });

    testWidgets('요청 처리 화면에서 결과를 공개하면 완료 상태로 돌아온다', (tester) async {
      debugPrint('[AD-04 TEST 3] 재조사 처리 테스트 시작');

      // STEP 1. 상세 화면 진입
      await pumpDetailPage(tester, spaceId: 'space-001');

      debugPrint('[AD-04 TEST 3] STEP 1 완료: 상세 화면 로딩');

      // STEP 2. 재조사 처리 화면 진입
      final requestButton = find.text('재조사 요청 처리하기');

      expect(requestButton, findsOneWidget);

      await tester.ensureVisible(requestButton);
      await tester.pump();

      debugPrint('[AD-04 TEST 3] STEP 2-1: 처리 버튼 화면 표시');

      await tester.tap(requestButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      debugPrint('[AD-04 TEST 3] STEP 2-2: 처리 화면 진입 완료');

      expect(find.text('현장 확인 결과를 알려주세요'), findsOneWidget);
      expect(find.text('사용자 제보 3건'), findsOneWidget);
      expect(find.text('확인 결과 (사용자에게 공개)'), findsOneWidget);

      debugPrint('[AD-04 TEST 3] STEP 2 검증 완료');

      // STEP 3. 확인 결과 입력
      final resultLabel = find.text('확인 결과 (사용자에게 공개)');

      await tester.ensureVisible(resultLabel);
      await tester.pump();

      debugPrint('[AD-04 TEST 3] STEP 3-1: 결과 입력란 표시');

      final resultField = find.byType(TextField).last;

      await tester.ensureVisible(resultField);
      await tester.pump();

      await tester.enterText(resultField, '현장 확인 결과 이용 시간을 21:30까지로 수정했어요.');

      await tester.pump();

      debugPrint('[AD-04 TEST 3] STEP 3-2: 확인 결과 입력 완료');

      // STEP 4. 공개 버튼 확인
      final publishButton = find.text('확인 결과 공개하기');

      expect(publishButton, findsOneWidget);

      debugPrint('[AD-04 TEST 3] STEP 4: 공개 버튼 확인 완료');

      // STEP 5. 결과 공개
      await tester.ensureVisible(publishButton);
      await tester.pump();

      await tester.tap(publishButton);
      await tester.pump();

      debugPrint('[AD-04 TEST 3] STEP 5-1: 공개 버튼 클릭 완료');

      // MockRepository 처리: 200ms
      await tester.pump(const Duration(milliseconds: 250));

      debugPrint('[AD-04 TEST 3] STEP 5-2: 요청 처리 대기 완료');

      // 상세 정보 재조회
      await tester.pump(const Duration(milliseconds: 350));

      debugPrint('[AD-04 TEST 3] STEP 5-3: 상세 정보 재조회 대기 완료');

      // 공간 목록 재조회
      await tester.pump(const Duration(milliseconds: 350));

      debugPrint('[AD-04 TEST 3] STEP 5-4: 공간 목록 재조회 대기 완료');

      // 최종 화면 갱신
      await tester.pump();

      debugPrint('[AD-04 TEST 3] STEP 6: 최종 화면 갱신 완료');

      // STEP 7. 완료 상태 검증
      expect(find.text('처리할 재조사 요청이 없어요'), findsOneWidget);
      expect(find.text('재조사 요청 3건'), findsNothing);

      debugPrint('[AD-04 TEST 3] STEP 7: 완료 상태 검증 통과');

      // STEP 8. 저장된 결과 검증
      debugPrint('[AD-04 TEST 3] STEP 8-1: Repository 조회 시작');

      // 조회 Future 먼저 생성
      final detailFuture = repository.fetchSpaceDetailById('space-001');

      debugPrint('[AD-04 TEST 3] STEP 8-2: Repository 조회 Future 생성 완료');

      // MockRepository의 300ms 지연 처리
      await tester.pump(const Duration(milliseconds: 350));

      debugPrint('[AD-04 TEST 3] STEP 8-3: Repository 조회 대기 완료');

      // Future 결과 가져오기
      final detail = await detailFuture;

      debugPrint('[AD-04 TEST 3] STEP 8-4: Repository 조회 완료');

      // 저장 결과 검증
      expect(detail, isNotNull);

      expect(detail!.reinspectionResult, '현장 확인 결과 이용 시간을 21:30까지로 수정했어요.');

      debugPrint('[AD-04 TEST 3] STEP 8-5: 저장 결과 검증 통과');
    });
  });
}

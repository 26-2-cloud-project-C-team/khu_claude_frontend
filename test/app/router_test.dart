import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:team_frontend/app/router.dart';
import 'package:team_frontend/features/admin_spaces/data/admin_space_repository.dart';
import 'package:team_frontend/features/admin_spaces/data/mock_admin_space_repository.dart';
import 'package:team_frontend/features/admin_spaces/viewmodels/admin_space_list_view_model.dart';
import 'package:team_frontend/core/theme/app_theme.dart';

void main() {
  Future<GoRouter> pumpAt(WidgetTester tester, String location) async {
    final repository = MockAdminSpaceRepository();
    final router = createRouter(initialLocation: location);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AdminSpaceRepository>.value(value: repository),
          ChangeNotifierProvider<AdminSpaceListViewModel>(
            create: (_) => AdminSpaceListViewModel(repository)..load(),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  final screens = {
    AppRoutes.start: 'US-00 시작',
    AppRoutes.search: 'US-01·02 검색 조건',
    AppRoutes.buildingSelect: 'US-03 출발 건물 선택',
    AppRoutes.candidates: 'US-04 후보 상세',
    AppRoutes.noResult: 'US-05 결과 없음',
    AppRoutes.directions: 'US-06 길찾기·이용 중',
    AppRoutes.review: 'US-07 이용 의견',
    AppRoutes.reinspection: 'US-07 재조사 요청',
    AppRoutes.done: 'US-08 완료',
  };

  for (final MapEntry(key: location, value: screen) in screens.entries) {
    testWidgets('$location 경로가 $screen 화면을 연다', (tester) async {
      await pumpAt(tester, location);
      expect(find.text(screen), findsOneWidget);
    });
  }

  testWidgets('/admin은 공간 목록으로 보낸다', (tester) async {
    final router = await pumpAt(tester, AppRoutes.admin);

    expect(router.state.uri.path, AppRoutes.adminSpaces);
    expect(find.text('공간 관리'), findsOneWidget);
  });

  testWidgets('공간 상세에서 뒤로 가면 공간 목록이 나온다', (tester) async {
    final router = await pumpAt(tester, AppRoutes.adminSpace('space-001'));

    expect(find.text('공간 상세'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('공간 관리'), findsOneWidget);
  });

  testWidgets('AD-04 정보 행에서 AD-05 해당 섹션 수정 화면을 연다', (tester) async {
    final router = await pumpAt(
      tester,
      AppRoutes.adminSpace('space-001'),
    );

    await tester.tap(find.text('이용 규칙과 소음'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/admin/spaces/space-001/edit');
    expect(router.state.uri.queryParameters['section'], 'rules');
    expect(find.text('부분 수정'), findsOneWidget);
    expect(find.text('이용 규칙과 소음을 고쳐주세요'), findsOneWidget);
    expect(find.text('24시간 이용'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:team_frontend/app/router.dart';

void main() {
  Future<GoRouter> pumpAt(WidgetTester tester, String location) async {
    final router = createRouter(initialLocation: location);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
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
    AppRoutes.adminLogin: 'AD-01 로그인',
    AppRoutes.adminSpaces: 'AD-02 공간 목록',
    AppRoutes.adminSpaceNew: 'AD-03 공간 등록',
    AppRoutes.adminSpace('7'): 'AD-04 공간 상세·재조사 처리 (7)',
    AppRoutes.adminSpaceEdit('7'): 'AD-03 공간 수정 (7)',
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
    expect(find.text('AD-02 공간 목록'), findsOneWidget);
  });

  testWidgets('공간 상세에서 뒤로 가면 공간 목록이 나온다', (tester) async {
    final router = await pumpAt(tester, AppRoutes.adminSpace('7'));

    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('AD-02 공간 목록'), findsOneWidget);
  });
}

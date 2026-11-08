import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:team_frontend/app/router.dart';
import 'package:team_frontend/core/location/location_repository.dart';
import 'package:team_frontend/features/directions/data/directions_repository.dart';
import 'package:team_frontend/features/feedback/data/feedback_repository.dart';
import 'package:team_frontend/features/search/data/search_repository.dart';

import '../fakes/fake_directions_repository.dart';
import '../fakes/fake_feedback_repository.dart';
import '../fakes/fake_location_repository.dart';
import '../fakes/fake_search_repository.dart';
import '../fakes/sample_space.dart';

void main() {
  Future<GoRouter> pumpAt(
    WidgetTester tester,
    String location, {
    FakeSearchRepository? search,
  }) async {
    final router = createRouter(initialLocation: location);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SearchRepository>.value(
            value: search ?? FakeSearchRepository(buildings: const [engineering, centralLibrary]),
          ),
          Provider<LocationRepository>.value(
            value: FakeLocationRepository(permission: LocationPermissionStatus.denied),
          ),
          Provider<DirectionsRepository>.value(value: FakeDirectionsRepository()),
          Provider<FeedbackRepository>.value(value: FakeFeedbackRepository()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  group('사용자 화면', () {
    testWidgets('/ 경로가 US-00 시작 화면을 연다', (tester) async {
      await pumpAt(tester, AppRoutes.start);

      expect(find.text('어떤 공간을 찾아 드릴까요?'), findsOneWidget);
    });

    testWidgets('목적 타일을 누르면 검색 조건으로 가고, 위치가 없으면 US-03을 연다', (tester) async {
      final router = await pumpAt(tester, AppRoutes.start);

      await tester.tap(find.text('개인 작업'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, AppRoutes.buildingSelect);
      expect(find.text('어느 건물에서 출발하시나요?'), findsOneWidget);
    });

    // 검색 조건 · 결과 · 고른 공간은 메모리에만 있으므로 새로고침하면 US-00부터 다시 시작한다.
    for (final location in [
      AppRoutes.search,
      AppRoutes.buildingSelect,
      AppRoutes.candidates,
      AppRoutes.noResult,
      AppRoutes.directions,
      AppRoutes.review,
      AppRoutes.reinspection,
    ]) {
      testWidgets('$location는 값 없이 열면 US-00으로 보낸다', (tester) async {
        final router = await pumpAt(tester, location);

        expect(router.state.uri.path, AppRoutes.start);
      });
    }

    testWidgets('/spaces/{spaceId}는 공간 하나를 복구 상태(US-04 ③)로 연다', (tester) async {
      await pumpAt(tester, AppRoutes.restoreSpace('7'));

      expect(find.text('공간 7'), findsOneWidget);
      expect(find.text('검색 조건이 사라져서 공간 정보만 보여 드려요'), findsOneWidget);
    });

    testWidgets('볼 수 없는 공간이면 US-00으로 보내며 토스트를 띄운다', (tester) async {
      final router = await pumpAt(
        tester,
        AppRoutes.restoreSpace('7'),
        search: FakeSearchRepository(missingIds: {'7'}),
      );

      expect(router.state.uri.path, AppRoutes.start);
      expect(find.text('지금은 볼 수 없는 공간이에요'), findsOneWidget);
    });

    testWidgets('/done은 US-08 완료 화면을 연다', (tester) async {
      await pumpAt(tester, '${AppRoutes.done}?kind=reinspection');

      expect(find.text('요청을 보냈어요'), findsOneWidget);
    });
  });

  final adminScreens = {
    AppRoutes.adminLogin: 'AD-01 로그인',
    AppRoutes.adminSpaces: 'AD-02 공간 목록',
    AppRoutes.adminSpaceNew: 'AD-03 공간 등록',
    AppRoutes.adminSpace('7'): 'AD-04 공간 상세·재조사 처리 (7)',
    AppRoutes.adminSpaceEdit('7'): 'AD-03 공간 수정 (7)',
  };

  for (final MapEntry(key: location, value: screen) in adminScreens.entries) {
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

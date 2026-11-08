import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/admin_auth/views/admin_login_page.dart';
import '../features/admin_spaces/views/admin_space_list_page.dart';
import '../features/admin_spaces/views/admin_space_create_page.dart';

abstract final class AppRoutes {
  static const start = '/';
  static const search = '/search';
  static const buildingSelect = '/search/building';
  static const candidates = '/search/candidates';
  static const noResult = '/search/no-result';
  static const directions = '/directions';
  static const review = '/directions/review';
  static const reinspection = '/directions/reinspection';
  static const done = '/done';

  static const admin = '/admin';
  static const adminLogin = '/admin/login';
  static const adminSpaces = '/admin/spaces';
  static const adminSpaceNew = '/admin/spaces/new';
  static String adminSpace(String spaceId) => '/admin/spaces/$spaceId';
  static String adminSpaceEdit(String spaceId) => '/admin/spaces/$spaceId/edit';
}

GoRouter createRouter({String initialLocation = AppRoutes.start}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      // 검색 조건을 US-00부터 공유해야 하므로 사용자 화면을 한 ShellRoute로 묶는다.
      // SearchFlowViewModel은 이 builder에서 child를 감싸 제공한다.
      ShellRoute(
        builder: (_, _, child) => child,
        routes: [
          _placeholder(AppRoutes.start, 'US-00 시작'),
          _placeholder(AppRoutes.search, 'US-01·02 검색 조건'),
          _placeholder(AppRoutes.buildingSelect, 'US-03 출발 건물 선택'),
          _placeholder(AppRoutes.candidates, 'US-04 후보 상세'),
          _placeholder(AppRoutes.noResult, 'US-05 결과 없음'),
          _placeholder(AppRoutes.directions, 'US-06 길찾기·이용 중'),
          _placeholder(AppRoutes.review, 'US-07 이용 의견'),
          _placeholder(AppRoutes.reinspection, 'US-07 재조사 요청'),
          _placeholder(AppRoutes.done, 'US-08 완료'),
        ],
      ),
      GoRoute(
        path: AppRoutes.admin,
        // 하위 경로 전체에 적용되므로 관리자 로그인 가드는 이 redirect에 추가한다.
        redirect: (_, state) =>
            state.uri.path == AppRoutes.admin ? AppRoutes.adminSpaces : null,
        routes: [
          GoRoute(
            path: 'login',
            builder: (_, state) => AdminLoginPage(
              accessDenied: state.uri.queryParameters['state'] == 'denied',
              email:
                  state.uri.queryParameters['email'] ?? 'wkdwowns2@khu.ac.kr',
            ),
          ),
          GoRoute(
            path: 'spaces',
            builder: (context, state) => AdminSpaceListPage(
              onCreate: () {
                context.push(AppRoutes.adminSpaceNew);
              },
              onOpenSpace: (spaceId) {
                context.push(AppRoutes.adminSpace(spaceId));
              },
              onLogout: () {
                context.go(AppRoutes.adminLogin);
              },
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) =>
                    AdminSpaceCreatePage(onBack: () => context.pop()),
              ),
              _placeholder(
                ':spaceId',
                'AD-04 공간 상세·재조사 처리',
                routes: [_placeholder('edit', 'AD-03 공간 수정')],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

GoRoute _placeholder(
  String path,
  String screen, {
  List<RouteBase> routes = const [],
}) {
  return GoRoute(
    path: path,
    builder: (_, state) => _PlaceholderPage(
      screen: screen,
      spaceId: state.pathParameters['spaceId'],
    ),
    routes: routes,
  );
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.screen, this.spaceId});

  final String screen;
  final String? spaceId;

  @override
  Widget build(BuildContext context) {
    final spaceId = this.spaceId;
    return Scaffold(
      body: Center(
        child: Text(spaceId == null ? screen : '$screen ($spaceId)'),
      ),
    );
  }
}

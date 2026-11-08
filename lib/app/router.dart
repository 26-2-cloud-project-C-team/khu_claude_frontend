import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'user_routes.dart';

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

  /// 공유 링크 · 새로고침 복구(US-04 ③). `/spaces/{spaceId}`
  static const restore = '/spaces';
  static String restoreSpace(String spaceId) => '$restore/$spaceId';

  static const admin = '/admin';
  static const adminLogin = '/admin/login';
  static const adminSpaces = '/admin/spaces';
  static const adminSpaceNew = '/admin/spaces/new';
  static String adminSpace(String spaceId) => '/admin/spaces/$spaceId';
  static String adminSpaceEdit(String spaceId) => '/admin/spaces/$spaceId/edit';
}

GoRouter createRouter({String initialLocation = AppRoutes.start}) {
  final flow = SearchFlowHolder();

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      // 검색 조건을 US-00부터 공유해야 하므로 사용자 화면을 한 ShellRoute로 묶는다.
      // SearchFlowViewModel은 이 builder에서 child를 감싸 제공한다.
      ShellRoute(
        builder: (context, _, child) {
          flow.ensure(context);
          return child;
        },
        routes: userRoutes(flow),
      ),
      GoRoute(
        path: AppRoutes.admin,
        // 하위 경로 전체에 적용되므로 관리자 로그인 가드는 이 redirect에 추가한다.
        redirect: (_, state) =>
            state.uri.path == AppRoutes.admin ? AppRoutes.adminSpaces : null,
        routes: [
          _placeholder('login', 'AD-01 로그인'),
          _placeholder(
            'spaces',
            'AD-02 공간 목록',
            routes: [
              _placeholder('new', 'AD-03 공간 등록'),
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

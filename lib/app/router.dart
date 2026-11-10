import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/admin_auth/viewmodels/admin_auth_view_model.dart';
import '../features/admin_auth/views/admin_login_page.dart';
import '../features/admin_spaces/views/admin_space_list_page.dart';
import '../features/admin_spaces/views/admin_space_create_page.dart';
import '../features/admin_spaces/views/admin_space_detail_page.dart';
import '../features/admin_spaces/views/admin_space_edit_page.dart';
import '../features/admin_spaces/models/admin_space_edit_section.dart';

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

GoRouter createRouter({
  String initialLocation = AppRoutes.start,
  AdminAuthViewModel? adminAuth,
}) {
  final flow = SearchFlowHolder();

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: adminAuth,
    redirect: adminAuth == null
        ? null
        : (context, state) {
            final path = state.uri.path;
            if (!path.startsWith('/admin')) return null;

            final isLoginRoute = path == AppRoutes.adminLogin;
            // 세션 확인 중에는 관리자 보호 화면을 잠시도 노출하지 않는다.
            if (adminAuth.isCheckingSession) {
              return isLoginRoute ? null : AppRoutes.adminLogin;
            }

            if (adminAuth.isAuthenticated && isLoginRoute) {
              return AppRoutes.adminSpaces;
            }
            if (!adminAuth.isAuthenticated && !isLoginRoute) {
              return AppRoutes.adminLogin;
            }
            return null;
          },
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
              onLogout: () async {
                await context.read<AdminAuthViewModel>().signOut();
                if (context.mounted) context.go(AppRoutes.adminLogin);
              },
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) =>
                    AdminSpaceCreatePage(onBack: () => context.pop()),
              ),
              GoRoute(
                path: ':spaceId',
                builder: (context, state) => AdminSpaceDetailPage(
                  spaceId: state.pathParameters['spaceId']!,
                  onBack: () => context.pop(),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => AdminSpaceEditPage(
                      spaceId: state.pathParameters['spaceId']!,
                      section: AdminSpaceEditSection.fromName(
                        state.uri.queryParameters['section'],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

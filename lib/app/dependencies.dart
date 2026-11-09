import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../core/map/app_map.dart';
import '../core/map/kakao_map.dart';
import '../core/network/api_client.dart';

import '../features/admin_auth/data/admin_auth_repository.dart';
import '../features/admin_auth/data/api_admin_auth_repository.dart';
import '../features/admin_auth/viewmodels/admin_auth_view_model.dart';
import '../features/admin_spaces/data/admin_space_repository.dart';
import '../features/admin_spaces/data/api_admin_space_repository.dart';
import '../features/admin_spaces/viewmodels/admin_space_list_view_model.dart';

/// 앱 전체에 제공할 의존성. Repository 구현체는 이 목록에 추가한다.
List<SingleChildWidget> createDependencies() => [
  Provider<ApiClient>(
    create: (_) => ApiClient(),
    dispose: (_, client) => client.dispose(),
  ),

  Provider<AdminAuthRepository>(
    create: (context) => ApiAdminAuthRepository(context.read<ApiClient>()),
  ),

  ChangeNotifierProvider<AdminAuthViewModel>(
    create: (context) => AdminAuthViewModel(
      repository: context.read<AdminAuthRepository>(),
      apiClient: context.read<ApiClient>(),
    )..restoreSession(),
  ),

  Provider<MapViewFactory>.value(value: const KakaoMapViewFactory()),

  Provider<AdminSpaceRepository>(
    create: (context) => ApiAdminSpaceRepository(context.read<ApiClient>()),
  ),

  ChangeNotifierProvider<AdminSpaceListViewModel>(
    create: (context) => AdminSpaceListViewModel(
      context.read<AdminSpaceRepository>(),
    ),
  ),
];

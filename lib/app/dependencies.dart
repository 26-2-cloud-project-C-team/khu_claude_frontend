import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../core/location/browser_location_repository.dart';
import '../core/location/location_repository.dart';
import '../core/map/app_map.dart';
import '../core/map/kakao_map.dart';
import '../core/network/api_client.dart';
import '../features/directions/data/directions_repository.dart';
import '../features/directions/data/directions_repository_impl.dart';
import '../features/feedback/data/feedback_repository.dart';
import '../features/feedback/data/feedback_repository_impl.dart';
import '../features/search/data/search_repository.dart';
import '../features/search/data/search_repository_impl.dart';

/// 앱 전체에 제공할 의존성. Repository 구현체는 이 목록에 추가한다.
List<SingleChildWidget> createDependencies() => [
  Provider<ApiClient>(
    create: (_) => ApiClient(),
    dispose: (_, client) => client.dispose(),
  ),
  Provider<MapViewFactory>.value(value: const KakaoMapViewFactory()),
  // 사용자 화면(US-00~08)
  Provider<LocationRepository>(create: (_) => createBrowserLocationRepository()),
  Provider<SearchRepository>(
    create: (context) => SearchRepositoryImpl(context.read<ApiClient>()),
  ),
  Provider<DirectionsRepository>(
    create: (context) => DirectionsRepositoryImpl(context.read<ApiClient>()),
  ),
  Provider<FeedbackRepository>(
    create: (context) => FeedbackRepositoryImpl(context.read<ApiClient>()),
  ),
];

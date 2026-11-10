import 'browser_location_stub.dart'
    if (dart.library.js_interop) 'browser_location_web.dart';
import 'location_repository.dart';

/// 브라우저 위치 API로 구현한 [LocationRepository]. 웹이 아니면 항상 권한 없음으로 답한다.
LocationRepository createBrowserLocationRepository() => BrowserLocationRepository();

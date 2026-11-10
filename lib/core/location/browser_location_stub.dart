import 'location_repository.dart';

/// 웹이 아닌 환경(테스트 VM 등)용. 위치를 쓸 수 없다.
class BrowserLocationRepository implements LocationRepository {
  @override
  Future<LocationPermissionStatus> requestPermission() async => LocationPermissionStatus.denied;

  @override
  Future<LocationFix?> currentFix() async => null;

  @override
  Stream<LocationFix> watch({Duration interval = const Duration(seconds: 10)}) =>
      const Stream.empty();
}

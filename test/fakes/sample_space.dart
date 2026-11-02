import 'package:team_frontend/core/models/building.dart';
import 'package:team_frontend/core/models/noise.dart';
import 'package:team_frontend/core/utils/geo.dart';
import 'package:team_frontend/features/search/models/candidate.dart';

const engineering = Building(id: 1, name: '공학관', lat: 37.2465, lng: 127.0802);
const centralLibrary = Building(id: 2, name: '중앙도서관(대학본부)', lat: 37.2410, lng: 127.0800);
const lifeScience = Building(id: 3, name: '생명과학대학관', lat: 37.2430, lng: 127.0820);

CandidateDetail sampleCandidate(
  int id, {
  GeoPoint buildingLocation = const GeoPoint(37.2410, 127.0800),
  int tableCount = 10,
  int chargeableTableCount = 8,
  double distanceMeters = 400,
}) {
  return CandidateDetail(
    spaceId: id,
    name: '공간 $id',
    buildingName: '중앙도서관(대학본부)',
    buildingLocation: buildingLocation,
    floor: '4층',
    locationGuide: '엘리베이터에서 내려 왼쪽 끝',
    photos: const [],
    distanceMeters: distanceMeters,
    availableNow: true,
    opensAt: '09:00',
    closesAt: '22:00',
    ratingAverage: 4.6,
    ratingCount: 32,
    tableCount: tableCount,
    maxPerTable: 8,
    chargeableTableCount: chargeableTableCount,
    freeWifi: true,
    noise: Noise.quiet,
    isCafe: false,
  );
}

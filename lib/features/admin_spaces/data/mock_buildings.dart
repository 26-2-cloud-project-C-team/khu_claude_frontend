import '../../../core/models/building.dart';

/// AD-03 위치 선택 화면 확인용 임시 건물 데이터.
/// 실제 건물 ID, 좌표, 층 범위는 백엔드 데이터로 교체해야 한다.
const mockBuildings = <Building>[
  Building(
    id: 'mock-building-001',
    name: '중앙도서관(대학본부)',
    lat: 0,
    lng: 0,
    floorRange: FloorRange(min: 1, max: 5),
  ),
  Building(
    id: 'mock-building-002',
    name: '공학관',
    lat: 0,
    lng: 0,
    floorRange: FloorRange(min: 1, max: 6),
  ),
  Building(
    id: 'mock-building-003',
    name: '국제·경영대학관',
    lat: 0,
    lng: 0,
    floorRange: FloorRange(min: 1, max: 5),
  ),
  Building(
    id: 'mock-building-004',
    name: '전자정보대학관',
    lat: 0,
    lng: 0,
    floorRange: FloorRange(min: 1, max: 5),
  ),
  Building(
    id: 'mock-building-005',
    name: '글로벌관',
    lat: 0,
    lng: 0,
    floorRange: FloorRange(min: 1, max: 5),
  ),
  Building(
    id: 'mock-building-006',
    name: '생명과학대학관',
    lat: 0,
    lng: 0,
    floorRange: FloorRange(min: -1, max: 5),
  ),
];

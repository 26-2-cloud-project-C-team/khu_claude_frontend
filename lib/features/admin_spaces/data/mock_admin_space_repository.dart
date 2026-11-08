import '../models/admin_space.dart';
import 'admin_space_repository.dart';

class MockAdminSpaceRepository implements AdminSpaceRepository {
  final List<AdminSpace> _spaces = [
    AdminSpace(
      id: 'space-001',
      name: '중앙도서관 4층 열람실',
      location: '중앙도서관 · 4층',
      updatedAt: DateTime(2026, 10, 12),
      isPublic: true,
      reinspectionRequestCount: 3,
    ),
    AdminSpace(
      id: 'space-002',
      name: '공학관 2층 라운지',
      location: '공학관 · 2층',
      updatedAt: DateTime(2026, 10, 9),
      isPublic: true,
    ),
    AdminSpace(
      id: 'space-003',
      name: '공학관 4층 세미나실',
      location: '공학관 · 4층',
      updatedAt: DateTime(2026, 10, 8),
      isPublic: true,
      reinspectionRequestCount: 1,
    ),
    AdminSpace(
      id: 'space-004',
      name: '전자정보대학 3층 스터디룸 B',
      location: '전자정보대학 · 3층',
      updatedAt: DateTime(2026, 10, 3),
      isPublic: true,
    ),
    AdminSpace(
      id: 'space-005',
      name: '글로벌관 인터내셔널 카페',
      location: '글로벌관 · 1층',
      updatedAt: DateTime(2026, 9, 30),
      isPublic: false,
    ),
    AdminSpace(
      id: 'space-006',
      name: '생명과학대학 2층 세미나실',
      location: '생명과학대학 · 2층',
      updatedAt: DateTime(2026, 9, 28),
      isPublic: false,
    ),
  ];

  @override
  Future<List<AdminSpace>> fetchSpaces() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return List.unmodifiable(_spaces);
  }

  @override
  Future<void> addSpace(AdminSpace space) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    _spaces.add(space);
  }
}

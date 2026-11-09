import '../../../core/models/building.dart';
import '../../../core/models/reinspection_category.dart';
import '../models/admin_space.dart';
import '../models/admin_space_activity.dart';
import '../models/admin_space_detail.dart';
import '../models/reinspection_request.dart';
import 'admin_space_repository.dart';
import 'mock_buildings.dart';

class MockAdminSpaceRepository implements AdminSpaceRepository {
  MockAdminSpaceRepository() {
    for (final space in _spaces) {
      _details[space.id] = _createDetail(space);
    }
  }

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

  final Map<String, AdminSpaceDetail> _details = {};

  @override
  Future<List<Building>> fetchBuildings() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return mockBuildings;
  }

  // 공간 목록 조회
  @override
  Future<List<AdminSpace>> fetchSpaces() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_spaces);
  }

  // 공간 기본 정보 조회
  @override
  Future<AdminSpace?> fetchSpaceById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    try {
      return _spaces.firstWhere((space) => space.id == id);
    } catch (_) {
      return null;
    }
  }

  // 공간 상세 정보 조회
  @override
  Future<AdminSpaceDetail?> fetchSpaceDetailById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _details[id];
  }

  // 공간 등록
  @override
  Future<void> addSpace(
    AdminSpace space, {
    AdminSpaceDetail? detail,
    required String surveyorEmail,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    _spaces.add(space);
    _details[space.id] = detail ?? _createDetail(space);
  }

  // 공개 상태 변경: 공개 토글은 작업 이력만 남기고 최근 수정일은 바꾸지 않는다.
  @override
  Future<void> updateVisibility(String id, bool isPublic) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final index = _spaces.indexWhere((space) => space.id == id);
    if (index == -1) {
      throw StateError('공간을 찾을 수 없습니다.');
    }

    final oldSpace = _spaces[index];
    if (oldSpace.isPublic == isPublic) return;

    final updatedSpace = oldSpace.copyWith(isPublic: isPublic);
    _spaces[index] = updatedSpace;

    final detail = _details[id] ?? _createDetail(oldSpace);
    _details[id] = detail.copyWith(
      space: updatedSpace,
      activities: [
        ...detail.activities,
        AdminSpaceActivity(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: '공개 상태 변경',
          description: isPublic ? '공개 상태로 변경했습니다.' : '비공개 상태로 변경했습니다.',
          createdAt: DateTime.now(),
        ),
      ],
    );
  }

  // AD-05 섹션 수정 결과를 저장한다.
  @override
  Future<void> updateSpaceDetail(
    String id,
    AdminSpaceDetail detail, {
    required String sectionLabel,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final index = _spaces.indexWhere((space) => space.id == id);
    if (index == -1) {
      throw StateError('공간을 찾을 수 없습니다.');
    }

    final now = DateTime.now();
    final updatedSpace = detail.space.copyWith(updatedAt: now);
    final oldDetail = _details[id] ?? _createDetail(_spaces[index]);

    _spaces[index] = updatedSpace;
    _details[id] = detail.copyWith(
      space: updatedSpace,
      reinspectionRequests: oldDetail.reinspectionRequests,
      reinspectionResult: oldDetail.reinspectionResult,
      activities: [
        ...oldDetail.activities,
        AdminSpaceActivity(
          id: 'activity-${now.microsecondsSinceEpoch}',
          title: '최근 수정',
          description: '$sectionLabel 정보가 수정되었습니다.',
          createdAt: now,
          actor: '관리자',
        ),
      ],
    );
  }

  // 화면의 CTA 한 번으로 현재 접수된 요청을 모두 처리하고 결과 이력은 한 건만 남긴다.
  @override
  Future<void> resolveAllReinspections(
    String spaceId, {
    required String result,
    bool makePrivate = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final detail = _details[spaceId];
    if (detail == null) {
      throw StateError('공간 상세 정보를 찾을 수 없습니다.');
    }

    final now = DateTime.now();
    final pendingCount = detail.reinspectionRequests
        .where((request) => !request.isResolved)
        .length;
    if (pendingCount == 0) return;

    final updatedRequests = detail.reinspectionRequests
        .map(
          (request) => request.isResolved
              ? request
              : ReinspectionRequest(
                  id: request.id,
                  message: request.message,
                  requestedAt: request.requestedAt,
                  categories: request.categories,
                  isResolved: true,
                  resolvedAt: now,
                ),
        )
        .toList(growable: false);
    final updatedSpace = detail.space.copyWith(
      updatedAt: now,
      reinspectionRequestCount: 0,
      isPublic: makePrivate ? false : detail.space.isPublic,
    );

    final spaceIndex = _spaces.indexWhere((space) => space.id == spaceId);
    if (spaceIndex != -1) _spaces[spaceIndex] = updatedSpace;

    _details[spaceId] = detail.copyWith(
      space: updatedSpace,
      reinspectionRequests: updatedRequests,
      reinspectionResult: result.trim(),
      lastResolvedAt: now,
      activities: [
        ...detail.activities,
        AdminSpaceActivity(
          id: 'activity-${now.microsecondsSinceEpoch}',
          title: '최근 수정',
          description: '재조사 처리 결과: ${result.trim()}',
          createdAt: now,
          actor: '관리자',
        ),
      ],
    );
  }

  // 테스트용 상세 데이터 생성
  AdminSpaceDetail _createDetail(AdminSpace space) {
    final requests = space.id == 'space-001'
        ? [
            ReinspectionRequest(
              id: 'request-001',
              message: '22시 전에 문을 닫아요.',
              requestedAt: DateTime(2026, 10, 15),
              category: ReinspectionCategory.timeMood,
            ),
            ReinspectionRequest(
              id: 'request-002',
              message: '충전되는 자리가 기존 정보보다 적어요.',
              requestedAt: DateTime(2026, 10, 16),
              category: ReinspectionCategory.tableFacility,
            ),
            ReinspectionRequest(
              id: 'request-003',
              message: '내용 없이 항목만 골랐어요.',
              requestedAt: DateTime(2026, 10, 17),
              category: ReinspectionCategory.timeMood,
            ),
          ]
        : space.id == 'space-003'
        ? [
            ReinspectionRequest(
              id: 'request-004',
              message: '이용 가능한 인원이 달라졌어요.',
              requestedAt: DateTime(2026, 10, 18),
              category: ReinspectionCategory.tableFacility,
            ),
          ]
        : <ReinspectionRequest>[];

    return AdminSpaceDetail(
      space: space,
      photos: const [],
      purpose: '개인 작업',
      isCafe: false,
      canTalk: false,
      is24Hours: false,
      startMinute: 9 * 60,
      endMinute: 22 * 60,
      noiseLevel: '조용함',
      tableCount: 10,
      maxPeoplePerTable: 4,
      chargingTableCount: 8,
      hasFreeWifi: true,
      goodPoints: '조용하고 쾌적한 학습 환경',
      badPoints: '시험 기간에는 좌석이 부족할 수 있음',
      memo: '학생증 태그 후 입장할 수 있어요. 취식은 제한됩니다.',
      surveyor: '관리자',
      reinspectionRequests: requests,
      activities: [
        AdminSpaceActivity(
          id: 'activity-${space.id}',
          title: '최초 조사',
          description: '공간 정보가 등록되었습니다.',
          createdAt: space.updatedAt,
          actor: '관리자',
        ),
      ],
    );
  }
}

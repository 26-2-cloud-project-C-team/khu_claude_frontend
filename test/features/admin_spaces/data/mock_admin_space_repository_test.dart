import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/features/admin_spaces/data/mock_admin_space_repository.dart';

void main() {
  group('MockAdminSpaceRepository', () {
    late MockAdminSpaceRepository repository;

    setUp(() {
      repository = MockAdminSpaceRepository();
    });

    test('공개 상태 변경은 최근 수정일을 바꾸지 않고 작업 이력에 남긴다', () async {
      final before = await repository.fetchSpaceDetailById('space-002');
      final beforeUpdatedAt = before!.space.updatedAt;

      await repository.updateVisibility('space-002', false);

      final after = await repository.fetchSpaceDetailById('space-002');
      expect(after!.space.isPublic, isFalse);
      expect(after.space.updatedAt, beforeUpdatedAt);
      expect(after.activities.last.title, '공개 상태 변경');
    });

    test('재조사 요청은 결과와 함께 공간 단위로 한 번에 처리한다', () async {
      final before = await repository.fetchSpaceDetailById('space-001');
      final beforeCount = before!.reinspectionRequests
          .where((request) => !request.isResolved)
          .length;

      await repository.resolveAllReinspections(
        'space-001',
        result: '현장 확인 결과 이용 시간을 21:30까지로 수정했어요.',
      );

      final after = await repository.fetchSpaceDetailById('space-001');
      expect(
        after!.reinspectionRequests.every((request) => request.isResolved),
        isTrue,
      );
      expect(after.space.reinspectionRequestCount, 0);
      expect(after.space.updatedAt.isAfter(before.space.updatedAt), isTrue);
      expect(after.activities.length, before.activities.length + 1);
      expect(after.activities.last.title, '최근 수정');
      expect(after.reinspectionResult,
          '현장 확인 결과 이용 시간을 21:30까지로 수정했어요.');
      expect(beforeCount, 3);
    });

    test('부분 수정은 해당 상세 정보와 최근 수정 작업 이력을 저장한다', () async {
      final before = await repository.fetchSpaceDetailById('space-001');
      final requestCount = before!.reinspectionRequests.length;
      final updatedDetail = before.copyWith(
        purpose: '팀 프로젝트 · 회의',
        tableCount: 12,
      );

      await repository.updateSpaceDetail(
        'space-001',
        updatedDetail,
        sectionLabel: '테이블과 시설',
      );

      final after = await repository.fetchSpaceDetailById('space-001');
      expect(after!.purpose, '팀 프로젝트 · 회의');
      expect(after.tableCount, 12);
      expect(after.reinspectionRequests.length, requestCount);
      expect(after.space.updatedAt.isAfter(before.space.updatedAt), isTrue);
      expect(after.activities.last.title, '최근 수정');
      expect(after.activities.last.description, '테이블과 시설 정보가 수정되었습니다.');
    });
  });
}

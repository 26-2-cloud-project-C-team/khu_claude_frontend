import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/errors/app_exception.dart';
import 'package:team_frontend/core/models/reinspection_category.dart';
import 'package:team_frontend/features/admin_spaces/data/admin_space_repository.dart';
import 'package:team_frontend/features/admin_spaces/models/admin_space.dart';
import 'package:team_frontend/features/admin_spaces/models/admin_space_detail.dart';
import 'package:team_frontend/features/admin_spaces/models/reinspection_request.dart';
import 'package:team_frontend/features/admin_spaces/viewmodels/admin_space_detail_view_model.dart';

AdminSpaceDetail _detail({required bool pending}) => AdminSpaceDetail(
  space: AdminSpace(
    id: 's1',
    name: '세미나실',
    location: '국제학관 · 3층',
    updatedAt: DateTime.utc(2026, 11, 25),
    isPublic: true,
  ),
  photos: const [],
  purpose: '팀 프로젝트 · 회의',
  isCafe: false,
  canTalk: true,
  is24Hours: true,
  startMinute: 0,
  endMinute: 1440,
  noiseLevel: '보통',
  tableCount: 2,
  maxPeoplePerTable: 10,
  chargingTableCount: 2,
  hasFreeWifi: true,
  goodPoints: 'a',
  badPoints: 'b',
  memo: 'c',
  surveyor: '관리자',
  reinspectionRequests: [
    ReinspectionRequest(
      id: 'r1',
      message: '',
      requestedAt: DateTime.utc(2026, 11, 25),
      category: ReinspectionCategory.etc,
      isResolved: !pending,
    ),
  ],
);

/// 이 테스트가 쓰는 메서드만 구현한다. 나머지 호출은 테스트 실패로 드러난다.
class _FakeRepository implements AdminSpaceRepository {
  AdminSpaceDetail detail = _detail(pending: true);
  Object? resolveError;
  int fetchCount = 0;

  @override
  Future<AdminSpaceDetail?> fetchSpaceDetailById(String id) async {
    fetchCount++;
    return detail;
  }

  @override
  Future<void> resolveAllReinspections(
    String spaceId, {
    required String result,
    bool makePrivate = false,
  }) async {
    final error = resolveError;
    if (error != null) throw error;
    detail = _detail(pending: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeRepository repository;
  late AdminSpaceDetailViewModel viewModel;

  setUp(() async {
    repository = _FakeRepository();
    viewModel = AdminSpaceDetailViewModel(repository: repository, spaceId: 's1');
    await viewModel.load();
  });

  test('처리하면 success를 돌려주고 대기 요청이 없는 상세로 갱신한다', () async {
    final result = await viewModel.resolveAllReinspections(result: '확인했어요');

    expect(result, ReinspectionResolveResult.success);
    expect(viewModel.detail!.reinspectionRequests.every((r) => r.isResolved), isTrue);
  });

  test('다른 관리자가 먼저 처리해 409가 오면 conflict를 돌려주고 다시 불러온다', () async {
    repository.resolveError = const AppException(statusCode: 409);
    repository.detail = _detail(pending: false);
    final fetchesBefore = repository.fetchCount;

    final result = await viewModel.resolveAllReinspections(result: '나중 결과');

    expect(result, ReinspectionResolveResult.conflict);
    expect(repository.fetchCount, fetchesBefore + 1);
    expect(viewModel.detail!.reinspectionRequests.every((r) => r.isResolved), isTrue);
    expect(viewModel.errorMessage, isNull);
  });

  test('그 밖의 오류는 failure와 오류 문구를 남긴다', () async {
    repository.resolveError = const AppException(statusCode: 500);

    final result = await viewModel.resolveAllReinspections(result: '결과');

    expect(result, ReinspectionResolveResult.failure);
    expect(viewModel.errorMessage, isNotNull);
  });
}

import '../../../core/models/building.dart';
import '../models/admin_space.dart';
import '../models/admin_space_detail.dart';

abstract class AdminSpaceRepository {
  // 건물 목록(공간 등록 위치 선택)
  Future<List<Building>> fetchBuildings();

  // 공간 목록
  Future<List<AdminSpace>> fetchSpaces();

  // 공간 기본 정보
  Future<AdminSpace?> fetchSpaceById(String id);

  // 공간 상세 정보
  Future<AdminSpaceDetail?> fetchSpaceDetailById(String id);

  // 공간 등록
  Future<void> addSpace(
    AdminSpace space, {
    AdminSpaceDetail? detail,
    required String surveyorEmail,
  });

  // 공개 상태 변경
  Future<void> updateVisibility(String id, bool isPublic);

  // AD-05에서 선택한 섹션의 수정 결과 저장
  Future<void> updateSpaceDetail(
    String id,
    AdminSpaceDetail detail, {
    required String sectionLabel,
  });

  // 재조사 요청 일괄 처리
  Future<void> resolveAllReinspections(
    String spaceId, {
    required String result,
    bool makePrivate = false,
  });
}

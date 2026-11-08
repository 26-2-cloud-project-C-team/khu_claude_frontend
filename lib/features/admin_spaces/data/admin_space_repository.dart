import '../models/admin_space.dart';
import '../models/admin_space_detail.dart';

abstract class AdminSpaceRepository {
  // 공간 목록
  Future<List<AdminSpace>> fetchSpaces();

  // 공간 기본 정보
  Future<AdminSpace?> fetchSpaceById(String id);

  // 공간 상세 정보
  Future<AdminSpaceDetail?> fetchSpaceDetailById(String id);

  // 공간 등록
  Future<void> addSpace(AdminSpace space, {AdminSpaceDetail? detail});

  // 공개 상태 변경
  Future<void> updateVisibility(String id, bool isPublic);

  // AD-05에서 선택한 섹션의 수정 결과 저장
  Future<void> updateSpaceDetail(
    String id,
    AdminSpaceDetail detail, {
    required String sectionLabel,
  });

  // 재조사 요청 처리
  Future<void> resolveReinspection(
    String spaceId,
    String requestId, {
    String? result,
  });

  // AD-04에서 현재 접수된 요청을 공간 단위로 한 번에 처리한다.
  Future<void> resolveAllReinspections(
    String spaceId, {
    required String result,
  });
}

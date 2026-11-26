import '../../../core/models/building.dart';
import '../../admin_auth/models/admin_user.dart';
import '../models/admin_space.dart';
import '../models/admin_space_detail.dart';
import '../models/selected_space_photo.dart';

abstract class AdminSpaceRepository {
  // 건물 목록(공간 등록 위치 선택)
  Future<List<Building>> fetchBuildings();

  // 관리자 명단(조사자 선택)
  Future<List<AdminUser>> fetchAdmins();

  // 공간 목록
  Future<List<AdminSpace>> fetchSpaces();

  // 공간 기본 정보
  Future<AdminSpace?> fetchSpaceById(String id);

  // 공간 상세 정보
  Future<AdminSpaceDetail?> fetchSpaceDetailById(String id);

  // 사진 한 장 업로드. 서버가 발급한 id와 url을 채운 사진을 돌려준다.
  Future<SelectedSpacePhoto> uploadPhoto(SelectedSpacePhoto photo);

  // 공간 등록. 새 공간의 ID를 돌려준다.
  Future<String> addSpace(
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

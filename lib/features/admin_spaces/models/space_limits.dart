/// 공간 등록 · 수정 화면이 함께 쓰는 입력 상한.
///
/// 서버는 테이블 수와 한 테이블 최대 인원에 상한을 두지 않는다. 화면 상한은 캠퍼스에서 실제로
/// 조사한 가장 큰 값(열람실 테이블 412개)과 사용자 검색의 인원 범위(1~10명)에 맞춘다.
abstract final class SpaceLimits {
  static const maxTableCount = 500;
  static const maxSeatsPerTable = 10;
}

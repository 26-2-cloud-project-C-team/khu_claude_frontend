/// US-06의 세 단계.
enum DirectionsStage {
  /// A · 이동 중(지도 + 경로 요약 시트)
  moving,

  /// B · 건물 도착(내부 안내)
  inBuilding,

  /// C · 이용 중(의견 남기기 진입점)
  inUse,
}

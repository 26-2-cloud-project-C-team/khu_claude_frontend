// TODO(A-07): 공용 코드값 작업(docs/tasks/platform/07)이 들어오면 그쪽 정의로 바꾸고 이 파일을 지운다.

/// 공간 사진 태그. 태그 없는 사진은 null로 다룬다.
enum PhotoTag {
  entrance('ENTRANCE', '입구'),
  // 확인 필요: AD-03은 '가는 길', US-04·US-06은 '복도'(07 작업 '확인 필요'). US-04 시안 기준 '가는 길'.
  hallway('HALLWAY', '가는 길'),
  inside('INSIDE', '내부');

  const PhotoTag(this.code, this.label);

  final String code;
  final String label;

  static PhotoTag? fromCode(String? code) {
    if (code == null) return null;
    return values.firstWhere(
      (v) => v.code == code,
      orElse: () => throw ArgumentError.value(code, 'code', '알 수 없는 사진 태그'),
    );
  }
}

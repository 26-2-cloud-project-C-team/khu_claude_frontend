/// AD-05에서 한 번에 수정할 공간 정보 섹션.
enum AdminSpaceEditSection {
  location('위치', '공간 위치를 고쳐주세요'),
  photos('사진', '공간 사진을 고쳐주세요'),
  rules('이용 규칙과 소음', '이용 규칙과 소음을 고쳐주세요'),
  facilities('테이블과 시설', '테이블과 시설을 고쳐주세요'),
  fieldSurvey('현장에서 느낀 점', '현장에서 느낀 점을 고쳐주세요');

  const AdminSpaceEditSection(this.label, this.title);

  final String label;
  final String title;

  static AdminSpaceEditSection fromName(String? value) {
    for (final section in values) {
      if (section.name == value) return section;
    }
    return location;
  }
}

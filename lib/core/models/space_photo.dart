/// 필수 사진 세 장의 자리. 추가 사진은 태그가 없다.
enum PhotoTag {
  entrance('입구'),
  approach('가는 길'),
  inside('내부');

  const PhotoTag(this.label);

  final String label;
}

class SpacePhoto {
  const SpacePhoto({required this.id, required this.url, this.tag});

  factory SpacePhoto.fromJson(Map<String, dynamic> json, {PhotoTag? tag}) =>
      SpacePhoto(
        id: json['id'] as String,
        url: json['url'] as String,
        tag: tag,
      );

  final String id;
  final String url;
  final PhotoTag? tag;

  /// 공간의 `photos`를 입구 · 가는 길 · 내부 · 추가 사진 순서의 목록으로 바꾼다.
  static List<SpacePhoto> listFromJson(Map<String, dynamic> photos) => [
    for (final tag in PhotoTag.values)
      SpacePhoto.fromJson(photos[tag.name] as Map<String, dynamic>, tag: tag),
    for (final extra in photos['extras'] as List<dynamic>)
      SpacePhoto.fromJson(extra as Map<String, dynamic>),
  ];
}

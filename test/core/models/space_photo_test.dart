import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/models/space_photo.dart';

void main() {
  test('필수 사진 세 장 뒤에 추가 사진을 이어 붙인다', () {
    Map<String, dynamic> photo(String id) => {
      'id': id,
      'url': 'https://cdn.example.com/photos/$id.webp',
    };

    final photos = SpacePhoto.listFromJson({
      'entrance': photo('e'),
      'approach': photo('a'),
      'inside': photo('i'),
      'extras': [photo('x1'), photo('x2')],
    });

    expect([for (final p in photos) p.id], ['e', 'a', 'i', 'x1', 'x2']);
    expect(
      [for (final p in photos) p.tag],
      [PhotoTag.entrance, PhotoTag.approach, PhotoTag.inside, null, null],
    );
    expect(photos.first.url, 'https://cdn.example.com/photos/e.webp');
  });

  test('태그 표시 문구', () {
    expect([for (final t in PhotoTag.values) t.label], ['입구', '가는 길', '내부']);
  });
}

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/features/admin_spaces/utils/photo_file_type.dart';

Uint8List _bytes(List<int> head) => Uint8List.fromList([...head, ...List.filled(16, 0)]);
Uint8List _ascii(String head) => _bytes(head.codeUnits);

void main() {
  test('시그니처로 JPEG · PNG · WebP를 구분한다', () {
    expect(PhotoFileType.detect(_bytes([0xFF, 0xD8, 0xFF, 0xE0])), PhotoFileType.jpeg);
    expect(PhotoFileType.detect(_bytes([0x89, 0x50, 0x4E, 0x47])), PhotoFileType.png);
    expect(PhotoFileType.detect(_ascii('RIFF\x00\x00\x00\x00WEBP')), PhotoFileType.webp);
  });

  test('GIF · HEIC처럼 받을 수 없는 형식은 안내 문구와 함께 거부한다', () {
    for (final head in ['GIF89a', '\x00\x00\x00\x18ftypheic']) {
      expect(
        () => PhotoFileType.validate(_ascii(head)),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', 'JPG · PNG · WEBP 사진만 올릴 수 있어요.')),
      );
    }
  });

  test('10MB를 넘으면 거부한다', () {
    final big = Uint8List(PhotoFileType.maxSourceBytes + 1)..setAll(0, [0xFF, 0xD8, 0xFF]);
    expect(() => PhotoFileType.validate(big), throwsA(isA<FormatException>()));
  });
}

import 'dart:typed_data';

/// 관리자 사진으로 받을 수 있는 형식. 서버가 받는 JPEG · PNG · WebP와 같다.
enum PhotoFileType {
  jpeg('image/jpeg', 'jpg'),
  png('image/png', 'png'),
  webp('image/webp', 'webp');

  const PhotoFileType(this.mimeType, this.extension);

  final String mimeType;
  final String extension;

  static const maxSourceBytes = 10 * 1024 * 1024;

  /// 파일 앞부분의 시그니처로 형식을 판정한다. 확장자나 브라우저가 알려주는 MIME은 믿지 않는다.
  static PhotoFileType? detect(Uint8List bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return jpeg;
    }
    if (_startsWith(bytes, 0, const [0x89, 0x50, 0x4E, 0x47])) return png;
    if (_ascii(bytes, 0, 4) == 'RIFF' && _ascii(bytes, 8, 4) == 'WEBP') return webp;
    return null;
  }

  /// 올릴 수 없는 사진이면 화면에 보여줄 문구를 담은 [FormatException]을 던진다.
  static PhotoFileType validate(Uint8List bytes) {
    if (bytes.lengthInBytes > maxSourceBytes) {
      throw const FormatException('원본 사진의 크기는 10MB 이하여야 해요.');
    }
    final type = detect(bytes);
    if (type == null) {
      throw const FormatException('JPG · PNG · WEBP 사진만 올릴 수 있어요.');
    }
    return type;
  }

  static bool _startsWith(Uint8List bytes, int offset, List<int> prefix) {
    if (bytes.length < offset + prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[offset + i] != prefix[i]) return false;
    }
    return true;
  }

  static String _ascii(Uint8List bytes, int offset, int length) {
    if (bytes.length < offset + length) return '';
    return String.fromCharCodes(bytes.sublist(offset, offset + length));
  }
}

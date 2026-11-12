import 'dart:typed_data';

Future<Uint8List> convertToJpeg(Uint8List sourceBytes) async {
  // Web이 아닌 환경에서는 원본 바이트를 반환
  return sourceBytes;
}
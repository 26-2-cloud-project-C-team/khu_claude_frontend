import 'dart:typed_data';

import 'package:heckofaheic/heckofaheic.dart';

Future<Uint8List> convertToJpeg(Uint8List sourceBytes) async {
  // HEIC / HEIF만 JPEG로 변환
  if (HeckOfAHeic.isHEIC(sourceBytes)) {
    return HeckOfAHeic.convert(
      sourceBytes,
      toType: TargetType.jpeg,
      jpegQuality: 0.85,
    );
  }

  // JPG 등 일반 이미지는 원본 그대로 반환
  return sourceBytes;
}
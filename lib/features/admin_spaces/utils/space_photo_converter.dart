import 'dart:typed_data';

import 'package:heckofaheic/heckofaheic.dart';

class SpacePhotoConverter {
  static Future<Uint8List> toJpeg(Uint8List sourceBytes) async {
    // HEIC / HEIF만 JPEG로 변환
    if (HeckOfAHeic.isHEIC(sourceBytes)) {
      return HeckOfAHeic.convert(
        sourceBytes,
        toType: TargetType.jpeg,
        jpegQuality: 0.85,
      );
    }

    // 일반 JPG는 변환하지 않고 원본 그대로 반환
    return sourceBytes;
  }
}
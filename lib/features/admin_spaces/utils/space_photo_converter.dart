import 'dart:typed_data';

import 'space_photo_converter_stub.dart'
    if (dart.library.html) 'space_photo_converter_web.dart'
    as platform;

class SpacePhotoConverter {
  static Future<Uint8List> toJpeg(Uint8List sourceBytes) {
    return platform.convertToJpeg(sourceBytes);
  }
}
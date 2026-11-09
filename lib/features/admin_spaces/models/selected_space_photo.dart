import 'dart:typed_data';

/// 관리자 공간 화면에서 사용하는 사진 정보.
///
/// 새로 선택한 사진은 [bytes]를 가지고, 서버에 저장된 사진은 [id]와 [url]을 가진다.
class SelectedSpacePhoto {
  const SelectedSpacePhoto({
    required this.name,
    this.mimeType = 'image/webp',
    this.bytes,
    this.id,
    this.url,
  });

  final String name;
  final String mimeType;
  final Uint8List? bytes;
  final String? id;
  final String? url;

  int get sizeInBytes => bytes?.lengthInBytes ?? 0;
  bool get isUploaded => id != null && id!.isNotEmpty;
  bool get hasLocalBytes => bytes != null && bytes!.isNotEmpty;
}

import 'dart:typed_data';

class SelectedSpacePhoto {
  const SelectedSpacePhoto({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;

  int get sizeInBytes => bytes.lengthInBytes;
}

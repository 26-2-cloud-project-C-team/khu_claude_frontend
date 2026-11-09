import 'package:flutter/material.dart';

import '../../features/admin_spaces/models/selected_space_photo.dart';

/// 로컬에서 막 선택한 사진과 서버 CDN 사진을 같은 방식으로 표시한다.
class SelectedSpacePhotoImage extends StatelessWidget {
  const SelectedSpacePhotoImage({
    super.key,
    required this.photo,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  final SelectedSpacePhoto photo;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final bytes = photo.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }

    final url = photo.url;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }

    return const Center(child: Icon(Icons.broken_image_outlined));
  }
}

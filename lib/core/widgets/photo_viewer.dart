import 'package:flutter/material.dart';

import '../models/space_photo.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// [photos]를 [initialIndex]번째부터 전체 화면으로 연다.
Future<void> showPhotoViewer({
  required BuildContext context,
  required List<SpacePhoto> photos,
  int initialIndex = 0,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      pageBuilder: (_, _, _) =>
          PhotoViewer(photos: photos, initialIndex: initialIndex),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class PhotoViewer extends StatefulWidget {
  const PhotoViewer({super.key, required this.photos, this.initialIndex = 0});

  final List<SpacePhoto> photos;
  final int initialIndex;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  static const _dismissDistance = 120.0;
  static const _dismissVelocity = 700.0;

  late final _pageController = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  double _dragOffset = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffset > _dismissDistance || velocity > _dismissVelocity) {
      _close();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tag = widget.photos[_index].tag;
    final fade = 1 - (_dragOffset / (_dismissDistance * 3)).clamp(0.0, 1.0);

    return Material(
      color: Colors.black.withValues(alpha: fade),
      child: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onVerticalDragUpdate: (details) => setState(
                () => _dragOffset = (_dragOffset + details.delta.dy).clamp(
                  0,
                  double.infinity,
                ),
              ),
              onVerticalDragEnd: _onDragEnd,
              child: Transform.translate(
                offset: Offset(0, _dragOffset),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.photos.length,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (_, index) => _Photo(widget.photos[index]),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '${_index + 1} / ${widget.photos.length}',
                    style: AppTypography.body1.copyWith(color: AppColors.white),
                  ),
                  Positioned(
                    left: AppSpacing.screenHorizontal - 10,
                    child: Semantics(
                      label: '닫기',
                      button: true,
                      child: InkWell(
                        onTap: _close,
                        customBorder: const CircleBorder(),
                        child: const SizedBox.square(
                          dimension: 44,
                          child: Icon(
                            Icons.close,
                            size: 24,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (tag != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: AppSpacing.section,
                child: Text(
                  tag.label,
                  textAlign: TextAlign.center,
                  style: AppTypography.body1.copyWith(color: AppColors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo(this.photo);

  final SpacePhoto photo;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      photo.url,
      fit: BoxFit.contain,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : const Center(
              child: CircularProgressIndicator(color: AppColors.white),
            ),
      errorBuilder: (_, _, _) => const Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 40,
          color: AppColors.gray500,
        ),
      ),
    );
  }
}

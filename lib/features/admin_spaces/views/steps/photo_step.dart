import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/space_photo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/selected_space_photo_image.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/selected_space_photo.dart';
import '../../viewmodels/admin_space_form_view_model.dart';

class PhotoStep extends StatefulWidget {
  const PhotoStep({super.key});

  @override
  State<PhotoStep> createState() => _PhotoStepState();
}

class _PhotoStepState extends State<PhotoStep> {
  final ImagePicker _picker = ImagePicker();

  String? _errorMessage;

  static const int _maxFileSize = 10 * 1024 * 1024;

  Future<SelectedSpacePhoto?> _selectPhoto() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);

    if (file == null) return null;

    final extension = file.name.split('.').last.toLowerCase();

    final mimeType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };

    if (mimeType == null) {
      throw const FormatException('JPG, PNG, WebP 형식의 사진만 선택할 수 있어요.');
    }

    final bytes = await file.readAsBytes();

    if (bytes.lengthInBytes > _maxFileSize) {
      throw const FormatException('사진 한 장의 크기는 10MB 이하여야 해요.');
    }

    return SelectedSpacePhoto(
      name: file.name,
      mimeType: mimeType,
      bytes: bytes,
    );
  }

  Future<void> _pickRequiredPhoto(PhotoTag tag) async {
    try {
      final photo = await _selectPhoto();

      if (!mounted || photo == null) return;

      context.read<AdminSpaceFormViewModel>().setRequiredPhoto(tag, photo);

      setState(() => _errorMessage = null);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _pickExtraPhoto() async {
    final viewModel = context.read<AdminSpaceFormViewModel>();

    if (viewModel.photoCount >= 10) {
      setState(() {
        _errorMessage = '사진은 최대 10장까지 선택할 수 있어요.';
      });
      return;
    }

    try {
      final photo = await _selectPhoto();

      if (!mounted || photo == null) return;

      viewModel.addExtraPhoto(photo);

      setState(() => _errorMessage = null);
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;

    setState(() {
      _errorMessage = error is FormatException
          ? error.message.toString()
          : '사진을 불러오지 못했어요. 다시 시도해주세요.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminSpaceFormViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final tag in PhotoTag.values) ...[
          _RequiredPhotoTile(
            tag: tag,
            photo: viewModel.requiredPhotos[tag],
            onTap: () => _pickRequiredPhoto(tag),
          ),
          const SizedBox(height: 10),
        ],

        const SizedBox(height: 12),

        OutlinedButton.icon(
          onPressed: viewModel.photoCount < 10 ? _pickExtraPhoto : null,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('사진 더 올리기'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.gray700,
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: AppColors.gray200),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTypography.body2,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          '추가 사진 ${viewModel.extraPhotos.length}장 · 전체 ${viewModel.photoCount}/10장',
          style: AppTypography.caption,
          textAlign: TextAlign.right,
        ),

        if (viewModel.extraPhotos.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < viewModel.extraPhotos.length; i++)
                _ExtraPhotoTile(
                  photo: viewModel.extraPhotos[i],
                  onRemove: () => viewModel.removeExtraPhoto(i),
                ),
            ],
          ),
        ],

        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: AppTypography.body2.copyWith(color: AppColors.primary),
          ),
        ],

        const SizedBox(height: 16),

        Text('입구, 가는 길, 내부 사진은 필수입니다.', style: AppTypography.caption),
      ],
    );
  }
}

class _RequiredPhotoTile extends StatelessWidget {
  const _RequiredPhotoTile({
    required this.tag,
    required this.photo,
    required this.onTap,
  });

  final PhotoTag tag;
  final SelectedSpacePhoto? photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = photo != null;

    return Material(
      color: AppColors.gray50,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 82,
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 62,
                  height: 62,
                  child: selected
                      ? SelectedSpacePhotoImage(photo: photo!, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.gray200,
                          child: const Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.gray500,
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag.label,
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selected ? photo!.name : '사진 선택하기',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),

              Icon(
                selected ? Icons.check_circle : Icons.add_circle_outline,
                color: selected ? AppColors.positive : AppColors.gray400,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExtraPhotoTile extends StatelessWidget {
  const _ExtraPhotoTile({required this.photo, required this.onRemove});

  final SelectedSpacePhoto photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SelectedSpacePhotoImage(photo: photo, fit: BoxFit.cover),
            ),
          ),

          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: AppColors.dim,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(5),
                  child: Icon(Icons.close, size: 15, color: AppColors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

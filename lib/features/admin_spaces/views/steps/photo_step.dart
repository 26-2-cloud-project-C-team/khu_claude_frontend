import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/space_photo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/selected_space_photo_image.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/form_photo.dart';
import '../../models/selected_space_photo.dart';
import '../../utils/photo_file_type.dart';
import '../../viewmodels/admin_space_form_view_model.dart';

class PhotoStep extends StatefulWidget {
  const PhotoStep({super.key});

  @override
  State<PhotoStep> createState() => _PhotoStepState();
}

class _PhotoStepState extends State<PhotoStep> {
  final ImagePicker _picker = ImagePicker();

  String? _errorMessage;

  Future<SelectedSpacePhoto> _convertPhoto(XFile file) async {
    final sourceBytes = await file.readAsBytes();
    final type = PhotoFileType.validate(sourceBytes);

    return SelectedSpacePhoto(
      name: 'photo.${type.extension}',
      mimeType: type.mimeType,
      bytes: sourceBytes,
    );
  }

  Future<void> _pickRequiredPhoto(PhotoTag tag) async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      final photo = await _convertPhoto(file);
      if (!mounted) return;

      context.read<AdminSpaceFormViewModel>().setRequiredPhoto(tag, photo);
      setState(() => _errorMessage = null);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _pickExtraPhoto() async {
    final viewModel = context.read<AdminSpaceFormViewModel>();
    final remaining = AdminSpaceFormViewModel.maxPhotos - viewModel.photoCount;

    if (remaining <= 0) {
      setState(() => _errorMessage = '사진은 최대 10장까지 올릴 수 있어요.');
      return;
    }

    try {
      final files = await _picker.pickMultiImage(limit: remaining);
      if (!mounted || files.isEmpty) return;

      String? lastError;
      for (final file in files) {
        try {
          final photo = await _convertPhoto(file);
          if (!viewModel.addExtraPhoto(photo)) break;
        } catch (error) {
          lastError = _messageOf(error);
        }
      }

      if (!mounted) return;
      setState(() => _errorMessage = lastError);
    } catch (error) {
      _showError(error);
    }
  }

  static String _messageOf(Object error) => error is FormatException
      ? error.message
      : '사진을 불러오지 못했어요. 다시 시도해주세요.';

  void _showError(Object error) {
    if (!mounted) return;
    setState(() => _errorMessage = _messageOf(error));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminSpaceFormViewModel>();
    final errors = [
      ?_errorMessage,
      for (final tag in PhotoTag.values)
        if (viewModel.requiredPhotoErrors[tag] case final message?)
          '${tag.label}: $message',
      ?viewModel.extraPhotoError,
    ];

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
          onPressed: viewModel.photoCount < AdminSpaceFormViewModel.maxPhotos
              ? _pickExtraPhoto
              : null,
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
          '추가 사진 ${viewModel.extraPhotos.length}장 · 전체 ${viewModel.photoCount}/${AdminSpaceFormViewModel.maxPhotos}장',
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

        for (final message in errors) ...[
          const SizedBox(height: 12),
          Text(
            message,
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
  final FormPhoto? photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
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
                      ? _UploadingPhoto(photo: photo)
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
                      switch (photo?.status) {
                        null => '사진 선택하기',
                        PhotoUploadStatus.waiting => '올리기 대기 중',
                        PhotoUploadStatus.uploading => '올리는 중',
                        PhotoUploadStatus.uploaded => '올렸어요',
                      },
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),

              Icon(
                photo?.isUploaded == true
                    ? Icons.check_circle
                    : Icons.add_circle_outline,
                color: photo?.isUploaded == true
                    ? AppColors.positive
                    : AppColors.gray400,
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

  final FormPhoto photo;
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
              child: _UploadingPhoto(photo: photo),
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

/// 올리기 전 · 올리는 중인 사진은 흐리게 두고 진행 표시를 얹는다.
class _UploadingPhoto extends StatelessWidget {
  const _UploadingPhoto({required this.photo});

  final FormPhoto photo;

  @override
  Widget build(BuildContext context) {
    final image = SelectedSpacePhotoImage(photo: photo.photo, fit: BoxFit.cover);
    if (photo.isUploaded) return image;

    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(opacity: 0.4, child: image),
        Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.gray700,
              value: photo.status == PhotoUploadStatus.waiting ? 0 : null,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../admin_auth/models/admin_user.dart';
import '../../viewmodels/admin_space_form_view_model.dart';

class FieldSurveyStep extends StatefulWidget {
  const FieldSurveyStep({super.key});

  @override
  State<FieldSurveyStep> createState() => _FieldSurveyStepState();
}

class _FieldSurveyStepState extends State<FieldSurveyStep> {
  late final TextEditingController _goodPointsController;
  late final TextEditingController _badPointsController;
  late final TextEditingController _memoController;

  @override
  void initState() {
    super.initState();

    final viewModel = context.read<AdminSpaceFormViewModel>();

    _goodPointsController = TextEditingController(text: viewModel.goodPoints);
    _badPointsController = TextEditingController(text: viewModel.badPoints);
    _memoController = TextEditingController(text: viewModel.memo);
  }

  @override
  void dispose() {
    _goodPointsController.dispose();
    _badPointsController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _selectSurveyor() async {
    final viewModel = context.read<AdminSpaceFormViewModel>();
    final selected = await showAppSelectSheet<AdminUser>(
      context: context,
      title: '조사자를 선택해주세요',
      options: viewModel.surveyorOptions,
      selected: viewModel.surveyor,
      labelOf: (admin) => admin.name,
      captionOf: (admin) => viewModel.isCurrentAdmin(admin) ? '나' : null,
    );
    if (selected != null) viewModel.selectSurveyor(selected);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminSpaceFormViewModel>();
    final photosPending = viewModel.isUploadingPhotos;
    final photosMissing = !viewModel.hasRequiredPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('직접 방문해서 느낀 점을 기록해 주세요. 모든 항목은 등록에 필요합니다.', style: AppTypography.body2),
        const SizedBox(height: 28),

        _InputSection(
          title: '좋았던 점',
          description: '공간의 장점이나 이용하기 편리했던 점',
          child: AppTextField(
            controller: _goodPointsController,
            placeholder: '예: 콘센트가 많고 책상이 넓어요.',
            maxLength: 40,
            lines: 2,
            onChanged: viewModel.setGoodPoints,
          ),
        ),

        const SizedBox(height: 24),

        _InputSection(
          title: '아쉬웠던 점',
          description: '불편했던 점이나 개선이 필요한 부분',
          child: AppTextField(
            controller: _badPointsController,
            placeholder: '예: 점심시간에는 소음이 커요.',
            maxLength: 40,
            lines: 2,
            onChanged: viewModel.setBadPoints,
          ),
        ),

        const SizedBox(height: 24),

        _InputSection(
          title: '추가 메모',
          description: '그 외에 남기고 싶은 정보를 기록해주세요.',
          child: AppTextField(
            controller: _memoController,
            placeholder: '예: 평일 오후에는 비교적 한산해요.',
            maxLength: 100,
            lines: 3,
            onChanged: viewModel.setMemo,
          ),
        ),

        const SizedBox(height: 24),

        _InputSection(
          title: '조사자',
          description: '현장을 조사한 관리자',
          child: _SurveyorField(
            name: viewModel.surveyor?.name,
            onTap: viewModel.surveyorOptions.isEmpty ? null : _selectSurveyor,
          ),
        ),

        if (photosMissing || photosPending) ...[
          const SizedBox(height: 12),
          Text(
            photosMissing
                ? '1단계에서 다시 골라야 할 사진이 있어요.'
                : '사진을 올리는 중이에요. 끝나면 등록할 수 있어요.',
            style: AppTypography.caption.copyWith(color: AppColors.gray700),
          ),
        ],

        const SizedBox(height: AppSpacing.section),
      ],
    );
  }
}

class _SurveyorField extends StatelessWidget {
  const _SurveyorField({required this.name, required this.onTap});

  final String? name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gray50,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name ?? '선택',
                  style: AppTypography.body2.copyWith(
                    color: name == null ? AppColors.gray400 : AppColors.gray900,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.gray500,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputSection extends StatelessWidget {
  const _InputSection({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h3),
        const SizedBox(height: 4),
        Text(description, style: AppTypography.caption),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

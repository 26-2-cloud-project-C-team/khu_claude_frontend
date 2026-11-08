import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
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
  late final TextEditingController _surveyorController;

  @override
  void initState() {
    super.initState();

    final viewModel = context.read<AdminSpaceFormViewModel>();

    _goodPointsController = TextEditingController(text: viewModel.goodPoints);
    _badPointsController = TextEditingController(text: viewModel.badPoints);
    _memoController = TextEditingController(text: viewModel.memo);
    _surveyorController = TextEditingController(text: viewModel.surveyor ?? '');
  }

  @override
  void dispose() {
    _goodPointsController.dispose();
    _badPointsController.dispose();
    _memoController.dispose();
    _surveyorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<AdminSpaceFormViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('직접 방문해서 느낀 점과 조사자 정보를 기록해 주세요.', style: AppTypography.body2),
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
          description: '그 외에 남기고 싶은 정보',
          child: AppTextField(
            controller: _memoController,
            placeholder: '추가로 기록할 내용이 있다면 입력해 주세요.',
            maxLength: 100,
            lines: 3,
            onChanged: viewModel.setMemo,
          ),
        ),

        const SizedBox(height: 24),

        _InputSection(
          title: '조사자',
          description: '현장 조사를 진행한 사람의 이름',
          child: AppTextField(
            controller: _surveyorController,
            placeholder: '이름을 입력해 주세요.',
            onChanged: viewModel.setSurveyor,
          ),
        ),

        const SizedBox(height: AppSpacing.section),
      ],
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

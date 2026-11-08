import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_step_scaffold.dart';
import '../viewmodels/admin_space_form_view_model.dart';
import 'steps/photo_step.dart';

class AdminSpaceCreatePage extends StatelessWidget {
  const AdminSpaceCreatePage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminSpaceFormViewModel(),
      child: _AdminSpaceCreateContent(onBack: onBack),
    );
  }
}

class _AdminSpaceCreateContent extends StatelessWidget {
  const _AdminSpaceCreateContent({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminSpaceFormViewModel>();

    final step = viewModel.currentStep;

    final titles = [
      '공간 사진을 찍어주세요',
      '공간 위치를 알려주세요',
      '이용 규칙과 소음을 기록해주세요',
      '테이블과 시설을 기록해주세요',
      '현장에서 느낀 점을 적어주세요',
    ];

    return AppStepScaffold(
      step: step,
      filledSteps: step - 1,
      totalSteps: 5,
      title: titles[step - 1],
      body: step == 1
          ? const PhotoStep()
          : const Center(child: Text('이 단계는 다음 개발 과정에서 구현합니다.')),
      ctaLabel: step == 5 ? '등록하기' : '다음',
      onCta: viewModel.canProceed
          ? () {
              if (step == 1) {
                viewModel.nextStep();
              }
            }
          : null,
      onBack: () {
        if (step == 1) {
          onBack();
        } else {
          viewModel.previousStep();
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/router.dart';
import '../../../core/widgets/app_step_scaffold.dart';
import '../../admin_auth/viewmodels/admin_auth_view_model.dart';
import '../data/admin_space_repository.dart';
import '../viewmodels/admin_space_form_view_model.dart';
import '../viewmodels/admin_space_list_view_model.dart';
import 'steps/facilities_step.dart';
import 'steps/field_survey_step.dart';
import 'steps/location_step.dart';
import 'steps/photo_step.dart';
import 'steps/rules_noise_step.dart';

class AdminSpaceCreatePage extends StatelessWidget {
  const AdminSpaceCreatePage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AdminSpaceFormViewModel(
        repository: context.read<AdminSpaceRepository>(),
        currentAdminEmail: context.read<AdminAuthViewModel>().admin?.email,
      ),
      child: _AdminSpaceCreateContent(onBack: onBack),
    );
  }
}

class _AdminSpaceCreateContent extends StatelessWidget {
  const _AdminSpaceCreateContent({required this.onBack});

  final VoidCallback onBack;

  static const _titles = [
    '공간 사진을 찍어주세요',
    '공간 위치를 알려주세요',
    '이용 규칙과 소음을 기록해주세요',
    '테이블과 시설을 기록해주세요',
    '현장에서 느낀 점을 적어주세요',
  ];

  Future<void> _submit(BuildContext context, AdminSpaceFormViewModel viewModel) async {
    final listViewModel = context.read<AdminSpaceListViewModel>();
    final spaceId = await viewModel.submit();
    if (!context.mounted) return;

    if (spaceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.submitError ?? '공간을 등록하지 못했어요.')),
      );
      return;
    }

    await listViewModel.refreshAfterCreate();
    if (!context.mounted) return;
    // 등록 폼으로 돌아오지 않도록 목록 위에 상세를 새로 쌓는다(AD-03 → AD-04).
    context.go('${AppRoutes.adminSpace(spaceId)}?toast=created');
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminSpaceFormViewModel>();
    final step = viewModel.currentStep;

    return AppStepScaffold(
      step: step,
      filledSteps: step,
      totalSteps: viewModel.totalSteps,
      title: _titles[step - 1],
      body: switch (step) {
        1 => const PhotoStep(),
        2 => const LocationStep(),
        3 => const RulesNoiseStep(),
        4 => const FacilitiesStep(),
        _ => const FieldSurveyStep(),
      },
      ctaLabel: step == viewModel.totalSteps ? '등록하기' : '다음',
      onCta: viewModel.canProceed
          ? () {
              if (step < viewModel.totalSteps) {
                viewModel.nextStep();
              } else {
                _submit(context, viewModel);
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

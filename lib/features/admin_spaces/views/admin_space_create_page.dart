import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/space_photo.dart';
import '../../../core/widgets/app_step_scaffold.dart';
import '../data/admin_space_repository.dart';
import '../models/admin_space.dart';
import '../models/admin_space_activity.dart';
import '../models/admin_space_detail.dart';
import '../models/selected_space_photo.dart';
import '../viewmodels/admin_space_form_view_model.dart';
import '../viewmodels/admin_space_list_view_model.dart';

import 'steps/photo_step.dart';
import 'steps/location_step.dart';
import 'steps/rules_noise_step.dart';
import 'steps/facilities_step.dart';
import 'steps/field_survey_step.dart';

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
      filledSteps: step,
      totalSteps: 5,
      title: titles[step - 1],
      body: switch (step) {
        1 => const PhotoStep(),
        2 => const LocationStep(),
        3 => const RulesNoiseStep(),
        4 => const FacilitiesStep(),
        5 => const FieldSurveyStep(),
        _ => const Center(child: Text('이 단계는 다음 개발 과정에서 구현합니다.')),
      },
      ctaLabel: step == 5 ? '등록하기' : '다음',
      onCta: viewModel.canProceed
          ? () async {
              if (step < 5) {
                viewModel.nextStep();
                return;
              }

              final building = viewModel.building;
              final floor = viewModel.floor;

              if (building == null || floor == null) return;

              final now = DateTime.now();
              final space = AdminSpace(
                id: 'space-${now.microsecondsSinceEpoch}',
                name: viewModel.spaceName.trim(),
                location:
                    '${building.name} · $floor층 · ${viewModel.detailLocation.trim()}',
                updatedAt: now,
                isPublic: true,
              );
              final photos = <SelectedSpacePhoto>[
                for (final tag in PhotoTag.values)
                  if (viewModel.requiredPhotos[tag] != null)
                    viewModel.requiredPhotos[tag]!,
                ...viewModel.extraPhotos,
              ];
              final detail = AdminSpaceDetail(
                space: space,
                photos: photos,
                purpose: viewModel.purpose?.label ?? '',
                isCafe: viewModel.cafeEnabled,
                canTalk: viewModel.conversationEnabled,
                is24Hours: viewModel.is24Hours,
                startMinute: viewModel.startMinutes,
                endMinute: viewModel.endMinutes,
                noiseLevel: viewModel.noiseLevel.label,
                tableCount: viewModel.tableCount,
                maxPeoplePerTable: viewModel.maxPeoplePerTable,
                chargingTableCount: viewModel.chargingTableCount,
                hasFreeWifi: viewModel.hasFreeWifi,
                goodPoints: viewModel.goodPoints,
                badPoints: viewModel.badPoints,
                memo: viewModel.memo,
                surveyor: viewModel.surveyor ?? '',
                activities: [
                  AdminSpaceActivity(
                    id: 'activity-${space.id}',
                    title: '최초 조사',
                    description: '공간 정보가 등록되었습니다.',
                    createdAt: now,
                    actor: viewModel.surveyor?.trim().isNotEmpty == true
                        ? viewModel.surveyor!.trim()
                        : '관리자',
                  ),
                ],
              );

              try {
                final repository = context.read<AdminSpaceRepository>();
                final listViewModel = context.read<AdminSpaceListViewModel>();

                await repository.addSpace(space, detail: detail);
                await listViewModel.refreshAfterCreate();

                if (!context.mounted) return;

                onBack();
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('공간 등록에 실패했습니다. 다시 시도해주세요.')),
                );
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

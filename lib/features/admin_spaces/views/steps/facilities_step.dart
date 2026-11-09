import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_stepper.dart';
import '../../viewmodels/admin_space_form_view_model.dart';

class FacilitiesStep extends StatelessWidget {
  const FacilitiesStep({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminSpaceFormViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '공간의 테이블과 편의시설 정보를 입력해 주세요.',
          style: AppTypography.body2.copyWith(color: AppColors.gray600),
        ),
        const SizedBox(height: 24),

        _Section(
          title: '테이블 정보',
          children: [
            AppStepperRow(
              label: '전체 테이블 수',
              value: viewModel.tableCount,
              min: 1,
              max: 40,
              unit: '개',
              onChanged: viewModel.setTableCount,
            ),
            const SizedBox(height: 12),
            AppStepperRow(
              label: '테이블당 최대 인원',
              value: viewModel.maxPeoplePerTable,
              min: 1,
              max: 8,
              unit: '명',
              onChanged: viewModel.setMaxPeoplePerTable,
            ),
            const SizedBox(height: 12),
            AppStepperRow(
              label: '충전 가능 테이블',
              value: viewModel.chargingTableCount,
              min: 0,
              max: viewModel.tableCount,
              unit: '개',
              onChanged: viewModel.setChargingTableCount,
            ),
          ],
        ),

        const SizedBox(height: 28),

        _Section(
          title: '편의시설',
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.cardPadding,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('무료 Wi-Fi', style: AppTypography.body1),
                        const SizedBox(height: 4),
                        Text(
                          '공간 이용자에게 무료 Wi-Fi를 제공하나요?',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: viewModel.hasFreeWifi,
                    onChanged: viewModel.setFreeWifi,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h3),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

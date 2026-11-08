import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/building.dart';
import '../../../../core/models/purpose.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/building_list.dart';
import '../../data/mock_buildings.dart';
import '../../viewmodels/admin_space_form_view_model.dart';

class LocationStep extends StatefulWidget {
  const LocationStep({super.key});

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  late final TextEditingController _nameController;
  late final TextEditingController _detailController;

  @override
  void initState() {
    super.initState();

    final viewModel = context.read<AdminSpaceFormViewModel>();

    _nameController = TextEditingController(text: viewModel.spaceName);

    _detailController = TextEditingController(text: viewModel.detailLocation);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _selectBuilding() async {
    final viewModel = context.read<AdminSpaceFormViewModel>();

    final Building? building = await showBuildingSelectSheet(
      context: context,
      title: '건물을 선택해주세요',
      buildings: mockBuildings,
      selected: viewModel.building,
    );

    if (!mounted || building == null) return;

    // 건물을 변경하면 ViewModel에서 기존 층을 초기화한다.
    viewModel.setBuilding(building);
  }

  Future<void> _selectFloor() async {
    final viewModel = context.read<AdminSpaceFormViewModel>();
    final building = viewModel.building;

    if (building == null) return;

    final floors = building.floorRange.floors;

    if (floors.isEmpty) return;

    final selectedFloor = await showAppSelectSheet<int>(
      context: context,
      title: '층을 선택해주세요',
      options: floors,
      selected: viewModel.floor,
      labelOf: _floorLabel,
    );

    if (!mounted || selectedFloor == null) return;

    viewModel.setFloor(selectedFloor);
  }

  String _floorLabel(int floor) {
    if (floor < 0) {
      return '지하 ${floor.abs()}층';
    }

    return '$floor층';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminSpaceFormViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel('공간 이름'),

        AppTextField(
          controller: _nameController,
          placeholder: '공간 이름을 입력해주세요',
          maxLength: 40,
          onChanged: viewModel.setSpaceName,
        ),

        _CharacterCounter(controller: _nameController, maxLength: 40),

        const SizedBox(height: AppSpacing.section),

        _FieldLabel('건물'),

        _SelectField(
          value: viewModel.building?.name ?? '건물을 선택해주세요',
          isSelected: viewModel.building != null,
          onTap: _selectBuilding,
        ),

        const SizedBox(height: AppSpacing.section),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _FieldLabel('층'),

                  _SelectField(
                    value: viewModel.floor == null
                        ? '선택'
                        : _floorLabel(viewModel.floor!),
                    isSelected: viewModel.floor != null,
                    enabled: viewModel.building != null,
                    onTap: _selectFloor,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _FieldLabel('내부 상세 위치'),

                  AppTextField(
                    controller: _detailController,
                    placeholder: '상세 위치 입력',
                    maxLength: 40,
                    onChanged: viewModel.setDetailLocation,
                  ),
                ],
              ),
            ),
          ],
        ),

        _CharacterCounter(controller: _detailController, maxLength: 40),

        const SizedBox(height: AppSpacing.section),

        const _FieldLabel('어울리는 이용 목적 · 1개 선택'),

        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final purpose in Purpose.values)
              _PurposeChip(
                purpose: purpose,
                selected: viewModel.purpose == purpose,
                onTap: () => viewModel.setPurpose(purpose),
              ),
          ],
        ),

        const SizedBox(height: AppSpacing.between),

        Text('건물과 층을 선택하고 공간의 정확한 위치를 입력해주세요.', style: AppTypography.caption),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: AppTypography.label.copyWith(color: AppColors.gray700),
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.value,
    required this.isSelected,
    required this.onTap,
    this.enabled = true,
  });

  final String value;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.gray50 : AppColors.gray100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body2.copyWith(
                    color: !enabled
                        ? AppColors.gray400
                        : isSelected
                        ? AppColors.gray900
                        : AppColors.gray400,
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

class _PurposeChip extends StatelessWidget {
  const _PurposeChip({
    required this.purpose,
    required this.selected,
    required this.onTap,
  });

  final Purpose purpose;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.gray100,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Text(
            purpose.label,
            style: AppTypography.label.copyWith(
              color: selected ? AppColors.white : AppColors.gray700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterCounter extends StatelessWidget {
  const _CharacterCounter({required this.controller, required this.maxLength});

  final TextEditingController controller;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${value.text.runes.length}/$maxLength',
            textAlign: TextAlign.right,
            style: AppTypography.caption,
          ),
        );
      },
    );
  }
}

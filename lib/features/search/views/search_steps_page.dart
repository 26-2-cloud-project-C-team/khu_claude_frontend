import 'package:flutter/material.dart';

import '../../../core/models/purpose.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_option_row.dart';
import '../../../core/widgets/app_selection_mode.dart';
import '../../../core/widgets/app_step_scaffold.dart';
import '../../../core/widgets/app_stepper.dart';
import '../models/origin.dart';
import '../models/requirement.dart';
import '../models/search_condition.dart';
import '../models/search_result.dart';
import '../models/sort_key.dart';
import '../viewmodels/search_flow_view_model.dart';

/// US-01 · US-02 검색 조건 5단계. 단계는 한 페이지 안에서 좌→우 슬라이드로 바뀐다.
class SearchStepsPage extends StatefulWidget {
  const SearchStepsPage({
    super.key,
    required this.viewModel,
    required this.onExit,
    required this.onChooseBuilding,
    required this.onSearched,
  });

  final SearchFlowViewModel viewModel;

  /// 첫 단계, 또는 조건 시트에서 들어온 단계에서 뒤로 갔을 때.
  final VoidCallback onExit;

  /// US-03으로. [locationUnavailable]이면 위치를 못 가져와서 바로 넘어가는 경우다.
  final void Function({required bool locationUnavailable}) onChooseBuilding;

  /// 검색 완료. 결과가 비었으면 US-05, 아니면 US-04로 보낸다.
  final ValueChanged<SearchResult> onSearched;

  @override
  State<SearchStepsPage> createState() => _SearchStepsPageState();
}

class _SearchStepsPageState extends State<SearchStepsPage> {
  SearchFlowViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    if (_vm.step == SearchStep.origin && _vm.originStatus == OriginStatus.idle) {
      _locate();
    }
  }

  Future<void> _locate() async {
    await _vm.locate();
    if (!mounted) return;
    if (_vm.originStatus == OriginStatus.unavailable && _vm.condition.origin == null) {
      widget.onChooseBuilding(locationUnavailable: true);
    }
  }

  void _back() {
    if (!_vm.back()) widget.onExit();
  }

  Future<void> _search() async {
    final result = await _vm.search();
    if (!mounted) return;
    // 실패하면 버튼만 다시 켠다. 통신 오류 재시도 안내는 설계(DS-00 ②)에서 뺐다.
    if (result == null) return;
    widget.onSearched(result);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final step = _vm.step;
        final canProceed = _vm.canProceed && !_vm.isSearching;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _back();
          },
          child: AppStepScaffold(
            step: step.index,
            filledSteps: SearchStep.values.where(_vm.isStepFilled).length,
            totalSteps: SearchStep.values.length,
            title: _title(step),
            subtitle: _subtitle(step),
            onBack: _back,
            ctaLabel: _ctaLabel(step),
            onCta: !canProceed
                ? null
                : step == SearchStep.sort
                ? _search
                : _vm.next,
            body: _body(step),
          ),
        );
      },
    );
  }

  String _title(SearchStep step) => switch (step) {
    SearchStep.origin => '현재 위치에서 출발할까요?',
    SearchStep.purpose => '어떤 공간을 찾아 드릴까요?',
    SearchStep.headcount => '몇 명이 이용하나요?',
    SearchStep.requirements => '필요한 조건이 있으면 선택해주세요',
    SearchStep.sort => '어떤 공간부터 보여 드릴까요?',
  };

  String _subtitle(SearchStep step) => switch (step) {
    SearchStep.origin => '현재 위치를 기준으로 가까운 공간을 찾아 드려요',
    SearchStep.purpose => '이용 목적에 해당하는 공간을 하나만 선택해주세요',
    SearchStep.headcount => '함께 사용하는 인원을 알려주세요',
    SearchStep.requirements || SearchStep.sort => '여러 개 고를 수 있어요',
  };

  String _ctaLabel(SearchStep step) => switch (step) {
    SearchStep.origin => '이 위치에서 시작',
    SearchStep.sort => '공간 찾기',
    _ => '다음',
  };

  Widget _body(SearchStep step) => switch (step) {
    SearchStep.origin => _OriginBody(
      viewModel: _vm,
      onOtherBuilding: () => widget.onChooseBuilding(locationUnavailable: false),
    ),
    SearchStep.purpose => Column(
      spacing: AppSpacing.between,
      children: [
        for (final p in Purpose.values)
          AppOptionRow(
            title: p.label,
            selected: _vm.condition.purpose == p,
            onTap: () => _vm.selectPurpose(p),
          ),
      ],
    ),
    SearchStep.headcount => Center(
      child: AppStepper(
        value: _vm.condition.headcount,
        min: SearchCondition.minHeadcount,
        max: SearchCondition.maxHeadcount,
        unit: '명',
        onChanged: _vm.setHeadcount,
      ),
    ),
    SearchStep.requirements => _RequirementsBody(viewModel: _vm),
    SearchStep.sort => Column(
      spacing: AppSpacing.between,
      children: [
        for (final k in SortKey.values)
          AppOptionRow(
            title: k.label,
            subtitle: k.description,
            selected: _vm.condition.sortKeys.contains(k),
            onTap: () => _vm.toggleSortKey(k),
            mode: AppSelectionMode.multiple,
          ),
      ],
    ),
  };
}

class _OriginBody extends StatelessWidget {
  const _OriginBody({required this.viewModel, required this.onOtherBuilding});

  final SearchFlowViewModel viewModel;
  final VoidCallback onOtherBuilding;

  @override
  Widget build(BuildContext context) {
    final origin = viewModel.condition.origin;
    if (origin == null) {
      if (viewModel.originStatus == OriginStatus.unavailable) {
        // 보통은 US-03으로 바로 넘어가지만, 거기서 뒤로 돌아온 경우를 위해 둔다.
        return AppButton(
          label: '출발할 건물 고르기',
          onPressed: onOtherBuilding,
          variant: AppButtonVariant.text,
        );
      }
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.section),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    final (title, detail) = switch (origin) {
      CurrentLocationOrigin(:final fix, :final nearestBuilding) => (
        '현재 위치',
        '${nearestBuilding.name} 앞 · 정확도 ±${fix.accuracyMeters.round()}m',
      ),
      BuildingOrigin(:final building) => ('출발 건물', building.name),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Row(
            children: [
              // 현재 위치는 경희블루 전용이다(DS-00).
              const Icon(Icons.my_location, color: AppColors.khuBlue),
              const SizedBox(width: AppSpacing.between),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.h3),
                    const SizedBox(height: AppSpacing.textLine),
                    Text(detail, style: AppTypography.body2.copyWith(color: AppColors.gray700)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.between),
        AppButton(
          label: '다른 건물에서 출발할래요',
          onPressed: onOtherBuilding,
          variant: AppButtonVariant.text,
        ),
      ],
    );
  }
}

class _RequirementsBody extends StatelessWidget {
  const _RequirementsBody({required this.viewModel});

  final SearchFlowViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final selected = viewModel.condition.requirements;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.inside,
          runSpacing: AppSpacing.inside,
          children: [
            for (final r in Requirement.values)
              AppChip(
                label: r.label,
                selected: selected.contains(r),
                onTap: () => viewModel.toggleRequirement(r),
                mode: AppSelectionMode.multiple,
              ),
          ],
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.between),
          Text(
            '${selected.length}개 선택됨 · 고른 조건을 모두 만족하는 공간만 보여드려요',
            style: AppTypography.caption.copyWith(color: AppColors.gray500),
          ),
        ],
      ],
    );
  }
}

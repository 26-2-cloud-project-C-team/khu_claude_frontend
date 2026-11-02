import 'package:flutter/material.dart';

import '../../../core/models/purpose.dart';
import '../models/origin.dart';
import '../models/requirement.dart';
import '../models/search_condition.dart';
import '../models/search_result.dart';
import '../models/sort_key.dart';
import '../viewmodels/search_flow_view_model.dart';
import 'widgets/option_tile.dart';
import 'widgets/step_scaffold.dart';

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
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('잠시 후 다시 시도해주세요')),
      );
      return;
    }
    widget.onSearched(result);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final step = _vm.step;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _back();
          },
          child: StepScaffold(
            filled: [for (final s in SearchStep.values) _vm.isStepFilled(s)],
            title: _title(step),
            subtitle: _subtitle(step),
            onBack: _back,
            ctaLabel: _ctaLabel(step),
            ctaLoading: _vm.isSearching,
            onCta: !_vm.canProceed
                ? null
                : step == SearchStep.sort
                    ? _search
                    : _vm.next,
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
                child: child,
              ),
              child: KeyedSubtree(key: ValueKey(step), child: _body(step)),
            ),
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
            children: [
              for (final p in Purpose.values)
                OptionTile(
                  label: p.label,
                  selected: _vm.condition.purpose == p,
                  onTap: () => _vm.selectPurpose(p),
                ),
            ],
          ),
        SearchStep.headcount => _HeadcountStepper(viewModel: _vm),
        SearchStep.requirements => _RequirementsBody(viewModel: _vm),
        SearchStep.sort => Column(
            children: [
              for (final k in SortKey.values)
                OptionTile(
                  label: k.label,
                  subtitle: k.description,
                  selected: _vm.condition.sortKeys.contains(k),
                  onTap: () => _vm.toggleSortKey(k),
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
    final theme = Theme.of(context);
    final origin = viewModel.condition.origin;
    if (origin == null) {
      if (viewModel.originStatus == OriginStatus.unavailable) {
        // 보통은 US-03으로 바로 넘어가지만, 거기서 뒤로 돌아온 경우를 위해 둔다.
        return TextButton(onPressed: onOtherBuilding, child: const Text('출발할 건물 고르기'));
      }
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
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
        Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.my_location, color: theme.colorScheme.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(detail, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(onPressed: onOtherBuilding, child: const Text('다른 건물에서 출발할래요')),
      ],
    );
  }
}

class _HeadcountStepper extends StatelessWidget {
  const _HeadcountStepper({required this.viewModel});

  final SearchFlowViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.outlined(
          iconSize: 28,
          constraints: const BoxConstraints.tightFor(width: 52, height: 52),
          tooltip: '인원 줄이기',
          onPressed: viewModel.canDecrementHeadcount ? viewModel.decrementHeadcount : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 120,
          child: Text(
            '${viewModel.condition.headcount}명',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        IconButton.outlined(
          iconSize: 28,
          constraints: const BoxConstraints.tightFor(width: 52, height: 52),
          tooltip: '인원 늘리기',
          onPressed: viewModel.canIncrementHeadcount ? viewModel.incrementHeadcount : null,
          icon: const Icon(Icons.add),
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
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in Requirement.values)
              FilterChip(
                label: Text(r.label),
                selected: selected.contains(r),
                onSelected: (_) => viewModel.toggleRequirement(r),
              ),
          ],
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '${selected.length}개 선택됨 · 고른 조건을 모두 만족하는 공간만 보여드려요',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

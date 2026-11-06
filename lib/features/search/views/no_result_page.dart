import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_screen_parts.dart';
import '../models/search_result.dart';
import '../viewmodels/no_result_view_model.dart';

/// US-05 결과 없음 · 조건 변경 대안.
class NoResultPage extends StatefulWidget {
  const NoResultPage({
    super.key,
    required this.viewModel,
    required this.onAdopt,
    required this.onRestart,
  });

  final NoResultViewModel viewModel;

  /// 고른 대안으로 다시 검색한 결과. SearchFlowViewModel.adopt 후 US-04(1위부터)로 보낸다.
  final ValueChanged<SearchResult> onAdopt;

  /// '처음부터 다시 설정': 조건 초기화 후 US-00으로.
  final VoidCallback onRestart;

  @override
  State<NoResultPage> createState() => _NoResultPageState();
}

class _NoResultPageState extends State<NoResultPage> {
  NoResultViewModel get _vm => widget.viewModel;

  Future<void> _adopt() async {
    final result = await _vm.adopt();
    // 실패하면 버튼만 다시 켠다. 통신 오류 재시도 안내는 설계(DS-00 ②)에서 뺐다.
    if (mounted && result != null) widget.onAdopt(result);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final count = _vm.selectedCount;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      56 + AppSpacing.belowTitle,
                      AppSpacing.screenHorizontal,
                      AppSpacing.belowTitle,
                    ),
                    children: [
                      const Text('조건에 맞는 공간이 없어요', style: AppTypography.h1),
                      const SizedBox(height: AppSpacing.inside),
                      Text(
                        '조건을 하나만 바꾸면 찾을 수 있어요',
                        style: AppTypography.body1.copyWith(color: AppColors.gray600),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      for (var i = 0; i < _vm.alternatives.length; i++) ...[
                        _AlternativeRow(
                          label: _vm.alternatives[i].alternative.label,
                          count: _vm.alternatives[i].count,
                          selected: _vm.selectedIndex == i,
                          onTap: () => _vm.select(i),
                        ),
                        const SizedBox(height: AppSpacing.between),
                      ],
                    ],
                  ),
                ),
                AppCtaArea(
                  label: count == null ? '후보 보기' : '$count곳 보기',
                  onPressed: _vm.canSubmit ? _adopt : null,
                  secondaryLabel: '처음부터 다시 설정',
                  onSecondaryPressed: widget.onRestart,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 대안 행. 공통 옵션 행과 같은 모양에 오른쪽 예상 후보 수 배지를 둔다.
/// 선택되면 Primary Tint 배경 + 테두리, 배지는 Primary로 채운다.
class _AlternativeRow extends StatelessWidget {
  const _AlternativeRow({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? AppColors.primaryTint : AppColors.gray50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.option),
          side: BorderSide(color: selected ? AppColors.primary : AppColors.gray100, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.body1.copyWith(
                        color: selected ? AppColors.primary : AppColors.gray900,
                      ),
                    ),
                  ),
                  Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.inside),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.gray100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$count곳',
                      style: AppTypography.label.copyWith(
                        color: selected ? AppColors.white : AppColors.gray600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

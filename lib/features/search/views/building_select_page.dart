import 'package:flutter/material.dart';

import '../../../core/models/building.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/geo.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_screen_parts.dart';
import '../models/origin.dart';
import '../viewmodels/search_flow_view_model.dart';

// TODO(A-10): 건물 목록·검색 위젯이 core에 들어오면 목록 부분을 그쪽으로 바꾼다.

/// US-03 출발 건물 선택. 행을 탭하면 확인 없이 출발점이 되고 다음 단계로 간다.
class BuildingSelectPage extends StatefulWidget {
  const BuildingSelectPage({
    super.key,
    required this.viewModel,
    required this.locationUnavailable,
    required this.onSelected,
    required this.onLocated,
    required this.onBack,
  });

  final SearchFlowViewModel viewModel;

  /// true면 A(위치를 가져올 수 없을 때), false면 B(다른 건물에서 출발).
  final bool locationUnavailable;

  /// 건물을 골랐다. 검색 조건 퍼널의 인원 단계로 돌아간다.
  final VoidCallback onSelected;

  /// '허용하기' 후 위치를 얻었다. US-01 A(현재 위치 카드)로 돌아간다.
  final VoidCallback onLocated;
  final VoidCallback onBack;

  @override
  State<BuildingSelectPage> createState() => _BuildingSelectPageState();
}

class _BuildingSelectPageState extends State<BuildingSelectPage> {
  String _query = '';

  SearchFlowViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.loadBuildings();
  }

  Future<void> _allowLocation() async {
    await _vm.locate();
    if (mounted && _vm.originStatus == OriginStatus.located) widget.onLocated();
  }

  List<Building> _filtered() {
    final q = _query.trim();
    final list = [
      for (final b in _vm.buildings)
        if (q.isEmpty || b.name.contains(q)) b,
    ]..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppNavBar(onBack: widget.onBack),
          Expanded(
            child: ListenableBuilder(
              listenable: _vm,
              builder: (context, _) {
                final buildings = _filtered();
                final origin = _vm.condition.origin;
                final here = origin is CurrentLocationOrigin ? origin.point : null;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.belowTitle,
                    AppSpacing.screenHorizontal,
                    34,
                  ),
                  children: [
                    Text(
                      widget.locationUnavailable ? '어느 건물에서 출발하시나요?' : '출발할 건물을 선택해주세요',
                      style: AppTypography.h1,
                    ),
                    if (widget.locationUnavailable) ...[
                      const SizedBox(height: AppSpacing.inside),
                      Text(
                        '현재 위치를 가져올 수 없어요',
                        style: AppTypography.body1.copyWith(color: AppColors.gray600),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.belowTitle),
                    if (widget.locationUnavailable) ...[
                      _LocationNotice(
                        onAllow: _vm.originStatus == OriginStatus.locating ? null : _allowLocation,
                      ),
                      const SizedBox(height: AppSpacing.between),
                    ],
                    _BuildingSearchField(onChanged: (v) => setState(() => _query = v)),
                    const SizedBox(height: AppSpacing.item),
                    Text(
                      '전체 건물 · 가나다순',
                      style: AppTypography.caption.copyWith(color: AppColors.gray500),
                    ),
                    const SizedBox(height: AppSpacing.inside),
                    if (!_vm.buildingsLoaded && !_vm.buildingsFailed)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.section),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      ),
                    for (final b in buildings)
                      AppSheetOption(
                        label: b.name,
                        caption: here == null
                            ? null
                            : '직선 ${distanceMeters(here, b.point).round()}m',
                        selected: false,
                        onTap: () {
                          _vm.chooseBuilding(b);
                          widget.onSelected();
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 검색창 위의 위치 안내 줄(경희블루 Tint). 검색창과 높이 52 · 왼쪽 여백 16 · 아이콘 20을 맞춘다.
class _LocationNotice extends StatelessWidget {
  const _LocationNotice({required this.onAllow});

  final VoidCallback? onAllow;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: AppSpacing.cardPadding, right: AppSpacing.textLine),
      decoration: BoxDecoration(
        color: AppColors.khuBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off_outlined, size: 20, color: AppColors.khuBlue),
          const SizedBox(width: AppSpacing.inside),
          Expanded(
            child: Text(
              '위치 권한이 필요해요',
              style: AppTypography.body2.copyWith(color: AppColors.gray900),
            ),
          ),
          TextButton(
            onPressed: onAllow,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.khuBlue,
              textStyle: AppTypography.body2.copyWith(fontWeight: FontWeight.w600),
              minimumSize: const Size(44, 44),
            ),
            child: const Text('허용하기'),
          ),
        ],
      ),
    );
  }
}

/// 건물 이름 검색창. 공통 입력 필드에는 앞 아이콘이 없어 같은 토큰으로 따로 둔다.
class _BuildingSearchField extends StatelessWidget {
  const _BuildingSearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.control)),
      borderSide: BorderSide.none,
    );
    return SizedBox(
      height: 52,
      child: TextField(
        style: AppTypography.body1.copyWith(color: AppColors.gray900),
        decoration: InputDecoration(
          hintText: '건물 이름 검색',
          hintStyle: AppTypography.body1.copyWith(color: AppColors.gray400),
          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.gray500),
          filled: true,
          fillColor: AppColors.gray50,
          contentPadding: EdgeInsets.zero,
          border: border,
          enabledBorder: border,
          focusedBorder: border,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

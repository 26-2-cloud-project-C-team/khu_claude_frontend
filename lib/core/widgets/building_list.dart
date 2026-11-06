import 'package:flutter/material.dart';

import '../models/building.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_bottom_sheet.dart';

/// 검색 필드와 가나다순 건물 행 목록. 행을 누르면 [onSelected]로 그 건물을 넘긴다.
///
/// 전체 화면은 제목 등을 [header]에 넣고 화면 여백을 [padding]으로 준다.
/// 바텀시트는 [showBuildingSelectSheet]를 쓴다.
class BuildingList extends StatefulWidget {
  const BuildingList({
    super.key,
    required this.buildings,
    required this.onSelected,
    this.selected,
    this.captionOf,
    this.header,
    this.padding = EdgeInsets.zero,
  });

  final List<Building> buildings;
  final ValueChanged<Building> onSelected;
  final Building? selected;

  /// 이름 옆 보조 문구. 예: 직선 400m
  final String? Function(Building building)? captionOf;
  final Widget? header;
  final EdgeInsets padding;

  @override
  State<BuildingList> createState() => _BuildingListState();
}

class _BuildingListState extends State<BuildingList> {
  String _query = '';

  List<Building> get _visible {
    final query = _normalize(_query);
    return [
      for (final building in widget.buildings)
        if (_normalize(building.name).contains(query)) building,
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Widget build(BuildContext context) {
    final header = widget.header;
    final captionOf = widget.captionOf;

    return ListView(
      padding: widget.padding,
      children: [
        ?header,
        _SearchField(onChanged: (value) => setState(() => _query = value)),
        const SizedBox(height: AppSpacing.inside),
        for (final building in _visible)
          AppSheetOption(
            label: building.name,
            caption: captionOf?.call(building),
            selected: building == widget.selected,
            onTap: () => widget.onSelected(building),
          ),
      ],
    );
  }
}

/// 띄어쓰기와 영문 대소문자가 달라도 찾도록 맞춘다.
String _normalize(String value) =>
    value.replaceAll(RegExp(r'\s'), '').toLowerCase();

/// 건물을 고르는 큰 바텀시트. 행을 누르면 그 건물로 바로 닫고, 그냥 닫으면 `null`이다.
Future<Building?> showBuildingSelectSheet({
  required BuildContext context,
  required String title,
  required List<Building> buildings,
  Building? selected,
}) {
  return showAppBottomSheet<Building>(
    context: context,
    title: title,
    expanded: true,
    builder: (context) => BuildingList(
      buildings: buildings,
      selected: selected,
      onSelected: (building) => Navigator.of(context).pop(building),
    ),
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

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
        style: AppTypography.body1,
        decoration: InputDecoration(
          hintText: '건물 이름 검색',
          hintStyle: AppTypography.body1.copyWith(color: AppColors.gray400),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: AppColors.gray500,
          ),
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

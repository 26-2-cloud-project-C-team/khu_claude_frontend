import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../models/requirement.dart';
import '../../models/search_condition.dart';
import '../../models/sort_key.dart';

/// 검색 조건 요약 시트(US-04). 항목을 탭하면 그 단계를 돌려준다. 바깥을 눌러 닫으면 null.
Future<SearchStep?> showConditionSheet(BuildContext context, SearchCondition condition) {
  return showAppBottomSheet<SearchStep>(
    context: context,
    title: '검색 조건',
    subtitle: '항목을 탭하면 그 단계로 돌아가 바꾼 뒤 다시 찾아 드려요',
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final step in SearchStep.values)
          _ConditionRow(
            label: stepLabel(step),
            value: conditionValueLabel(condition, step),
            onTap: () => Navigator.of(context).pop(step),
          ),
      ],
    ),
  );
}

class _ConditionRow extends StatelessWidget {
  const _ConditionRow({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      child: Container(
        height: 56,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.gray100)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(label, style: AppTypography.body2.copyWith(color: AppColors.gray500)),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body1.copyWith(color: AppColors.gray900),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}

String stepLabel(SearchStep step) => switch (step) {
  SearchStep.origin => '출발점',
  SearchStep.purpose => '목적',
  SearchStep.headcount => '인원',
  SearchStep.requirements => '필요 조건',
  SearchStep.sort => '정렬',
};

String conditionValueLabel(SearchCondition c, SearchStep step) => switch (step) {
  SearchStep.origin => c.origin?.label ?? '-',
  SearchStep.purpose => c.purpose?.label ?? '-',
  SearchStep.headcount => '${c.headcount}명',
  SearchStep.requirements =>
    c.requirements.isEmpty
        ? '없음'
        : [
            for (final r in Requirement.values)
              if (c.requirements.contains(r)) r.label,
          ].join(' · '),
  SearchStep.sort =>
    c.sortKeys.isEmpty
        ? SortKey.distance.label
        : [
            for (final k in SortKey.values)
              if (c.sortKeys.contains(k)) k.label,
          ].join(' · '),
};

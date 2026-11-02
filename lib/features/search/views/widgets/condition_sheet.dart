import 'package:flutter/material.dart';

import '../../models/requirement.dart';
import '../../models/search_condition.dart';
import '../../models/sort_key.dart';

/// 검색 조건 요약 시트(US-04). 항목을 탭하면 그 단계를 돌려준다. 바깥을 눌러 닫으면 null.
Future<SearchStep?> showConditionSheet(BuildContext context, SearchCondition condition) {
  return showModalBottomSheet<SearchStep>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('검색 조건', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('항목을 탭하면 그 단계로 돌아가 바꾼 뒤 다시 찾아 드려요',
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              for (final step in SearchStep.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(stepLabel(step)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(conditionValueLabel(condition, step)),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => Navigator.of(context).pop(step),
                ),
            ],
          ),
        ),
      );
    },
  );
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
      SearchStep.requirements => c.requirements.isEmpty
          ? '없음'
          : [
              for (final r in Requirement.values)
                if (c.requirements.contains(r)) r.label,
            ].join(' · '),
      SearchStep.sort => c.sortKeys.isEmpty
          ? SortKey.distance.label
          : [
              for (final k in SortKey.values)
                if (c.sortKeys.contains(k)) k.label,
            ].join(' · '),
    };

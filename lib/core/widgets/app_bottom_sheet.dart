import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 바깥을 누르거나 아래로 내려 닫으면 null을 돌려준다. 호출한 쪽은 null이면 이전 값을 그대로 둔다.
///
/// 여러 값을 맞추는 시트는 [builder] 안에 '확인' 버튼을 두고 `Navigator.pop(context, 값)`으로 닫는다.
/// [expanded]는 목록이 긴 시트를 화면 위쪽까지 올라오는 큰 시트로 연다.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  String? title,
  String? subtitle,
  bool expanded = false,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: expanded,
    backgroundColor: AppColors.white,
    barrierColor: AppColors.dim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.bottomSheet),
      ),
    ),
    builder: (context) => _SheetFrame(
      title: title,
      subtitle: subtitle,
      expanded: expanded,
      child: builder(context),
    ),
  );
}

/// 하나를 고르는 시트. 항목을 누르면 그 값을 돌려주며 바로 닫는다.
Future<T?> showAppSelectSheet<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<T> options,
  required String Function(T option) labelOf,
  String? Function(T option)? captionOf,
  T? selected,
  bool expanded = false,
}) {
  return showAppBottomSheet<T>(
    context: context,
    title: title,
    subtitle: subtitle,
    expanded: expanded,
    builder: (context) => ListView(
      shrinkWrap: !expanded,
      padding: EdgeInsets.zero,
      children: [
        for (final option in options)
          AppSheetOption(
            label: labelOf(option),
            caption: captionOf?.call(option),
            selected: option == selected,
            onTap: () => Navigator.of(context).pop(option),
          ),
      ],
    ),
  );
}

class AppSheetOption extends StatelessWidget {
  const AppSheetOption({
    super.key,
    required this.label,
    this.caption,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final caption = this.caption;

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
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
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: AppTypography.body1.copyWith(
                          color: selected
                              ? AppColors.primary
                              : AppColors.gray900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (caption != null) ...[
                      const SizedBox(width: AppSpacing.textLine),
                      Text(caption, style: AppTypography.caption),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check, size: 20, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.child,
  });

  final String? title;
  final String? subtitle;
  final bool expanded;
  final Widget child;

  // 큰 시트는 화면 위에서 이만큼 남기고 올라온다(설계서 AD-03 건물 선택).
  static const _expandedTopGap = 120.0;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final subtitle = this.subtitle;

    final content = Padding(
      // 아래 34는 하단 CTA 영역과 같은 세이프 에어리어 고정값이다.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        12,
        AppSpacing.screenHorizontal,
        34,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.cardPadding),
          if (title != null) Text(title, style: AppTypography.h2),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.textLine),
            Text(subtitle, style: AppTypography.caption),
          ],
          if (title != null || subtitle != null)
            const SizedBox(height: AppSpacing.between),
          if (expanded) Expanded(child: child) else Flexible(child: child),
        ],
      ),
    );

    if (!expanded) return content;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height - _expandedTopGap,
      child: content,
    );
  }
}

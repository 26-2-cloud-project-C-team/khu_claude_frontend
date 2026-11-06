import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// 모달로 여는 의견 화면(US-07)의 위쪽 닫기(×) 줄. [AppNavBar]와 높이 56 · 터치 영역 44를 맞춘다.
class CloseBar extends StatelessWidget {
  const CloseBar({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.screenHorizontal - 10),
          Semantics(
            label: '닫기',
            button: true,
            child: Tooltip(
              message: '닫기',
              child: InkWell(
                onTap: onClose,
                customBorder: const CircleBorder(),
                splashFactory: NoSplash.splashFactory,
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                child: const SizedBox.square(
                  dimension: 44,
                  child: Icon(Icons.close, size: 24, color: AppColors.gray900),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

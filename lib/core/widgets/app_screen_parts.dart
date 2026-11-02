import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';

/// 화면 위쪽의 뒤로가기 줄. 높이 56이다.
class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          // 아이콘(24)은 화면 좌우 여백 20에 맞추고, 터치 영역 44는 그 바깥으로 넓힌다.
          const SizedBox(width: AppSpacing.screenHorizontal - 10),
          Semantics(
            label: '뒤로',
            button: true,
            child: InkWell(
              onTap: onBack,
              customBorder: const CircleBorder(),
              splashFactory: NoSplash.splashFactory,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              child: const SizedBox.square(
                dimension: 44,
                child: Icon(
                  Icons.chevron_left,
                  size: 24,
                  color: AppColors.gray900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 숫자 없이 칸을 채워 진행을 보여준다. [filled]는 채울 칸 수다.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({super.key, required this.filled, required this.total});

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$total단계 중 $filled단계',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Row(
            spacing: AppSpacing.textLine,
            children: [
              for (var i = 0; i < total; i++)
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: i < filled ? AppColors.primary : AppColors.gray100,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 화면 아래 고정 CTA 영역. Primary 버튼 하나와, 필요하면 그 아래 텍스트 버튼을 둔다.
///
/// [onPressed]가 null이면 오류 문구 없이 버튼만 비활성으로 둔다.
class AppCtaArea extends StatelessWidget {
  const AppCtaArea({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    final secondaryLabel = this.secondaryLabel;

    return Padding(
      // 아래 34는 세이프 에어리어 고정값이다.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.cardPadding,
        AppSpacing.screenHorizontal,
        34,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.textLine,
        children: [
          AppButton(label: label, onPressed: onPressed),
          if (secondaryLabel != null)
            AppButton(
              label: secondaryLabel,
              onPressed: onSecondaryPressed,
              variant: AppButtonVariant.text,
            ),
        ],
      ),
    );
  }
}

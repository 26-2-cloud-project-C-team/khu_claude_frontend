import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_screen_parts.dart';

/// 검색 조건(US-01·02)과 공간 등록(AD-03)의 단계형 화면 틀.
///
/// 한 경로 안에서 단계를 바꾸므로 [step]이 바뀌면 제목·부제·내용이 슬라이드로 바뀐다.
/// 다음 단계로 가면 오른쪽에서 들어오고, 이전 단계로 가면 왼쪽에서 들어온다.
class AppStepScaffold extends StatelessWidget {
  const AppStepScaffold({
    super.key,
    required this.step,
    required this.filledSteps,
    required this.totalSteps,
    required this.title,
    this.subtitle,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
    this.secondaryCtaLabel,
    this.onSecondaryCta,
    required this.onBack,
  });

  final int step;
  final int filledSteps;
  final int totalSteps;
  final String title;
  final String? subtitle;
  final Widget body;
  final String ctaLabel;
  final VoidCallback? onCta;
  final String? secondaryCtaLabel;
  final VoidCallback? onSecondaryCta;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;

    return Scaffold(
      body: Column(
        children: [
          AppNavBar(onBack: onBack),
          AppProgressBar(filled: filledSteps, total: totalSteps),
          Expanded(
            child: AppStepTransition(
              step: step,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.belowTitle,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: AppTypography.h1),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.inside),
                      Text(
                        subtitle,
                        style: AppTypography.body1.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                    SizedBox(
                      height: subtitle == null
                          ? AppSpacing.belowTitle
                          : AppSpacing.section,
                    ),
                    body,
                  ],
                ),
              ),
            ),
          ),
          AppCtaArea(
            label: ctaLabel,
            onPressed: onCta,
            secondaryLabel: secondaryCtaLabel,
            onSecondaryPressed: onSecondaryCta,
          ),
        ],
      ),
    );
  }
}

/// [step]이 커지면 새 내용이 오른쪽에서, 작아지면 왼쪽에서 들어온다.
class AppStepTransition extends StatefulWidget {
  const AppStepTransition({super.key, required this.step, required this.child});

  final int step;
  final Widget child;

  @override
  State<AppStepTransition> createState() => _AppStepTransitionState();
}

class _AppStepTransitionState extends State<AppStepTransition> {
  var _forward = true;

  @override
  void didUpdateWidget(AppStepTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.step != oldWidget.step) _forward = widget.step > oldWidget.step;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        transitionBuilder: (child, animation) {
          final entering = child.key == ValueKey(widget.step);
          // 나가는 내용은 animation이 1에서 0으로 거꾸로 흐르므로 시작 위치가 곧 나가는 방향이다.
          final from = (entering == _forward) ? 1.0 : -1.0;
          return SlideTransition(
            position: Tween(
              begin: Offset(from, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        child: KeyedSubtree(key: ValueKey(widget.step), child: widget.child),
      ),
    );
  }
}

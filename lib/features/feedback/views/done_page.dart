import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_screen_parts.dart';

enum DoneKind {
  review('후기를 남겨주셔서 감사해요'),
  reinspection('요청을 보냈어요');

  const DoneKind(this.title);

  final String title;
}

/// US-08 완료. 뒤로가기·닫기 없이 '확인'만 둔다. 시스템 뒤로가기도 '확인'과 같다.
class DonePage extends StatelessWidget {
  const DonePage({super.key, required this.kind, required this.onConfirm});

  final DoneKind kind;

  /// 조건을 모두 초기화하고 US-00으로.
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onConfirm();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.positiveTint,
                          shape: BoxShape.circle,
                        ),
                        child: const DrawnCheck(color: AppColors.positive),
                      ),
                      const SizedBox(height: AppSpacing.belowTitle),
                      // 완료 화면은 H1 원칙의 예외로 결과형 제목을 쓰고 부제는 두지 않는다.
                      Text(kind.title, style: AppTypography.h1),
                    ],
                  ),
                ),
              ),
              AppCtaArea(label: '확인', onPressed: onConfirm),
            ],
          ),
        ),
      ),
    );
  }
}

/// 진입할 때 한 번 그려지는 체크. 축하 효과는 두지 않는다.
/// '동작 줄이기' 설정이면 처음부터 다 그린 상태로 보인다.
class DrawnCheck extends StatelessWidget {
  const DrawnCheck({
    super.key,
    required this.color,
    this.duration = const Duration(milliseconds: 400),
  });

  final Color color;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
      duration: reduceMotion ? Duration.zero : duration,
      curve: Curves.easeOut,
      builder: (context, progress, _) => CustomPaint(
        painter: _CheckPainter(color: color, progress: progress),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final path = Path()
      ..moveTo(size.width / 2 - s * 0.2, size.height / 2)
      ..lineTo(size.width / 2 - s * 0.05, size.height / 2 + s * 0.15)
      ..lineTo(size.width / 2 + s * 0.22, size.height / 2 - s * 0.13);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress || old.color != color;
}

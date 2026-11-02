import 'package:flutter/material.dart';

// TODO(A-05): 기반 구조의 단계형 화면 레이아웃이 들어오면 그쪽으로 바꾸고 이 파일을 지운다.

/// 단계형 화면 틀: 뒤로가기 + 진행 바(숫자 없음) + 질문형 H1 + 부제 + 내용 + 하단 Primary CTA 1개.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.filled,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
    required this.onBack,
    this.subtitle,
    this.ctaLoading = false,
  });

  /// 진행 바 칸마다 채울지.
  final List<bool> filled;
  final String title;
  final String? subtitle;
  final Widget body;
  final String ctaLabel;

  /// null이면 CTA 비활성.
  final VoidCallback? onCta;
  final VoidCallback onBack;
  final bool ctaLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '뒤로',
          onPressed: onBack,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StepProgressBar(filled: filled),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  Text(title, style: theme.textTheme.headlineSmall),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: theme.textTheme.bodyMedium),
                  ],
                  const SizedBox(height: 24),
                  body,
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                onPressed: ctaLoading ? null : onCta,
                child: ctaLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(ctaLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StepProgressBar extends StatelessWidget {
  const StepProgressBar({super.key, required this.filled});

  final List<bool> filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < filled.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              key: ValueKey('progress-$i'),
              height: 4,
              decoration: BoxDecoration(
                color: filled[i] ? scheme.primary : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onConfirm();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TODO(A-02): Positive(#0E8A5F) · Positive Tint는 디자인 토큰으로 바꾼다.
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE6F4EE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, size: 40, color: Color(0xFF0E8A5F)),
                      ),
                      const SizedBox(height: 24),
                      Text(kind.title, style: theme.textTheme.headlineSmall),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
                child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  onPressed: onConfirm,
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

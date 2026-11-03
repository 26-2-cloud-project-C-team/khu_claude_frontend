import 'package:flutter/material.dart';

import '../models/rating.dart';
import '../viewmodels/review_view_model.dart';

/// US-07 A(별점) · B(후기). 모달로 열리고 닫으면 입력값을 버린다.
class ReviewPage extends StatefulWidget {
  const ReviewPage({
    super.key,
    required this.viewModel,
    required this.spaceName,
    required this.onDone,
    required this.onClose,
  });

  final ReviewViewModel viewModel;
  final String spaceName;

  /// 등록 완료 → US-08 A.
  final VoidCallback onDone;

  /// × 또는 A에서 뒤로.
  final VoidCallback onClose;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late final TextEditingController _text;

  ReviewViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: _vm.text);
    _vm.load().then((_) {
      // 오늘 남긴 후기를 복원했으면 입력칸에도 채운다.
      if (mounted && _text.text.isEmpty) _text.text = _vm.text;
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool includeText}) async {
    final ok = await _vm.submit(includeText: includeText);
    if (!mounted) return;
    // 실패하면 버튼만 다시 켠다. 통신 오류 재시도 안내는 설계(DS-00 ②)에서 뺐다.
    if (ok) widget.onDone();
  }

  void _back() {
    if (_vm.step == ReviewStep.text) {
      _vm.backToRating();
    } else {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final onText = _vm.step == ReviewStep.text;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _back();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: onText
                  ? IconButton(icon: const Icon(Icons.arrow_back), tooltip: '뒤로', onPressed: _back)
                  : IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: '닫기',
                      onPressed: widget.onClose,
                    ),
            ),
            body: onText ? _textBody(context) : _ratingBody(context),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: onText
                      ? [
                          FilledButton(
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                            onPressed: _vm.isSubmitting || !_vm.isTextValid
                                ? null
                                : () => _submit(includeText: true),
                            child: const Text('등록하기'),
                          ),
                          if (_vm.canSubmitRatingOnly)
                            TextButton(
                              onPressed: _vm.isSubmitting
                                  ? null
                                  : () => _submit(includeText: false),
                              child: const Text('후기 없이 별점만 등록'),
                            ),
                        ]
                      : [
                          FilledButton(
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                            onPressed: _vm.canProceedFromRating ? _vm.goToText : null,
                            child: const Text('다음'),
                          ),
                        ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _ratingBody(BuildContext context) {
    final theme = Theme.of(context);
    final rating = _vm.rating ?? 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('이용한 공간은 만족스러우셨나요?', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(widget.spaceName, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = minRating; i <= maxRating; i++)
              IconButton(
                iconSize: 44,
                tooltip: '$i점',
                onPressed: () => _vm.selectRating(i),
                // TODO(A-02): 별점 골드(#C3A353)는 디자인 토큰으로 바꾼다.
                icon: Icon(
                  i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i <= rating ? const Color(0xFFC3A353) : theme.colorScheme.outline,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_vm.rating != null)
          Text(
            '${_vm.rating}점 · ${_vm.ratingLabel}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
      ],
    );
  }

  Widget _textBody(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('간단한 후기 작성을 부탁드려요', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('작성한 후기는 다른 사용자에게 익명으로 공개돼요', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
        TextField(
          controller: _text,
          maxLines: 6,
          maxLength: reviewMaxLength,
          decoration: InputDecoration(
            labelText: '후기',
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: _vm.updateText,
        ),
      ],
    );
  }
}

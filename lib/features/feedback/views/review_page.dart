import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_rating.dart';
import '../../../core/widgets/app_screen_parts.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/rating.dart';
import '../viewmodels/review_view_model.dart';
import 'widgets/close_bar.dart';

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
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // A는 닫기(×), B는 별점으로 돌아가는 뒤로(‹).
                  if (onText) AppNavBar(onBack: _back) else CloseBar(onClose: widget.onClose),
                  Expanded(child: onText ? _textBody() : _ratingBody()),
                  if (onText)
                    AppCtaArea(
                      label: '등록하기',
                      onPressed: _vm.isSubmitting || !_vm.isTextValid
                          ? null
                          : () => _submit(includeText: true),
                      secondaryLabel: _vm.canSubmitRatingOnly ? '후기 없이 별점만 등록' : null,
                      onSecondaryPressed: _vm.isSubmitting
                          ? null
                          : () => _submit(includeText: false),
                    )
                  else
                    AppCtaArea(
                      label: '다음',
                      onPressed: _vm.canProceedFromRating ? _vm.goToText : null,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _ratingBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.belowTitle,
        AppSpacing.screenHorizontal,
        AppSpacing.belowTitle,
      ),
      children: [
        const Text('이용한 공간은 만족스러우셨나요?', style: AppTypography.h1),
        const SizedBox(height: AppSpacing.inside),
        Text(widget.spaceName, style: AppTypography.body1.copyWith(color: AppColors.gray600)),
        const SizedBox(height: AppSpacing.section),
        Center(
          child: AppRatingInput(value: _vm.rating, onChanged: _vm.selectRating),
        ),
        const SizedBox(height: AppSpacing.between),
        if (_vm.rating != null)
          Text(
            '${_vm.rating}점 · ${_vm.ratingLabel}',
            textAlign: TextAlign.center,
            style: AppTypography.h3,
          ),
      ],
    );
  }

  Widget _textBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.belowTitle,
        AppSpacing.screenHorizontal,
        AppSpacing.belowTitle,
      ),
      children: [
        const Text('간단한 후기 작성을 부탁드려요', style: AppTypography.h1),
        const SizedBox(height: AppSpacing.inside),
        Text(
          '작성한 후기는 다른 사용자에게 익명으로 공개돼요',
          style: AppTypography.body1.copyWith(color: AppColors.gray600),
        ),
        const SizedBox(height: AppSpacing.section),
        AppTextField(
          controller: _text,
          placeholder: '후기',
          lines: 6,
          maxLength: reviewMaxLength,
          onChanged: _vm.updateText,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_screen_parts.dart';
import '../../../core/widgets/app_selection_mode.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/rating.dart';
import '../../../core/models/reinspection_category.dart';
import '../viewmodels/reinspection_view_model.dart';
import 'widgets/close_bar.dart';

/// US-07 C 재조사 요청. 모달로 열리고 닫으면 입력값을 버린다.
class ReinspectionPage extends StatefulWidget {
  const ReinspectionPage({
    super.key,
    required this.viewModel,
    required this.onDone,
    required this.onClose,
  });

  final ReinspectionViewModel viewModel;

  /// 요청 완료 → US-08 B.
  final VoidCallback onDone;
  final VoidCallback onClose;

  @override
  State<ReinspectionPage> createState() => _ReinspectionPageState();
}

class _ReinspectionPageState extends State<ReinspectionPage> {
  ReinspectionViewModel get _vm => widget.viewModel;

  Future<void> _submit() async {
    final ok = await _vm.submit();
    if (!mounted) return;
    // 실패하면 버튼만 다시 켠다. 통신 오류 재시도 안내는 설계(DS-00 ②)에서 뺐다.
    if (ok) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              CloseBar(onClose: widget.onClose),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.belowTitle,
                    AppSpacing.screenHorizontal,
                    AppSpacing.belowTitle,
                  ),
                  children: [
                    const Text('어떤 정보가 달랐나요?', style: AppTypography.h1),
                    const SizedBox(height: AppSpacing.inside),
                    Text(
                      '확인 후 결과를 공간 상세에 알려 드려요',
                      style: AppTypography.body1.copyWith(color: AppColors.gray600),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    Wrap(
                      spacing: AppSpacing.inside,
                      runSpacing: AppSpacing.inside,
                      children: [
                        for (final c in ReinspectionCategory.values)
                          AppChip(
                            label: c.label,
                            selected: _vm.isSelected(c),
                            onTap: () => _vm.toggle(c),
                            mode: AppSelectionMode.multiple,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.item),
                    AppTextField(
                      placeholder: '상세 내용',
                      lines: 5,
                      maxLength: reinspectionDetailMaxLength,
                      onChanged: _vm.updateDetail,
                    ),
                  ],
                ),
              ),
              AppCtaArea(label: '요청 보내기', onPressed: _vm.canSubmit ? _submit : null),
            ],
          ),
        ),
      ),
    );
  }
}

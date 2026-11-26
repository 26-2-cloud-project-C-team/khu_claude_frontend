import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';

/// 스테퍼로 누르기엔 큰 수(열람실 테이블 412개 등)를 직접 적는 시트. 범위를 벗어나면 '확인'이 비활성이다.
Future<int?> showNumberInputSheet({
  required BuildContext context,
  required String title,
  required int value,
  required int min,
  required int max,
  required String unit,
}) {
  return showAppBottomSheet<int>(
    context: context,
    title: title,
    subtitle: '$min~$max$unit',
    builder: (context) => _NumberInput(value: value, min: min, max: max, unit: unit),
  );
}

class _NumberInput extends StatefulWidget {
  const _NumberInput({
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
  });

  final int value;
  final int min;
  final int max;
  final String unit;

  @override
  State<_NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<_NumberInput> {
  late final _controller = TextEditingController(text: '${widget.value}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _parsed {
    final value = int.tryParse(_controller.text);
    if (value == null || value < widget.min || value > widget.max) return null;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parsed;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTypography.h2,
            decoration: InputDecoration(suffixText: widget.unit),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (parsed != null) Navigator.of(context).pop(parsed);
            },
          ),
          const SizedBox(height: AppSpacing.section),
          AppButton(
            label: '확인',
            onPressed: parsed == null ? null : () => Navigator.of(context).pop(parsed),
          ),
        ],
      ),
    );
  }
}

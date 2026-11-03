import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.maxLength,
    this.lines = 1,
    this.onChanged,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final int? maxLength;
  final int lines;
  final ValueChanged<String>? onChanged;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  TextEditingController? _ownController;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      maxLength: widget.maxLength,
      buildCounter: _hideDefaultCounter,
      minLines: widget.lines,
      maxLines: widget.lines,
      style: AppTypography.body1,
      cursorColor: AppColors.gray900,
      decoration: InputDecoration.collapsed(
        hintText: widget.placeholder,
        hintStyle: AppTypography.body1.copyWith(color: AppColors.gray400),
      ),
    );

    final maxLength = widget.maxLength;
    if (widget.lines == 1) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding),
        alignment: Alignment.centerLeft,
        decoration: _decoration,
        child: field,
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: _decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field,
          if (maxLength != null) ...[
            const SizedBox(height: AppSpacing.inside),
            ValueListenableBuilder(
              valueListenable: _controller,
              builder: (_, value, _) => Text(
                '${value.text.characters.length} / $maxLength',
                style: AppTypography.caption,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static const _decoration = BoxDecoration(
    color: AppColors.gray50,
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.control)),
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.gray200, width: 1.5),
    ),
  );

  static Widget? _hideDefaultCounter(
    BuildContext context, {
    required int currentLength,
    required int? maxLength,
    required bool isFocused,
  }) => null;
}

import 'package:flutter/material.dart';

import '../models/rating.dart';
import '../models/reinspection_category.dart';
import '../viewmodels/reinspection_view_model.dart';

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
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: '닫기',
            onPressed: widget.onClose,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text('어떤 정보가 달랐나요?', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('확인 후 결과를 공간 상세에 알려 드려요', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in ReinspectionCategory.values)
                  FilterChip(
                    label: Text(c.label),
                    selected: _vm.isSelected(c),
                    onSelected: (_) => _vm.toggle(c),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              maxLines: 5,
              maxLength: reinspectionDetailMaxLength,
              decoration: InputDecoration(
                labelText: '상세 내용',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _vm.updateDetail,
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              onPressed: _vm.canSubmit ? _submit : null,
              child: const Text('요청 보내기'),
            ),
          ),
        ),
      ),
    );
  }
}

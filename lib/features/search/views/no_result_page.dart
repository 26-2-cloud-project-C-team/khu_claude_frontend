import 'package:flutter/material.dart';

import '../models/search_result.dart';
import '../viewmodels/no_result_view_model.dart';
import 'widgets/option_tile.dart';

/// US-05 결과 없음 · 조건 변경 대안.
class NoResultPage extends StatefulWidget {
  const NoResultPage({
    super.key,
    required this.viewModel,
    required this.onAdopt,
    required this.onRestart,
  });

  final NoResultViewModel viewModel;

  /// 고른 대안으로 다시 검색한 결과. SearchFlowViewModel.adopt 후 US-04(1위부터)로 보낸다.
  final ValueChanged<SearchResult> onAdopt;

  /// '처음부터 다시 설정': 조건 초기화 후 US-00으로.
  final VoidCallback onRestart;

  @override
  State<NoResultPage> createState() => _NoResultPageState();
}

class _NoResultPageState extends State<NoResultPage> {
  NoResultViewModel get _vm => widget.viewModel;

  Future<void> _adopt() async {
    final result = await _vm.adopt();
    // 실패하면 버튼만 다시 켠다. 통신 오류 재시도 안내는 설계(DS-00 ②)에서 뺐다.
    if (mounted && result != null) widget.onAdopt(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final count = _vm.selectedCount;
        return Scaffold(
          appBar: AppBar(),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text('조건에 맞는 공간이 없어요', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('조건을 하나만 바꾸면 찾을 수 있어요', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 24),
              for (var i = 0; i < _vm.alternatives.length; i++)
                OptionTile(
                  label: _vm.alternatives[i].alternative.label,
                  selected: _vm.selectedIndex == i,
                  onTap: () => _vm.select(i),
                  trailing: Badge(
                    label: Text('${_vm.alternatives[i].count}곳'),
                    backgroundColor: _vm.selectedIndex == i
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                    onPressed: _vm.canSubmit ? _adopt : null,
                    child: Text(count == null ? '후보 보기' : '$count곳 보기'),
                  ),
                  TextButton(onPressed: widget.onRestart, child: const Text('처음부터 다시 설정')),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

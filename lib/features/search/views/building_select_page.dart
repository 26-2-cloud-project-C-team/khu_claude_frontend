import 'package:flutter/material.dart';

import '../../../core/models/building.dart';
import '../../../core/utils/geo.dart';
import '../models/origin.dart';
import '../viewmodels/search_flow_view_model.dart';

// TODO(A-10): 건물 목록·검색 위젯이 core에 들어오면 목록 부분을 그쪽으로 바꾼다.

/// US-03 출발 건물 선택. 행을 탭하면 확인 없이 출발점이 되고 다음 단계로 간다.
class BuildingSelectPage extends StatefulWidget {
  const BuildingSelectPage({
    super.key,
    required this.viewModel,
    required this.locationUnavailable,
    required this.onSelected,
    required this.onLocated,
    required this.onBack,
  });

  final SearchFlowViewModel viewModel;

  /// true면 A(위치를 가져올 수 없을 때), false면 B(다른 건물에서 출발).
  final bool locationUnavailable;

  /// 건물을 골랐다. 검색 조건 퍼널의 인원 단계로 돌아간다.
  final VoidCallback onSelected;

  /// '허용하기' 후 위치를 얻었다. US-01 A(현재 위치 카드)로 돌아간다.
  final VoidCallback onLocated;
  final VoidCallback onBack;

  @override
  State<BuildingSelectPage> createState() => _BuildingSelectPageState();
}

class _BuildingSelectPageState extends State<BuildingSelectPage> {
  String _query = '';

  SearchFlowViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.loadBuildings();
  }

  Future<void> _allowLocation() async {
    await _vm.locate();
    if (mounted && _vm.originStatus == OriginStatus.located) widget.onLocated();
  }

  List<Building> _filtered() {
    final q = _query.trim();
    final list = [
      for (final b in _vm.buildings)
        if (q.isEmpty || b.name.contains(q)) b,
    ]..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '뒤로',
          onPressed: widget.onBack,
        ),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final buildings = _filtered();
          final origin = _vm.condition.origin;
          final here = origin is CurrentLocationOrigin ? origin.point : null;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
            children: [
              Text(
                widget.locationUnavailable ? '어느 건물에서 출발하시나요?' : '출발할 건물을 선택해주세요',
                style: theme.textTheme.headlineSmall,
              ),
              if (widget.locationUnavailable) ...[
                const SizedBox(height: 4),
                Text('현재 위치를 가져올 수 없어요', style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 24),
              if (widget.locationUnavailable) ...[
                Container(
                  height: 52,
                  padding: const EdgeInsets.only(left: 16, right: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off_outlined, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text('위치 권한이 필요해요', style: theme.textTheme.bodyMedium)),
                      TextButton(
                        onPressed: _vm.originStatus == OriginStatus.locating ? null : _allowLocation,
                        child: const Text('허용하기'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                decoration: InputDecoration(
                  hintText: '건물 이름 검색',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 24),
              Text('전체 건물 · 가나다순', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              if (_vm.buildings.isEmpty && !_vm.buildingsFailed)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              for (final b in buildings)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  minTileHeight: 56,
                  title: Text(b.name),
                  trailing: here == null
                      ? null
                      : Text('직선 ${distanceMeters(here, b.point).round()}m',
                          style: theme.textTheme.bodySmall),
                  onTap: () {
                    _vm.chooseBuilding(b);
                    widget.onSelected();
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/models/building.dart';
import '../../search/models/candidate.dart';
import '../models/directions_stage.dart';
import '../viewmodels/directions_view_model.dart';

/// US-06 지도 길찾기(A) · 건물 도착 내부 안내(B) · 이용 중(C), 복구 · 출발점 없음(②).
class DirectionsPage extends StatefulWidget {
  const DirectionsPage({
    super.key,
    required this.viewModel,
    required this.onChooseOrigin,
    required this.onReview,
    required this.onReinspect,
    required this.onClose,
  });

  final DirectionsViewModel viewModel;

  /// 출발 건물 선택(US-03)을 띄우고 고른 건물을 돌려준다. 닫으면 null.
  /// 복구로 들어와 현재 위치를 못 구했을 때 한 번, ②의 '출발 건물 골라서 길찾기'에서 다시 연다.
  final Future<Building?> Function() onChooseOrigin;

  /// C '이용 의견 남기기' → US-07 A(모달).
  final VoidCallback onReview;

  /// C '정보가 달라요' → US-07 C(모달).
  final VoidCallback onReinspect;

  /// 닫기 → US-00.
  final VoidCallback onClose;

  @override
  State<DirectionsPage> createState() => _DirectionsPageState();
}

class _DirectionsPageState extends State<DirectionsPage> {
  DirectionsViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.start().then((_) {
      // 복구로 들어와 현재 위치도 없으면 US-03을 먼저 띄운다. 닫으면 ②(핀만 있는 지도)에 남는다.
      if (mounted && _vm.lacksOrigin) _chooseOrigin();
    });
  }

  Future<void> _chooseOrigin() async {
    final building = await widget.onChooseOrigin();
    if (!mounted || building == null) return;
    await _vm.chooseOrigin(building);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        if (_vm.stage == DirectionsStage.inUse) {
          return _InUseView(
            destination: _vm.destination,
            onReview: widget.onReview,
            onReinspect: widget.onReinspect,
            onClose: widget.onClose,
          );
        }
        final destination = _vm.destination.buildingName;
        return Scaffold(
          appBar: AppBar(
            title: Text(_vm.stage == DirectionsStage.moving ? '길찾기' : '내부 안내'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: '닫기',
              onPressed: widget.onClose,
            ),
          ),
          body: Column(
            children: [
              // TODO(A-12): 카카오맵 래퍼로 바꾼다. 현재 위치 = 경희블루 점, 목적지 = 경희레드 핀,
              // 경로 = 경희레드 선. 진입 시 출발점·목적지가 모두 보이게 범위를 맞춘다.
              // ②(lacksOrigin)는 경로선 · 현재 위치 점 · '현재 위치로' 버튼 없이 목적지 핀과 Tint 건물만,
              // 목적지 건물이 가운데 오도록 맞춘다.
              Expanded(
                child: Container(
                  key: const ValueKey('map-placeholder'),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Text(
                    _vm.lacksOrigin ? destination : '${_vm.originLabel ?? '현재 위치'} → $destination',
                  ),
                ),
              ),
              if (_vm.isResolvingOrigin)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                _RouteSheet(viewModel: _vm, onChooseOrigin: _chooseOrigin),
            ],
          ),
        );
      },
    );
  }
}

/// A·B·②가 함께 쓰는 경로 요약 시트. 단계 라벨 → 제목 → 보조 한 줄 → 목적지 카드 → Primary → 텍스트 버튼.
class _RouteSheet extends StatelessWidget {
  const _RouteSheet({required this.viewModel, required this.onChooseOrigin});

  final DirectionsViewModel viewModel;
  final VoidCallback onChooseOrigin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = viewModel;
    final d = vm.destination;
    final moving = vm.stage == DirectionsStage.moving;
    final route = vm.route;

    // ②는 경로 단계가 없어 단계 라벨을 '내부 안내'(회색)로, 도착 여부를 몰라 보조 줄은 건물 이름만 둔다.
    final noOrigin = vm.lacksOrigin;
    final label = moving ? '1/2 · 이동 중' : (noOrigin ? '내부 안내' : '2/2 · 건물 도착');
    final labelColor = moving
        ? theme.colorScheme.primary
        : (noOrigin ? theme.colorScheme.onSurfaceVariant : Colors.green.shade700);
    final title = moving
        ? (vm.isApproaching
              ? '곧 도착해요'
              : '${d.buildingName}까지 도보 ${route?.minutes ?? d.walkMinutes}분')
        : '${d.floor}으로 올라가세요';
    final sub = moving
        ? (route == null
              ? null
              : '${route.isFallback ? '직선' : '걷는 길'} ${route.distanceMeters.round()}m')
        : (noOrigin ? d.buildingName : '${d.buildingName}에 도착했어요');

    return Material(
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label, style: theme.textTheme.labelLarge?.copyWith(color: labelColor)),
              const SizedBox(height: 4),
              Text(title, style: theme.textTheme.titleLarge),
              if (sub != null) ...[
                const SizedBox(height: 4),
                Text(sub, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
              DestinationCard(destination: d),
              if (!moving) _BeforeArrival(destination: d),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                onPressed: moving ? vm.arriveAtBuilding : vm.startUsing,
                child: Text(moving ? '건물에 도착했어요' : '공간에 도착했어요'),
              ),
              // ②에는 길 안내가 이미 없으므로 '길 안내 없이' 대신 길 안내를 되찾는 길을 둔다.
              noOrigin
                  ? TextButton(onPressed: onChooseOrigin, child: const Text('출발 건물 골라서 길찾기'))
                  : TextButton(onPressed: vm.startUsing, child: const Text('길 안내 없이 바로 이용하기')),
            ],
          ),
        ),
      ),
    );
  }
}

/// 목적지 카드(썸네일 · 층 공간명 · 상세 위치). A·B·C 공용.
class DestinationCard extends StatelessWidget {
  const DestinationCard({super.key, required this.destination});

  final CandidateDetail destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = destination.photos.isEmpty ? null : destination.photos.first.url;
    final placeholder = Container(
      width: 56,
      height: 56,
      color: theme.colorScheme.surfaceContainerHighest,
    );
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: photo == null
                  ? placeholder
                  : Image.network(
                      photo,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => placeholder,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(destination.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(destination.locationGuide, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeforeArrival extends StatelessWidget {
  const _BeforeArrival({required this.destination});

  final CandidateDetail destination;

  @override
  Widget build(BuildContext context) {
    final tagged = [
      for (final p in destination.photos)
        if (p.tag != null) p,
    ];
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('도착 전에 확인해주세요'),
      children: [
        if (tagged.isNotEmpty)
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tagged.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      tagged[i].url,
                      width: 96,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(width: 96, height: 72),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(tagged[i].tag!.label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        if (destination.note != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(alignment: Alignment.centerLeft, child: Text(destination.note!)),
          ),
      ],
    );
  }
}

class _InUseView extends StatelessWidget {
  const _InUseView({
    required this.destination,
    required this.onReview,
    required this.onReinspect,
    required this.onClose,
  });

  final CandidateDetail destination;
  final VoidCallback onReview;
  final VoidCallback onReinspect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = destination;
    return Scaffold(
      appBar: AppBar(
        title: const Text('이용 중'),
        leading: IconButton(icon: const Icon(Icons.close), tooltip: '닫기', onPressed: onClose),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
        children: [
          Text('공간 도착', style: theme.textTheme.labelLarge?.copyWith(color: Colors.green.shade700)),
          const SizedBox(height: 4),
          Text(d.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('${d.floor} · ${d.locationGuide}', style: theme.textTheme.bodyMedium),
          if (d.closesAt != null) ...[
            const SizedBox(height: 12),
            Text('오늘 ${d.closesAt}까지 이용 가능', style: theme.textTheme.bodyLarge),
          ],
          if (d.note != null) ...[
            const SizedBox(height: 4),
            Text(d.note!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 32),
          Text('의견을 남겨주시면 다음 사람에게 도움이 돼요', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              title: const Text('이용 의견 남기기'),
              subtitle: const Text('별점과 한마디'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onReview,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              title: const Text('정보가 달라요'),
              subtitle: const Text('재조사 요청'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onReinspect,
            ),
          ),
          const SizedBox(height: 24),
          Text('닫으면 처음 화면으로 돌아가요', textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

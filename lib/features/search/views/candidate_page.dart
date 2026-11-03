import 'package:flutter/material.dart';

import '../models/candidate.dart';
import '../models/search_condition.dart';
import '../viewmodels/candidate_view_model.dart';
import 'widgets/condition_sheet.dart';

/// 복구하려던 공간이 비공개 · 삭제됐을 때(U3 404) US-00에서 띄우는 토스트(DS-00 ②).
const spaceUnavailableMessage = '지금은 볼 수 없는 공간이에요';

/// US-04 후보 상세. 순위대로 한 곳씩 보여주고 좌우로 넘긴다.
class CandidatePage extends StatefulWidget {
  const CandidatePage({
    super.key,
    required this.viewModel,
    required SearchCondition this.condition,
    required this.onClose,
    required ValueChanged<SearchStep> this.onEditStep,
    required this.onGo,
    required this.onOpenPhoto,
  }) : onUnavailable = null;

  /// US-04 ③ 복구 상태. [CandidateViewModel.restored]를 받는다.
  /// 순위 · 조건 · 거리 · 다음 후보 미리보기는 검색 결과에서만 나오는 값이라 숨긴다.
  const CandidatePage.restored({
    super.key,
    required this.viewModel,
    required this.onClose,
    required this.onGo,
    required VoidCallback this.onUnavailable,
    required this.onOpenPhoto,
  }) : condition = null,
       onEditStep = null;

  final CandidateViewModel viewModel;

  /// 조건 시트에 보여줄 이번 검색 조건. 복구 상태에서는 null.
  final SearchCondition? condition;

  /// ×: 검색 결과를 닫고 US-00으로. 복구 상태의 '처음부터 다시 찾기'와 좌우 스와이프도 같다.
  final VoidCallback onClose;

  /// 조건 시트에서 항목을 골랐다. 그 단계로 돌아가 다시 찾는다.
  final ValueChanged<SearchStep>? onEditStep;

  /// '여기로 갈게요': 이 후보로 길찾기(US-06) 시작.
  /// 복구 상태에서는 출발점이 없으므로 US-06이 현재 위치 → US-03 순으로 다시 구한다.
  final ValueChanged<CandidateDetail> onGo;

  /// 복구하려던 공간을 볼 수 없다(U3 404). US-00으로 보내며 [spaceUnavailableMessage] 토스트.
  final VoidCallback? onUnavailable;

  /// 사진 크게 보기(A-11).
  final void Function(CandidateDetail candidate, int index) onOpenPhoto;

  @override
  State<CandidatePage> createState() => _CandidatePageState();
}

class _CandidatePageState extends State<CandidatePage> {
  final _scroll = ScrollController();
  int _shownRank = 1;

  CandidateViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onChanged);
    _vm.load();
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_vm.isUnavailable) {
      widget.onUnavailable?.call();
      return;
    }
    // 다른 순위로 넘기면 스크롤은 맨 위에서 다시 시작한다.
    if (_vm.rank != _shownRank) {
      _shownRank = _vm.rank;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  Future<void> _openConditions() async {
    final condition = widget.condition;
    if (condition == null) return;
    final step = await showConditionSheet(context, condition);
    if (step != null) widget.onEditStep?.call(step);
  }

  void _onSwipe(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v.abs() <= 200) return;
    // 복구 상태에는 이전 · 다음 후보가 없어 좌우 스와이프도 닫기와 같다.
    if (_vm.isRestored) {
      widget.onClose();
    } else if (v < 0) {
      _vm.next();
    } else {
      _vm.previous();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final current = _vm.current;
        final restored = _vm.isRestored;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: '닫기',
              onPressed: widget.onClose,
            ),
            centerTitle: true,
            title: restored
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        tooltip: '이전 후보',
                        onPressed: _vm.hasPrevious ? _vm.previous : null,
                      ),
                      Text('${_vm.rank}위'),
                      Text(' / ${_vm.total}곳', style: Theme.of(context).textTheme.bodyMedium),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        tooltip: '다음 후보',
                        onPressed: _vm.hasNext ? _vm.next : null,
                      ),
                    ],
                  ),
            actions: restored
                ? null
                : [TextButton(onPressed: _openConditions, child: const Text('조건'))],
          ),
          body: current == null
              ? _Loading(viewModel: _vm)
              : GestureDetector(
                  onHorizontalDragEnd: _onSwipe,
                  child: _CandidateBody(
                    candidate: current,
                    restored: restored,
                    controller: _scroll,
                    onOpenPhoto: (i) => widget.onOpenPhoto(current, i),
                    onRestart: widget.onClose,
                  ),
                ),
          bottomNavigationBar: current == null
              ? null
              : _BottomArea(
                  viewModel: _vm,
                  onGo: () => widget.onGo(current),
                  onChangeConditions: _openConditions,
                ),
        );
      },
    );
  }
}

/// US-04 ③ 상단 바 아래 · 사진 위의 안내 띠. 복구 상태에서만 보인다.
class _RestoredBanner extends StatelessWidget {
  const _RestoredBanner({required this.onRestart});

  /// '처음부터 다시 찾기' → US-00.
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('검색 조건이 사라져서 공간 정보만 보여 드려요', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          InkWell(
            onTap: onRestart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '처음부터 다시 찾기',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 복구 중 U3를 기다리는 동안만 보인다.
/// 볼 수 없는 공간이면 곧 US-00으로 넘어가고, 통신 오류 재시도는 설계(DS-00 ②)에서 빼서 비워 둔다.
class _Loading extends StatelessWidget {
  const _Loading({required this.viewModel});

  final CandidateViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (!viewModel.isLoading) return const SizedBox.shrink();
    return const Center(child: CircularProgressIndicator());
  }
}

class _CandidateBody extends StatelessWidget {
  const _CandidateBody({
    required this.candidate,
    required this.restored,
    required this.controller,
    required this.onOpenPhoto,
    required this.onRestart,
  });

  final CandidateDetail candidate;

  /// 복구 상태면 안내 띠를 두고, 출발점이 없어 도보 시간 · 직선거리는 뺀다.
  final bool restored;
  final ScrollController controller;
  final ValueChanged<int> onOpenPhoto;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = candidate;
    final note = c.note == null ? null : (c.isCafe ? '카페 · ${c.note}' : c.note);
    return ListView(
      controller: controller,
      children: [
        if (restored) _RestoredBanner(onRestart: onRestart),
        _PhotoHeader(candidate: c, onTap: () => onOpenPhoto(0)),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                restored
                    ? c.buildingName
                    : '${c.buildingName} · 도보 ${c.walkMinutes}분 · 직선 ${c.distanceMeters.round()}m',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(c.availableNow ? '지금 이용 가능' : '지금 이용 불가')),
                  Chip(label: Text(_ratingText(c))),
                ],
              ),
              const SizedBox(height: 24),
              _InfoRow('이용 시간', c.opensAt == null ? '오늘 휴무' : '오늘 ${c.opensAt} – ${c.closesAt}'),
              _InfoRow('테이블', '${c.tableCount}개 · 최대 ${c.maxPerTable}명'),
              _InfoRow('충전', '충전되는 테이블 ${c.chargeablePercent}%'),
              _InfoRow('와이파이', c.freeWifi ? '무료' : '없음'),
              _InfoRow('분위기', c.noise.label),
              if (note != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(note, style: theme.textTheme.bodyMedium),
                ),
              ],
              if (c.pros != null || c.cons != null) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ProsConsCard(title: '좋아요', text: c.pros ?? '-'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ProsConsCard(title: '아쉬워요', text: c.cons ?? '-'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const _SectionBand(),
        _Section(
          title: '내부 위치 찾기',
          children: [
            Text(c.floor, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(c.locationGuide, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < c.photos.length; i++)
                  if (c.photos[i].tag != null)
                    ActionChip(
                      label: Text(c.photos[i].tag!.label),
                      onPressed: () => onOpenPhoto(i),
                    ),
              ],
            ),
          ],
        ),
        const _SectionBand(),
        _Section(
          title: '이용 의견',
          children: [
            Text(_ratingText(c), style: theme.textTheme.titleMedium),
            for (final r in c.recentReviews) ...[
              const SizedBox(height: 16),
              Text(
                '${'★' * r.rating}${'☆' * (5 - r.rating)} · ${formatDate(r.createdAt)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(r.text ?? '별점만 남겼어요', style: theme.textTheme.bodyMedium),
            ],
            for (final a in c.answers) ...[
              const SizedBox(height: 24),
              Text('Q. ${a.question}', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text('${formatDate(a.checkedAt)} 재확인', style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text('A. ${a.answer}', style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ],
    );
  }

  static String _ratingText(CandidateDetail c) => c.ratingAverage == null
      ? '평가 없음'
      : '★ ${c.ratingAverage!.toStringAsFixed(1)} (${c.ratingCount})';
}

// TODO(A-08): 날짜 포맷 유틸이 core에 들어오면 그쪽으로 바꾼다.
String formatDate(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.candidate, required this.onTap});

  final CandidateDetail candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photos = candidate.photos;
    final placeholder = Container(color: Theme.of(context).colorScheme.surfaceContainerHighest);
    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photos.isEmpty)
            placeholder
          else
            GestureDetector(
              onTap: onTap,
              child: Image.network(
                photos.first.url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              ),
            ),
          if (photos.isNotEmpty)
            Positioned(right: 12, bottom: 12, child: Chip(label: Text('1 / ${photos.length}'))),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: theme.textTheme.bodySmall)),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: theme.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _ProsConsCard extends StatelessWidget {
  const _ProsConsCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(text, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _SectionBand extends StatelessWidget {
  const _SectionBand();

  @override
  Widget build(BuildContext context) =>
      Container(height: 8, color: Theme.of(context).colorScheme.surfaceContainerHighest);
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _BottomArea extends StatelessWidget {
  const _BottomArea({
    required this.viewModel,
    required this.onGo,
    required this.onChangeConditions,
  });

  final CandidateViewModel viewModel;
  final VoidCallback onGo;
  final VoidCallback onChangeConditions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = viewModel.nextPreview;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 복구 상태에는 다음 후보가 없어 '여기로 갈게요' 하나만 둔다.
            if (!viewModel.isRestored) ...[
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: viewModel.isLast
                    ? ListTile(
                        title: const Text('마지막 후보예요'),
                        subtitle: const Text('조건 바꿔서 다시 찾기'),
                        trailing: const Icon(Icons.tune),
                        onTap: onChangeConditions,
                      )
                    : ListTile(
                        title: Text(
                          '다음 후보 · ${viewModel.rank + 1}위',
                          style: theme.textTheme.bodySmall,
                        ),
                        subtitle: Text(
                          preview == null
                              ? '불러오는 중'
                              : '${preview.name} · 도보 ${preview.walkMinutes}분',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: viewModel.next,
                      ),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              onPressed: onGo,
              child: const Text('여기로 갈게요'),
            ),
          ],
        ),
      ),
    );
  }
}

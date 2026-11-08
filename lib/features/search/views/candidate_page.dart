import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_rating.dart';
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
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _TopBar(viewModel: _vm, onClose: widget.onClose, onOpenConditions: _openConditions),
                Expanded(
                  child: current == null
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
                ),
                if (current != null)
                  _BottomArea(
                    viewModel: _vm,
                    onGo: () => widget.onGo(current),
                    onChangeConditions: _openConditions,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 상단 바. 왼쪽 닫기(×) · 가운데 '‹ 1위 / 12곳 ›' · 오른쪽 '조건'.
/// 복구 상태에는 순위와 조건이 검색 결과에서만 나오는 값이라 닫기만 둔다.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.viewModel, required this.onClose, required this.onOpenConditions});

  final CandidateViewModel viewModel;
  final VoidCallback onClose;
  final VoidCallback onOpenConditions;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.screenHorizontal - 10),
          _IconTap(icon: Icons.close, label: '닫기', onTap: onClose),
          Expanded(
            child: vm.isRestored
                ? const SizedBox.shrink()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _IconTap(
                        icon: Icons.chevron_left,
                        label: '이전 후보',
                        onTap: vm.hasPrevious ? vm.previous : null,
                      ),
                      Text('${vm.rank}위', style: AppTypography.h3),
                      Text(
                        ' / ${vm.total}곳',
                        style: AppTypography.body2.copyWith(color: AppColors.gray500),
                      ),
                      _IconTap(
                        icon: Icons.chevron_right,
                        label: '다음 후보',
                        onTap: vm.hasNext ? vm.next : null,
                      ),
                    ],
                  ),
          ),
          if (vm.isRestored)
            const SizedBox(width: 44 + AppSpacing.screenHorizontal - 10)
          else
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.screenHorizontal - 10),
              child: TextButton(
                onPressed: onOpenConditions,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.gray900,
                  textStyle: AppTypography.body2,
                  minimumSize: const Size(44, 44),
                ),
                child: const Text('조건'),
              ),
            ),
        ],
      ),
    );
  }
}

/// 터치 영역 44의 아이콘 버튼. [onTap]이 null이면 회색으로 비활성한다.
class _IconTap extends StatelessWidget {
  const _IconTap({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: onTap != null,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: SizedBox.square(
            dimension: 44,
            child: Icon(
              icon,
              size: 24,
              color: onTap == null ? AppColors.gray300 : AppColors.gray900,
            ),
          ),
        ),
      ),
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
    final action = AppTypography.body2.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
    );
    return Container(
      width: double.infinity,
      color: AppColors.gray50,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        14,
        AppSpacing.screenHorizontal,
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '검색 조건이 사라져서 공간 정보만 보여 드려요',
            style: AppTypography.body2.copyWith(color: AppColors.gray600),
          ),
          InkWell(
            onTap: onRestart,
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('처음부터 다시 찾기', style: action),
                  const Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
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
    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
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
    final c = candidate;
    final note = c.note == null ? null : (c.isCafe ? '카페 · ${c.note}' : c.note);
    final average = c.ratingAverage;
    return ListView(
      controller: controller,
      children: [
        if (restored) _RestoredBanner(onRestart: onRestart),
        _PhotoHeader(candidate: c, onTap: () => onOpenPhoto(0)),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.cardPadding,
            AppSpacing.screenHorizontal,
            AppSpacing.belowTitle,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.name, style: AppTypography.h2),
              const SizedBox(height: AppSpacing.textLine),
              Text(
                // 복구 상태(U3)에는 출발점이 없어 도보 시간 · 직선거리가 오지 않는다.
                restored || c.walkMinutes == null
                    ? c.buildingName
                    : '${c.buildingName} · 도보 ${c.walkMinutes}분 · 직선 ${c.distanceMeters}m',
                style: AppTypography.body2.copyWith(color: AppColors.gray700),
              ),
              const SizedBox(height: AppSpacing.between),
              Wrap(
                spacing: AppSpacing.inside,
                children: [
                  c.availableNow
                      ? const AppBadge(label: '지금 이용 가능', tone: AppBadgeTone.positive)
                      : const AppBadge(label: '지금 이용 불가'),
                  if (average == null)
                    const AppBadge(label: '평가 없음')
                  else
                    AppRatingBadge(average: average, count: c.ratingCount),
                ],
              ),
              const SizedBox(height: AppSpacing.item),
              _InfoRow('이용 시간', '오늘 ${formatHours(c.opensAt, c.closesAt)}'),
              _InfoRow('테이블', '${c.tableCount}개 · 최대 ${c.maxPerTable}명'),
              _InfoRow('충전', '충전되는 테이블 ${c.chargeablePercent}%'),
              _InfoRow('와이파이', c.freeWifi ? '무료' : '없음'),
              _InfoRow('분위기', c.noise.label),
              if (note != null) ...[
                const SizedBox(height: AppSpacing.between),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.between),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: Text(note, style: AppTypography.body2.copyWith(color: AppColors.gray700)),
                ),
              ],
              if (c.pros != null || c.cons != null) ...[
                const SizedBox(height: AppSpacing.between),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ProsConsCard(title: '좋아요', text: c.pros ?? '-'),
                    ),
                    const SizedBox(width: AppSpacing.between),
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
            Text(c.floorLabel, style: AppTypography.h3),
            const SizedBox(height: AppSpacing.textLine),
            Text(c.locationGuide, style: AppTypography.body2.copyWith(color: AppColors.gray700)),
            const SizedBox(height: AppSpacing.between),
            Wrap(
              spacing: AppSpacing.inside,
              runSpacing: AppSpacing.inside,
              children: [
                for (var i = 0; i < c.photos.length; i++)
                  if (c.photos[i].tag != null)
                    AppChip(
                      label: c.photos[i].tag!.label,
                      selected: false,
                      onTap: () => onOpenPhoto(i),
                    ),
              ],
            ),
          ],
        ),
        const _SectionBand(),
        _Section(
          title: '이용 의견',
          trailing: average == null
              ? null
              : AppRatingSummary(average: average, count: c.ratingCount),
          children: [
            for (final r in c.recentReviews) ...[
              Row(
                children: [
                  AppStars(rating: r.rating),
                  const SizedBox(width: AppSpacing.textLine),
                  Text(
                    '· ${formatDate(r.createdAt)}',
                    style: AppTypography.caption.copyWith(color: AppColors.gray500),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.textLine),
              Text(
                r.text ?? '별점만 남겼어요',
                // 빈 값은 회색 한 줄로 둔다(DS-00 ② 3).
                style: AppTypography.body2.copyWith(
                  color: r.text == null ? AppColors.gray500 : AppColors.gray900,
                ),
              ),
              const SizedBox(height: AppSpacing.cardPadding),
            ],
            for (final a in c.results) ...[
              const SizedBox(height: AppSpacing.inside),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q. ${a.categories.map((c) => c.label).join(' · ')} 제보',
                      style: AppTypography.body2,
                    ),
                    const SizedBox(height: AppSpacing.textLine),
                    Text(
                      '${formatDate(a.resolvedAt)} 재확인',
                      style: AppTypography.caption.copyWith(color: AppColors.gray500),
                    ),
                    const SizedBox(height: AppSpacing.textLine),
                    Text(
                      'A. ${a.result}',
                      style: AppTypography.body2.copyWith(color: AppColors.gray700),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.candidate, required this.onTap});

  final CandidateDetail candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photos = candidate.photos;
    final placeholder = Container(color: AppColors.gray100);
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
            Positioned(
              right: AppSpacing.between,
              bottom: AppSpacing.between,
              child: AppBadge(label: '1 / ${photos.length}', tone: AppBadgeTone.plain),
            ),
        ],
      ),
    );
  }
}

/// 왼쪽 항목명(14, Gray 500) · 오른쪽 값(15).
class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppTypography.body2.copyWith(color: AppColors.gray500)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.body1.copyWith(color: AppColors.gray900),
            ),
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.label.copyWith(color: AppColors.gray600)),
          const SizedBox(height: AppSpacing.textLine),
          Text(text, style: AppTypography.body2.copyWith(color: AppColors.gray900)),
        ],
      ),
    );
  }
}

/// 구획을 나누는 8px 회색 띠.
class _SectionBand extends StatelessWidget {
  const _SectionBand();

  @override
  Widget build(BuildContext context) => Container(height: 8, color: AppColors.gray100);
}

/// 구획 제목은 모두 H3(17/600).
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.trailing});

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.belowTitle,
        AppSpacing.screenHorizontal,
        AppSpacing.section,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTypography.h3)),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.cardPadding),
          ...children,
        ],
      ),
    );
  }
}

/// 하단 고정 영역. 다음 후보 미리보기 카드(높이 64, 연회색 바탕, 테두리 없음)와 Primary '여기로 갈게요'.
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
    final preview = viewModel.nextPreview;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.cardPadding,
        AppSpacing.screenHorizontal,
        34,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 복구 상태에는 다음 후보가 없어 '여기로 갈게요' 하나만 둔다.
          if (!viewModel.isRestored) ...[
            if (viewModel.isLast)
              _PreviewCard(title: '마지막 후보예요', subtitle: '조건 바꿔서 다시 찾기', onTap: onChangeConditions)
            else if (preview != null)
              _PreviewCard(
                title: '다음 후보 · ${viewModel.rank + 1}위',
                subtitle: preview.name,
                trailing: '도보 ${preview.walkMinutes}분',
                onTap: viewModel.next,
              ),
            const SizedBox(height: AppSpacing.between),
          ],
          AppButton(label: '여기로 갈게요', onPressed: onGo),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return Material(
      color: AppColors.gray50,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.caption.copyWith(color: AppColors.gray500)),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body1.copyWith(color: AppColors.gray900),
                      ),
                    ],
                  ),
                ),
                if (trailing != null)
                  Text(trailing, style: AppTypography.body2.copyWith(color: AppColors.gray700)),
                const Icon(Icons.chevron_right, size: 20, color: AppColors.gray400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

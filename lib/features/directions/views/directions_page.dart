import 'package:flutter/material.dart';

import '../../../core/models/building.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_screen_parts.dart';
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
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _TitleBar(
                  title: _vm.stage == DirectionsStage.moving ? '길찾기' : '내부 안내',
                  onClose: widget.onClose,
                ),
                // TODO(A-12): 카카오맵 래퍼로 바꾼다. 현재 위치 = 경희블루 점, 목적지 = 경희레드 핀,
                // 경로 = 경희레드 선. 진입 시 출발점·목적지가 모두 보이게 범위를 맞춘다.
                // ②(lacksOrigin)는 경로선 · 현재 위치 점 · '현재 위치로' 버튼 없이 목적지 핀과 Tint 건물만,
                // 목적지 건물이 가운데 오도록 맞춘다.
                Expanded(
                  child: Container(
                    key: const ValueKey('map-placeholder'),
                    color: AppColors.gray100,
                    alignment: Alignment.center,
                    child: Text(
                      _vm.lacksOrigin
                          ? destination
                          : '${_vm.originLabel ?? '현재 위치'} → $destination',
                      style: AppTypography.body2.copyWith(color: AppColors.gray600),
                    ),
                  ),
                ),
                if (_vm.isResolvingOrigin)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.section),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                else
                  _RouteSheet(viewModel: _vm, onChooseOrigin: _chooseOrigin),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 위쪽 줄. 왼쪽 닫기(×) · 가운데 제목(H3).
class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.screenHorizontal - 10),
          Semantics(
            label: '닫기',
            button: true,
            child: Tooltip(
              message: '닫기',
              child: InkWell(
                onTap: onClose,
                customBorder: const CircleBorder(),
                splashFactory: NoSplash.splashFactory,
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                child: const SizedBox.square(
                  dimension: 44,
                  child: Icon(Icons.close, size: 24, color: AppColors.gray900),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(title, textAlign: TextAlign.center, style: AppTypography.h3),
          ),
          const SizedBox(width: 44 + AppSpacing.screenHorizontal - 10),
        ],
      ),
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
    final vm = viewModel;
    final d = vm.destination;
    final moving = vm.stage == DirectionsStage.moving;
    final route = vm.route;

    // ②는 경로 단계가 없어 단계 라벨을 '내부 안내'(회색)로, 도착 여부를 몰라 보조 줄은 건물 이름만 둔다.
    final noOrigin = vm.lacksOrigin;
    final label = moving ? '1/2 · 이동 중' : (noOrigin ? '내부 안내' : '2/2 · 건물 도착');
    final labelColor = moving
        ? AppColors.primary
        : (noOrigin ? AppColors.gray500 : AppColors.positive);
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

    // 안의 '도착 전에 확인해주세요'가 Material에 그려지도록 시트 바탕도 Material로 둔다.
    return Material(
      color: AppColors.white,
      elevation: 8,
      shadowColor: AppColors.gray900.withValues(alpha: 0.2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.screenHorizontal,
              AppSpacing.screenHorizontal,
              0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(label, style: AppTypography.label.copyWith(color: labelColor)),
                const SizedBox(height: AppSpacing.textLine),
                Text(title, style: AppTypography.h2),
                if (sub != null) ...[
                  const SizedBox(height: AppSpacing.textLine),
                  Text(sub, style: AppTypography.body2.copyWith(color: AppColors.gray700)),
                ],
                const SizedBox(height: AppSpacing.cardPadding),
                DestinationCard(destination: d, highlighted: !moving),
                if (!moving) _BeforeArrival(destination: d),
              ],
            ),
          ),
          // AppCtaArea가 좌우 여백 20 · 아래 34를 직접 둔다.
          AppCtaArea(
            label: moving ? '건물에 도착했어요' : '공간에 도착했어요',
            onPressed: moving ? vm.arriveAtBuilding : vm.startUsing,
            // ②에는 길 안내가 이미 없으므로 '길 안내 없이' 대신 길 안내를 되찾는 길을 둔다.
            secondaryLabel: noOrigin ? '출발 건물 골라서 길찾기' : '길 안내 없이 바로 이용하기',
            onSecondaryPressed: noOrigin ? onChooseOrigin : vm.startUsing,
          ),
        ],
      ),
    );
  }
}

/// 목적지 카드(썸네일 · 층 공간명 · 상세 위치). A·B·C 공용.
/// [highlighted]면 건물 도착 후라 Primary Tint로 강조한다.
class DestinationCard extends StatelessWidget {
  const DestinationCard({super.key, required this.destination, this.highlighted = false});

  final CandidateDetail destination;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final photo = destination.photos.isEmpty ? null : destination.photos.first.url;
    final placeholder = Container(width: 56, height: 56, color: AppColors.gray100);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.between),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primaryTint : AppColors.gray50,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.control),
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
          const SizedBox(width: AppSpacing.between),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(destination.name, style: AppTypography.h3),
                const SizedBox(height: AppSpacing.textLine),
                Text(
                  destination.locationGuide,
                  style: AppTypography.body2.copyWith(color: AppColors.gray700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// '도착 전에 확인해주세요'. 입구 · 가는 길 · 내부 사진과 비고를 접어 두고 탭하면 펼친다.
class _BeforeArrival extends StatelessWidget {
  const _BeforeArrival({required this.destination});

  final CandidateDetail destination;

  @override
  Widget build(BuildContext context) {
    final tagged = [
      for (final p in destination.photos)
        if (p.tag != null) p,
    ];
    final note = destination.note;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        iconColor: AppColors.gray500,
        collapsedIconColor: AppColors.gray500,
        title: Text('도착 전에 확인해주세요', style: AppTypography.body1.copyWith(color: AppColors.gray900)),
        children: [
          if (tagged.isNotEmpty)
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tagged.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.inside),
                itemBuilder: (context, i) => Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      child: Image.network(
                        tagged[i].url,
                        width: 96,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Container(width: 96, height: 72, color: AppColors.gray100),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.textLine),
                    Text(
                      tagged[i].tag!.label,
                      style: AppTypography.caption.copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
            ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.inside),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(note, style: AppTypography.body2.copyWith(color: AppColors.gray700)),
              ),
            ),
        ],
      ),
    );
  }
}

/// C 이용 중. CTA 없이 텍스트 행 2개만 둔다.
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
    final d = destination;
    final note = d.note;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TitleBar(title: '이용 중', onClose: onClose),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.inside,
                  AppSpacing.screenHorizontal,
                  34,
                ),
                children: [
                  Text('공간 도착', style: AppTypography.label.copyWith(color: AppColors.positive)),
                  const SizedBox(height: AppSpacing.textLine),
                  Text(d.name, style: AppTypography.h1),
                  const SizedBox(height: AppSpacing.textLine),
                  Text(
                    '${d.floor} · ${d.locationGuide}',
                    style: AppTypography.body2.copyWith(color: AppColors.gray700),
                  ),
                  if (d.closesAt != null) ...[
                    const SizedBox(height: AppSpacing.between),
                    Text(
                      '오늘 ${d.closesAt}까지 이용 가능',
                      style: AppTypography.body1.copyWith(color: AppColors.gray900),
                    ),
                  ],
                  if (note != null) ...[
                    const SizedBox(height: AppSpacing.textLine),
                    Text(note, style: AppTypography.body2.copyWith(color: AppColors.gray700)),
                  ],
                  const SizedBox(height: AppSpacing.section),
                  const Text('의견을 남겨주시면 다음 사람에게 도움이 돼요', style: AppTypography.h3),
                  const SizedBox(height: AppSpacing.between),
                  _FeedbackRow(title: '이용 의견 남기기', subtitle: '별점과 한마디', onTap: onReview),
                  const SizedBox(height: AppSpacing.between),
                  _FeedbackRow(title: '정보가 달라요', subtitle: '재조사 요청', onTap: onReinspect),
                  const SizedBox(height: AppSpacing.item),
                  Text(
                    '닫으면 처음 화면으로 돌아가요',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(color: AppColors.gray500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({required this.title, required this.subtitle, required this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                      Text(title, style: AppTypography.body1.copyWith(color: AppColors.gray900)),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.caption.copyWith(color: AppColors.gray500),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20, color: AppColors.gray400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

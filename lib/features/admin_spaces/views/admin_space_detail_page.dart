import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/reinspection_category.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/admin_space_repository.dart';
import '../models/admin_space_activity.dart';
import '../models/admin_space_detail.dart';
import '../models/admin_space_edit_section.dart';
import '../models/reinspection_request.dart';
import '../models/selected_space_photo.dart';
import '../viewmodels/admin_space_detail_view_model.dart';
import '../viewmodels/admin_space_list_view_model.dart';

class AdminSpaceDetailPage extends StatelessWidget {
  const AdminSpaceDetailPage({
    super.key,
    required this.spaceId,
    required this.onBack,
  });

  final String spaceId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AdminSpaceDetailViewModel(
        repository: context.read<AdminSpaceRepository>(),
        spaceId: spaceId,
      )..load(),
      child: _AdminSpaceDetailView(spaceId: spaceId, onBack: onBack),
    );
  }
}

class _AdminSpaceDetailView extends StatefulWidget {
  const _AdminSpaceDetailView({required this.spaceId, required this.onBack});

  final String spaceId;
  final VoidCallback onBack;

  @override
  State<_AdminSpaceDetailView> createState() => _AdminSpaceDetailViewState();
}

class _AdminSpaceDetailViewState extends State<_AdminSpaceDetailView> {
  bool _isReviewingRequests = false;
  late final TextEditingController _resolutionController;

  @override
  void initState() {
    super.initState();
    _resolutionController = TextEditingController();
  }

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: '뒤로',
          onPressed: _isReviewingRequests
              ? () => setState(() => _isReviewingRequests = false)
              : widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          _isReviewingRequests ? '재조사 요청 처리' : '공간 상세',
          style: AppTypography.h2,
        ),
        centerTitle: false,
      ),
      body: Consumer<AdminSpaceDetailViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.detail == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (viewModel.errorMessage != null && viewModel.detail == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      viewModel.errorMessage!,
                      style: AppTypography.body1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.item),
                    AppButton(
                      label: '다시 불러오기',
                      variant: AppButtonVariant.secondary,
                      onPressed: viewModel.isLoading ? null : viewModel.load,
                    ),
                  ],
                ),
              ),
            );
          }

          final detail = viewModel.detail;
          if (detail == null) {
            return const Center(child: Text('공간 정보를 찾을 수 없습니다.'));
          }

          final pendingRequests = detail.reinspectionRequests
              .where((request) => !request.isResolved)
              .toList(growable: false);

          return Column(
            children: [
              Expanded(
                child: _isReviewingRequests
                    ? _ReinspectionReviewBody(
                        requests: pendingRequests,
                        resultController: _resolutionController,
                      )
                    : _SpaceDetailBody(
                        detail: detail,
                        pendingRequests: pendingRequests,
                        isUpdating: viewModel.isUpdating,
                        onVisibilityChanged: _updateVisibility,
                        onOpenRequests: () {
                          _resolutionController.clear();
                          setState(() => _isReviewingRequests = true);
                        },
                        onEditSection: (section) =>
                            _editSection(viewModel, section),
                      ),
              ),
              if (_isReviewingRequests && pendingRequests.isNotEmpty)
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _resolutionController,
                  builder: (context, value, _) => _BottomAction(
                    label: '확인 결과 공개하기',
                    isLoading: viewModel.isUpdating,
                    onPressed: viewModel.isUpdating || value.text.trim().isEmpty
                        ? null
                        : () => _completeReinspection(viewModel),
                  ),
                )
              else if (!_isReviewingRequests && pendingRequests.isNotEmpty)
                _BottomAction(
                  label: '재조사 요청 처리하기',
                  onPressed: () => setState(() => _isReviewingRequests = true),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editSection(
    AdminSpaceDetailViewModel viewModel,
    AdminSpaceEditSection section,
  ) async {
    final result = await context.push<bool>(
      '/admin/spaces/${widget.spaceId}/edit?section=${section.name}',
    );
    if (!mounted || result != true) return;

    await viewModel.load();
    if (!mounted) return;
    await context.read<AdminSpaceListViewModel>().load();
  }

  Future<void> _updateVisibility(bool value) async {
    final viewModel = context.read<AdminSpaceDetailViewModel>();
    final success = await viewModel.updateVisibility(value);
    if (!mounted) return;

    if (success) {
      await context.read<AdminSpaceListViewModel>().load();
      _showMessage(
        value ? '공개 상태로 변경했어요.' : '비공개 상태로 변경했어요.',
        actionLabel: '되돌리기',
        onAction: () => _updateVisibility(!value),
      );
    } else {
      _showMessage(viewModel.errorMessage ?? '공개 상태 변경에 실패했습니다.');
    }
  }

  Future<void> _completeReinspection(
    AdminSpaceDetailViewModel viewModel,
  ) async {
    final result = _resolutionController.text.trim();
    if (result.isEmpty) {
      _showMessage('사용자에게 공개할 확인 결과를 입력해주세요.');
      return;
    }

    final success = await viewModel.resolveAllReinspections(result: result);
    if (!mounted) return;

    if (success) {
      await context.read<AdminSpaceListViewModel>().load();
      setState(() => _isReviewingRequests = false);
      _showMessage('재조사 요청 처리가 완료되었습니다.');
    } else {
      _showMessage(viewModel.errorMessage ?? '재조사 요청 처리에 실패했습니다.');
    }
  }

  void _showMessage(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          action: actionLabel != null && onAction != null
              ? SnackBarAction(label: actionLabel, onPressed: onAction)
              : null,
        ),
      );
  }
}

class _SpaceDetailBody extends StatelessWidget {
  const _SpaceDetailBody({
    required this.detail,
    required this.pendingRequests,
    required this.isUpdating,
    required this.onVisibilityChanged,
    required this.onOpenRequests,
    required this.onEditSection,
  });

  final AdminSpaceDetail detail;
  final List<ReinspectionRequest> pendingRequests;
  final bool isUpdating;
  final ValueChanged<bool> onVisibilityChanged;
  final VoidCallback onOpenRequests;
  final ValueChanged<AdminSpaceEditSection> onEditSection;

  @override
  Widget build(BuildContext context) {
    final space = detail.space;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        16,
        AppSpacing.screenHorizontal,
        AppSpacing.section,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(space.name, style: AppTypography.h2),
          const SizedBox(height: 4),
          Text(
            space.location,
            style: AppTypography.body2.copyWith(color: AppColors.gray600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          _SpacePhotoStrip(photos: detail.photos),
          const SizedBox(height: 16),
          _VisibilityCard(
            isPublic: space.isPublic,
            isUpdating: isUpdating,
            onChanged: onVisibilityChanged,
          ),
          const SizedBox(height: 12),
          if (pendingRequests.isNotEmpty)
            _ReinspectionSummaryCard(
              requests: pendingRequests,
              onTap: onOpenRequests,
            )
          else
            _NoReinspectionCard(detail: detail),
          const SizedBox(height: AppSpacing.section),
          Text('공간 정보', style: AppTypography.h3),
          const SizedBox(height: 8),
          _SpaceInformationCard(detail: detail, onEditSection: onEditSection),
          const SizedBox(height: AppSpacing.section),
          Text('작업 이력', style: AppTypography.h3),
          const SizedBox(height: 8),
          _ActivityHistoryCard(activities: detail.activities),
        ],
      ),
    );
  }
}

class _SpacePhotoStrip extends StatelessWidget {
  const _SpacePhotoStrip({required this.photos});

  final List<SelectedSpacePhoto> photos;

  static const _requiredPhotoLabels = ['입구', '가는 길', '내부'];

  @override
  Widget build(BuildContext context) {
    final slots = <Widget>[];

    for (var index = 0; index < 3; index++) {
      final photo = index < photos.length ? photos[index] : null;
      slots.add(
        _PhotoThumbnail(
          photo: photo,
          label: _requiredPhotoLabels[index],
          onTap: photo == null ? null : () => _openViewer(context, index),
        ),
      );
    }

    for (var index = 3; index < photos.length; index++) {
      final photo = photos[index];
      slots.add(
        _PhotoThumbnail(
          photo: photo,
          label: '추가',
          onTap: () => _openViewer(context, index),
        ),
      );
    }

    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: slots.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => slots[index],
      ),
    );
  }

  void _openViewer(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        pageBuilder: (_, _, _) =>
            _AdminPhotoViewer(photos: photos, initialIndex: initialIndex),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.photo,
    required this.label,
    required this.onTap,
  });

  final SelectedSpacePhoto? photo;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gray100,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 108,
          height: 81,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photo == null)
                const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.gray400,
                  size: 24,
                )
              else
                Image.memory(
                  photo!.bytes,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.gray400,
                  ),
                ),
              Positioned(
                left: 8,
                bottom: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.gray900.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    child: Text(
                      label,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminPhotoViewer extends StatefulWidget {
  const _AdminPhotoViewer({required this.photos, required this.initialIndex});

  final List<SelectedSpacePhoto> photos;
  final int initialIndex;

  @override
  State<_AdminPhotoViewer> createState() => _AdminPhotoViewerState();
}

class _AdminPhotoViewerState extends State<_AdminPhotoViewer> {
  late final PageController _pageController = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tag = _index < 3
        ? _SpacePhotoStrip._requiredPhotoLabels[_index]
        : '추가 사진';

    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (_, index) => InteractiveViewer(
                child: Center(
                  child: Image.memory(
                    widget.photos[index].bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.gray400,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 4,
              child: IconButton(
                tooltip: '닫기',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppColors.white),
              ),
            ),
            Positioned(
              top: 18,
              left: 0,
              right: 0,
              child: Text(
                '${_index + 1} / ${widget.photos.length}',
                textAlign: TextAlign.center,
                style: AppTypography.body1.copyWith(color: AppColors.white),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Text(
                tag,
                textAlign: TextAlign.center,
                style: AppTypography.body1.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityCard extends StatelessWidget {
  const _VisibilityCard({
    required this.isPublic,
    required this.isUpdating,
    required this.onChanged,
  });

  final bool isPublic;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '공개 상태',
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text('끄면 사용자 앱에서 바로 사라져요.', style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: isPublic,
            onChanged: isUpdating ? null : onChanged,
            activeTrackColor: AppColors.positive,
          ),
        ],
      ),
    );
  }
}

class _ReinspectionSummaryCard extends StatelessWidget {
  const _ReinspectionSummaryCard({required this.requests, required this.onTap});

  final List<ReinspectionRequest> requests;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final latestRequest = requests.reduce(
      (a, b) => a.requestedAt.isAfter(b.requestedAt) ? a : b,
    );
    final categoryCounts = <ReinspectionCategory, int>{};
    for (final request in requests) {
      categoryCounts.update(
        request.category,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final representative = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mainCategory = representative.first;
    final remainingCount = requests.length - mainCategory.value;

    return Material(
      color: AppColors.primaryTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.primary, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '재조사 요청 ${requests.length}건',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${mainCategory.key.label} ${mainCategory.value}건'
                      '${remainingCount > 0 ? ' 외 $remainingCount건' : ''} · '
                      '최근 ${formatDate(latestRequest.requestedAt)}',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.primary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoReinspectionCard extends StatelessWidget {
  const _NoReinspectionCard({required this.detail});

  final AdminSpaceDetail detail;

  @override
  Widget build(BuildContext context) {
    final resolved = detail.reinspectionRequests
        .where((request) => request.isResolved && request.resolvedAt != null)
        .map((request) => request.resolvedAt!)
        .toList();
    resolved.sort((a, b) => b.compareTo(a));

    return AppCard(
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.positive,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('처리할 재조사 요청이 없어요', style: AppTypography.h3),
                const SizedBox(height: 4),
                Text(
                  resolved.isEmpty
                      ? '새 요청이 접수되면 여기에 표시돼요.'
                      : '최근 처리 ${formatDate(resolved.first)}',
                  style: AppTypography.body2.copyWith(color: AppColors.gray500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceInformationCard extends StatelessWidget {
  const _SpaceInformationCard({
    required this.detail,
    required this.onEditSection,
  });

  final AdminSpaceDetail detail;
  final ValueChanged<AdminSpaceEditSection> onEditSection;

  @override
  Widget build(BuildContext context) {
    final hours = detail.is24Hours
        ? '00:00 – 24:00'
        : '${_formatMinute(detail.startMinute)} – ${_formatMinute(detail.endMinute)}';
    final useSummary = '$hours · ${detail.noiseLevel}';
    final facilitySummary =
        '${detail.tableCount}개 · 최대 ${detail.maxPeoplePerTable}명';
    final noteSummary = detail.memo.isNotEmpty
        ? detail.memo
        : detail.goodPoints.isNotEmpty
        ? detail.goodPoints
        : detail.badPoints;

    return AppCard(
      child: Column(
        children: [
          _SpaceInformationRow(
            label: '위치',
            value: detail.space.location,
            onTap: () => onEditSection(AdminSpaceEditSection.location),
          ),
          const _InformationDivider(),
          _SpaceInformationRow(
            label: '사진',
            value: '${detail.photos.length}장',
            onTap: () => onEditSection(AdminSpaceEditSection.photos),
          ),
          const _InformationDivider(),
          _SpaceInformationRow(
            label: '이용 규칙과 소음',
            value: useSummary,
            maxLines: 1,
            onTap: () => onEditSection(AdminSpaceEditSection.rules),
          ),
          const _InformationDivider(),
          _SpaceInformationRow(
            label: '테이블과 시설',
            value: facilitySummary,
            maxLines: 1,
            onTap: () => onEditSection(AdminSpaceEditSection.facilities),
          ),
          const _InformationDivider(),
          _SpaceInformationRow(
            label: '현장에서 느낀 점',
            value: noteSummary.isEmpty ? '등록된 메모가 없어요.' : noteSummary,
            maxLines: 1,
            onTap: () => onEditSection(AdminSpaceEditSection.fieldSurvey),
          ),
        ],
      ),
    );
  }
}

class _SpaceInformationRow extends StatelessWidget {
  const _SpaceInformationRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.maxLines = 3,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  label,
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 6,
                child: Text(
                  value,
                  style: AppTypography.body2.copyWith(color: AppColors.gray600),
                  textAlign: TextAlign.right,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: AppColors.gray400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InformationDivider extends StatelessWidget {
  const _InformationDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: AppColors.gray200);
}

class _ActivityHistoryCard extends StatelessWidget {
  const _ActivityHistoryCard({required this.activities});

  final List<AdminSpaceActivity> activities;

  @override
  Widget build(BuildContext context) {
    final initialSurvey =
        activities.where((activity) => activity.title == '최초 조사').toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final latestEdit =
        activities.where((activity) => activity.title == '최근 수정').toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    // 공개 전환 로그는 별도로 보존하고, 화면에는 최초 조사와 최근 수정만 표시한다.
    final visibleActivities = [
      if (initialSurvey.isNotEmpty) initialSurvey.first,
      if (latestEdit.isNotEmpty) latestEdit.first,
    ];

    if (visibleActivities.isEmpty) {
      return const AppCard(
        child: Text('등록된 작업 이력이 없어요.', style: AppTypography.body2),
      );
    }

    return AppCard(
      child: Column(
        children: [
          for (var index = 0; index < visibleActivities.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visibleActivities[index].title,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.gray900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (visibleActivities[index].description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          visibleActivities[index].description,
                          style: AppTypography.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 124,
                  child: Text(
                    '${formatDate(visibleActivities[index].createdAt)} · '
                    '${visibleActivities[index].actor}',
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            if (index != visibleActivities.length - 1)
              const Divider(height: 20, color: AppColors.gray200),
          ],
        ],
      ),
    );
  }
}

class _ReinspectionReviewBody extends StatelessWidget {
  const _ReinspectionReviewBody({
    required this.requests,
    required this.resultController,
  });

  final List<ReinspectionRequest> requests;
  final TextEditingController resultController;

  @override
  Widget build(BuildContext context) {
    final sortedRequests = [...requests]
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    final groupedRequests = <ReinspectionCategory, List<ReinspectionRequest>>{};
    for (final request in sortedRequests) {
      groupedRequests.putIfAbsent(request.category, () => []).add(request);
    }
    final categories = ReinspectionCategory.values
        .where(groupedRequests.containsKey)
        .toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        20,
        AppSpacing.screenHorizontal,
        AppSpacing.section,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('현장 확인 결과를 알려주세요', style: AppTypography.h1),
          const SizedBox(height: 8),
          Text(
            '사용자 제보 ${sortedRequests.length}건',
            style: AppTypography.body2.copyWith(color: AppColors.gray600),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                for (var index = 0; index < sortedRequests.length; index++) ...[
                  _ReinspectionRequestRow(request: sortedRequests[index]),
                  if (index != sortedRequests.length - 1)
                    const Divider(height: 20, color: AppColors.gray200),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          Text('고칠 곳', style: AppTypography.h3),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                for (var index = 0; index < categories.length; index++) ...[
                  _CategoryRequestRow(
                    category: categories[index],
                    requests: groupedRequests[categories[index]]!,
                  ),
                  if (index != categories.length - 1)
                    const Divider(height: 1, color: AppColors.gray200),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          Text('확인 결과 (사용자에게 공개)', style: AppTypography.h3),
          const SizedBox(height: 8),
          AppTextField(
            controller: resultController,
            placeholder: '현장에서 확인한 내용과 수정한 정보를 입력해주세요.',
            maxLength: 200,
            lines: 4,
          ),
          const SizedBox(height: 12),
          Text(
            '확인 결과를 공개하면 현재 접수된 미처리 요청이 모두 완료 처리됩니다.',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}

class _ReinspectionRequestRow extends StatelessWidget {
  const _ReinspectionRequestRow({required this.request});

  final ReinspectionRequest request;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(request.category.label, style: AppTypography.h3),
          const SizedBox(height: 4),
          Text(
            request.message.trim().isEmpty
                ? '내용 없이 항목만 골랐어요.'
                : request.message,
            style: AppTypography.body1,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              formatDate(request.requestedAt),
              style: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRequestRow extends StatelessWidget {
  const _CategoryRequestRow({required this.category, required this.requests});

  final ReinspectionCategory category;
  final List<ReinspectionRequest> requests;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(
        category.label,
        style: AppTypography.body1.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${requests.length}건', style: AppTypography.body2),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.gray400),
        ],
      ),
      children: [
        for (final request in requests)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                request.message.trim().isEmpty
                    ? '내용 없이 항목만 골랐어요.'
                    : request.message,
                style: AppTypography.body2.copyWith(color: AppColors.gray600),
              ),
            ),
          ),
      ],
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: SizedBox(
          width: double.infinity,
          child: AppButton(
            label: isLoading ? '처리 중...' : label,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

String _formatMinute(int minute) {
  final safeMinute = minute.clamp(0, 1440).toInt();
  final hour = safeMinute == 1440 ? 24 : safeMinute ~/ 60;
  final minutes = safeMinute == 1440 ? 0 : safeMinute % 60;
  final formattedHour = hour.toString().padLeft(2, '0');
  final formattedMinute = minutes.toString().padLeft(2, '0');
  return '$formattedHour:$formattedMinute';
}

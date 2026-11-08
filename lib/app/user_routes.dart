import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/location/location_repository.dart';
import '../core/models/building.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/building_list.dart';
import '../core/widgets/photo_viewer.dart';
import '../features/directions/data/directions_repository.dart';
import '../features/directions/viewmodels/directions_view_model.dart';
import '../features/directions/views/directions_page.dart';
import '../features/feedback/data/feedback_repository.dart';
import '../features/feedback/viewmodels/reinspection_view_model.dart';
import '../features/feedback/viewmodels/review_view_model.dart';
import '../features/feedback/views/done_page.dart';
import '../features/feedback/views/reinspection_page.dart';
import '../features/feedback/views/review_page.dart';
import '../features/search/data/search_repository.dart';
import '../features/search/models/candidate.dart';
import '../features/search/models/origin.dart';
import '../features/search/viewmodels/candidate_view_model.dart';
import '../features/search/viewmodels/no_result_view_model.dart';
import '../features/search/viewmodels/search_flow_view_model.dart';
import '../features/search/views/building_select_page.dart';
import '../features/search/views/candidate_page.dart';
import '../features/search/views/no_result_page.dart';
import '../features/search/views/search_steps_page.dart';
import '../features/search/views/start_page.dart';
import 'router.dart';

/// 사용자 화면 전체가 공유하는 [SearchFlowViewModel]. 사용자 `ShellRoute`가 처음 그려질 때 만든다.
///
/// redirect는 ShellRoute 바깥 context에서 돌기 때문에 Provider 대신 이 객체로 '검색 조건이 남아 있는지'를 본다.
/// 새로고침하면 Router와 함께 새로 만들어져 비어 있다.
class SearchFlowHolder {
  SearchFlowViewModel? value;

  /// ShellRoute 안에서만 부른다.
  SearchFlowViewModel get flow => value!;

  SearchFlowViewModel ensure(BuildContext context) => value ??= SearchFlowViewModel(
    searchRepository: context.read<SearchRepository>(),
    locationRepository: context.read<LocationRepository>(),
  );
}

/// 길찾기(US-06) · 의견(US-07)으로 넘기는 값. 검색 조건이 없는 복구 진입이면 [origin]이 null이다.
class DirectionsArgs {
  const DirectionsArgs({required this.space, this.origin});

  final CandidateDetail space;
  final Origin? origin;
}

/// 사용자 화면(US-00~08) 경로. `router.dart`의 사용자 `ShellRoute` 안에 들어간다.
///
/// 검색 조건과 결과는 [SearchFlowViewModel]이 들고 있어 URL에 담지 않는다. 새로고침으로 값이 사라진
/// 화면은 US-00으로 보내고, 공간 하나는 `/spaces/{spaceId}`(US-04 ③)로 복구한다.
List<RouteBase> userRoutes(SearchFlowHolder holder) {
  // 목적 없이 들어오면(새로고침) 처음부터 시작한다.
  String? needsCondition(BuildContext _, GoRouterState _) =>
      holder.value?.condition.purpose == null ? AppRoutes.start : null;
  String? needsArgs(BuildContext _, GoRouterState state) =>
      state.extra is DirectionsArgs ? null : AppRoutes.start;

  void restart(BuildContext context) {
    holder.value?.reset();
    context.go(AppRoutes.start);
  }

  void openPhotos(BuildContext context, CandidateDetail space, int index) =>
      showPhotoViewer(context: context, photos: space.photos, initialIndex: index);

  return [
    GoRoute(
      path: AppRoutes.start,
      builder: (context, _) =>
          StartPage(viewModel: holder.flow, onStarted: () => context.go(AppRoutes.search)),
    ),
    GoRoute(
      path: AppRoutes.search,
      redirect: needsCondition,
      builder: (context, _) => SearchStepsPage(
        viewModel: holder.flow,
        onExit: () => context.canPop() ? context.pop() : restart(context),
        onChooseBuilding: ({required bool locationUnavailable}) => context.push(
          Uri(
            path: AppRoutes.buildingSelect,
            queryParameters: {'unavailable': '$locationUnavailable'},
          ).toString(),
        ),
        onSearched: (result) =>
            context.go(result.isEmpty ? AppRoutes.noResult : AppRoutes.candidates),
      ),
    ),
    GoRoute(
      path: AppRoutes.buildingSelect,
      redirect: needsCondition,
      builder: (context, state) {
        final unavailable = state.uri.queryParameters['unavailable'] == 'true';
        void backToSearch() => context.canPop() ? context.pop() : context.go(AppRoutes.search);
        return BuildingSelectPage(
          viewModel: holder.flow,
          locationUnavailable: unavailable,
          onSelected: backToSearch,
          onLocated: backToSearch,
          onBack: () => unavailable ? restart(context) : backToSearch(),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.candidates,
      redirect: (_, _) {
        final result = holder.value?.lastResult;
        return result == null || result.isEmpty ? AppRoutes.start : null;
      },
      builder: (context, _) {
        final result = holder.flow.lastResult!;
        return ViewModelScope(
          // 결과가 바뀌면(조건 시트에서 다시 검색) 1위부터 새로 보여준다.
          key: ObjectKey(result),
          create: (_) => CandidateViewModel(result: result),
          builder: (context, vm) => CandidatePage(
            viewModel: vm,
            condition: result.condition,
            onClose: () => restart(context),
            onEditStep: (step) {
              holder.flow.editFromSheet(step);
              context.push(AppRoutes.search);
            },
            onGo: (space) => context.push(
              AppRoutes.directions,
              extra: DirectionsArgs(space: space, origin: result.condition.origin),
            ),
            onOpenPhoto: (space, index) => openPhotos(context, space, index),
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.noResult,
      redirect: (_, _) => holder.value?.lastResult == null ? AppRoutes.start : null,
      builder: (context, _) => ViewModelScope(
        create: (context) => NoResultViewModel(
          repository: context.read<SearchRepository>(),
          result: holder.flow.lastResult!,
        ),
        builder: (context, vm) => NoResultPage(
          viewModel: vm,
          onAdopt: (result) {
            holder.flow.adopt(result);
            context.go(result.isEmpty ? AppRoutes.noResult : AppRoutes.candidates);
          },
          onRestart: () => restart(context),
        ),
      ),
    ),
    GoRoute(
      path: '${AppRoutes.restore}/:spaceId',
      builder: (context, state) => ViewModelScope(
        key: ValueKey(state.pathParameters['spaceId']),
        create: (context) => CandidateViewModel.restored(
          repository: context.read<SearchRepository>(),
          spaceId: state.pathParameters['spaceId']!,
        ),
        builder: (context, vm) => CandidatePage.restored(
          viewModel: vm,
          onClose: () => restart(context),
          // 출발점은 저장하지 않으므로 US-06이 현재 위치 → US-03 순으로 다시 구한다.
          onGo: (space) => context.push(AppRoutes.directions, extra: DirectionsArgs(space: space)),
          onUnavailable: () {
            showAppToast(context, spaceUnavailableMessage);
            restart(context);
          },
          onOpenPhoto: (space, index) => openPhotos(context, space, index),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.directions,
      redirect: needsArgs,
      builder: (context, state) {
        final args = state.extra! as DirectionsArgs;
        return ViewModelScope(
          create: (context) => DirectionsViewModel(
            directionsRepository: context.read<DirectionsRepository>(),
            locationRepository: context.read<LocationRepository>(),
            origin: args.origin,
            destination: args.space,
          ),
          builder: (context, vm) => DirectionsPage(
            viewModel: vm,
            onChooseOrigin: () => _chooseOriginBuilding(context),
            onReview: () => context.push(AppRoutes.review, extra: args),
            onReinspect: () => context.push(AppRoutes.reinspection, extra: args),
            onClose: () => restart(context),
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.review,
      redirect: needsArgs,
      // 닫으면 입력값을 버리므로 열 때마다 새로 만든다(US-07 Check Point).
      pageBuilder: (context, state) {
        final args = state.extra! as DirectionsArgs;
        return MaterialPage(
          fullscreenDialog: true,
          child: ViewModelScope(
            create: (context) => ReviewViewModel(
              repository: context.read<FeedbackRepository>(),
              spaceId: args.space.spaceId,
            ),
            builder: (context, vm) => ReviewPage(
              viewModel: vm,
              spaceName: args.space.name,
              onDone: () => context.go(_done(DoneKind.review)),
              onClose: () => context.pop(),
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.reinspection,
      redirect: needsArgs,
      pageBuilder: (context, state) {
        final args = state.extra! as DirectionsArgs;
        return MaterialPage(
          fullscreenDialog: true,
          child: ViewModelScope(
            create: (context) => ReinspectionViewModel(
              repository: context.read<FeedbackRepository>(),
              spaceId: args.space.spaceId,
            ),
            builder: (context, vm) => ReinspectionPage(
              viewModel: vm,
              onDone: () => context.go(_done(DoneKind.reinspection)),
              onClose: () => context.pop(),
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.done,
      builder: (context, state) => DonePage(
        kind: state.uri.queryParameters['kind'] == DoneKind.reinspection.name
            ? DoneKind.reinspection
            : DoneKind.review,
        onConfirm: () => restart(context),
      ),
    ),
  ];
}

/// 페이지 하나가 쓰는 ViewModel을 그 페이지가 화면에 있는 동안만 들고 있다가 버린다.
///
/// 페이지는 ViewModel을 생성자로 받고 직접 구독한다. Provider로 감싸지 않는 것은 페이지가 `initState`에서
/// 바로 불러오기를 시작해 알림을 보내기 때문이다(Provider가 빌드 중 알림을 막는다).
class ViewModelScope<T extends ChangeNotifier> extends StatefulWidget {
  const ViewModelScope({super.key, required this.create, required this.builder});

  final T Function(BuildContext context) create;
  final Widget Function(BuildContext context, T viewModel) builder;

  @override
  State<ViewModelScope<T>> createState() => _ViewModelScopeState<T>();
}

class _ViewModelScopeState<T extends ChangeNotifier> extends State<ViewModelScope<T>> {
  late final T _viewModel = widget.create(context);

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _viewModel);
}

String _done(DoneKind kind) =>
    Uri(path: AppRoutes.done, queryParameters: {'kind': kind.name}).toString();

/// 복구 중 위치를 못 구했을 때 띄우는 출발 건물 선택(US-03). 고르지 않고 닫으면 null.
Future<Building?> _chooseOriginBuilding(BuildContext context) async {
  final List<Building> buildings;
  try {
    buildings = await context.read<SearchRepository>().fetchBuildings();
  } on Exception {
    return null;
  }
  if (!context.mounted) return null;
  return showBuildingSelectSheet(context: context, title: '출발할 건물을 선택해주세요', buildings: buildings);
}

/// DS-00 ② 토스트. 하단 CTA 위 · 3초 · 한 줄 · 높이 44 · 반경 12 · Gray 900 바탕 · Body2.
void showAppToast(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      content: Text(message, style: AppTypography.body2.copyWith(color: AppColors.white)),
      backgroundColor: AppColors.gray900,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        0,
        AppSpacing.screenHorizontal,
        56 + AppSpacing.cardPadding + 34,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.control)),
      ),
    ),
  );
}

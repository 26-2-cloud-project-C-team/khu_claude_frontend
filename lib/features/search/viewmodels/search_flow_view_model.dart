import 'package:flutter/foundation.dart';

import '../../../core/location/location_repository.dart';
import '../../../core/models/building.dart';
import '../../../core/models/purpose.dart';
import '../data/search_repository.dart';
import '../models/origin.dart';
import '../models/requirement.dart';
import '../models/search_condition.dart';
import '../models/search_result.dart';
import '../models/sort_key.dart';

enum OriginStatus {
  /// 아직 위치를 요청하지 않음.
  idle,
  locating,

  /// 현재 위치 카드(US-01 A)를 보여준다.
  located,

  /// 권한 없음·조회 실패. US-03 A(출발 건물 선택)로 바로 전환한다.
  unavailable,
}

/// 검색 조건 퍼널(US-00 → US-01 → US-03 → US-02) 상태.
///
/// 퍼널의 여러 페이지와 후보 상세(US-04)의 조건 시트, 결과 없음(US-05)이
/// 같은 인스턴스를 공유한다. 화면 이동은 View가 [step]과 메서드 반환값을 보고 처리한다.
class SearchFlowViewModel extends ChangeNotifier {
  SearchFlowViewModel({
    required SearchRepository searchRepository,
    required LocationRepository locationRepository,
  })  : _search = searchRepository,
        _location = locationRepository;

  final SearchRepository _search;
  final LocationRepository _location;

  SearchCondition _condition = const SearchCondition();
  SearchStep _step = SearchStep.origin;
  OriginStatus _originStatus = OriginStatus.idle;
  List<Building> _buildings = const [];
  bool _buildingsFailed = false;
  bool _isSearching = false;
  Object? _searchError;
  SearchResult? _lastResult;

  /// 조건 시트에서 들어온 단계. 여기서 뒤로 가면 퍼널을 닫고 후보 상세로 돌아간다.
  SearchStep? _editEntry;

  SearchCondition get condition => _condition;
  SearchStep get step => _step;
  OriginStatus get originStatus => _originStatus;
  List<Building> get buildings => _buildings;
  bool get buildingsFailed => _buildingsFailed;
  bool get isSearching => _isSearching;
  Object? get searchError => _searchError;
  SearchResult? get lastResult => _lastResult;
  bool get isEditing => _editEntry != null;

  /// 진행 바 칸을 채울지. 목적은 US-00에서 이미 골랐으면 처음부터 채운다.
  bool isStepFilled(SearchStep s) =>
      s.index <= _step.index || (s == SearchStep.purpose && _condition.purpose != null);

  /// 지금 단계의 Primary CTA 활성 여부. 필요 조건·정렬은 0개도 허용한다.
  bool get canProceed => switch (_step) {
        SearchStep.origin => _condition.origin != null,
        SearchStep.purpose => _condition.purpose != null,
        SearchStep.headcount || SearchStep.requirements || SearchStep.sort => true,
      };

  bool get canDecrementHeadcount => _condition.headcount > SearchCondition.minHeadcount;
  bool get canIncrementHeadcount => _condition.headcount < SearchCondition.maxHeadcount;

  // ── 진입·이동 ─────────────────────────────────────────

  /// US-00 목적 타일. 이전 조건을 버리고 목적만 고른 상태로 출발점 단계부터 시작한다.
  void startWithPurpose(Purpose purpose) {
    _condition = SearchCondition(purpose: purpose);
    _step = SearchStep.origin;
    _originStatus = OriginStatus.idle;
    _editEntry = null;
    _lastResult = null;
    _searchError = null;
    notifyListeners();
  }

  /// US-04 조건 시트에서 항목을 눌렀을 때. 그 단계부터 다시 진행한다.
  void editFromSheet(SearchStep step) {
    _step = step;
    _editEntry = step;
    notifyListeners();
  }

  /// 다음 단계로. 목적 단계는 조건 시트에서 고칠 때만 보인다.
  /// 마지막 단계(정렬)에서는 아무것도 하지 않는다. 그때는 [search]를 부른다.
  void next() {
    if (!canProceed) return;
    final following = _neighbor(_step, forward: true);
    if (following == null) return;
    _step = following;
    notifyListeners();
  }

  /// 이전 단계로. 값은 유지한다.
  /// false면 퍼널을 벗어나야 한다(첫 단계, 또는 조건 시트에서 들어온 단계).
  bool back() {
    if (_step == _editEntry) {
      _editEntry = null;
      return false;
    }
    final previous = _neighbor(_step, forward: false);
    if (previous == null) return false;
    _step = previous;
    notifyListeners();
    return true;
  }

  SearchStep? _neighbor(SearchStep from, {required bool forward}) {
    var i = from.index;
    while (true) {
      i += forward ? 1 : -1;
      if (i < 0 || i >= SearchStep.values.length) return null;
      final s = SearchStep.values[i];
      if (s != SearchStep.purpose) return s;
    }
  }

  // ── 출발점(US-01 A, US-03) ───────────────────────────────

  /// US-01 진입 직후 위치 권한을 요청하고 가장 가까운 건물을 찾는다.
  Future<void> locate() async {
    _originStatus = OriginStatus.locating;
    notifyListeners();

    LocationFix? fix;
    try {
      final permission = await _location.requestPermission();
      if (permission == LocationPermissionStatus.granted) {
        fix = await _location.currentFix();
      }
    } on Exception {
      fix = null;
    }

    final buildings = await loadBuildings();
    final nearest = fix == null ? null : nearestBuilding(fix.point, buildings);
    if (fix == null || nearest == null) {
      _originStatus = OriginStatus.unavailable;
    } else {
      _condition = _condition.copyWith(
        origin: CurrentLocationOrigin(fix: fix, nearestBuilding: nearest),
      );
      _originStatus = OriginStatus.located;
    }
    notifyListeners();
  }

  /// U1 건물 목록. 한 번 받으면 다시 부르지 않는다.
  Future<List<Building>> loadBuildings() async {
    if (_buildings.isNotEmpty) return _buildings;
    try {
      _buildings = await _search.fetchBuildings();
      _buildingsFailed = false;
    } on Exception {
      _buildingsFailed = true;
    }
    notifyListeners();
    return _buildings;
  }

  /// US-03 행 탭. 확인 없이 출발점으로 확정하고 다음 단계로 간다.
  void chooseBuilding(Building building) {
    _condition = _condition.copyWith(origin: BuildingOrigin(building));
    next();
  }

  // ── 목적·인원·필요 조건·정렬 ─────────────────────────────

  void selectPurpose(Purpose purpose) {
    _condition = _condition.copyWith(purpose: purpose);
    notifyListeners();
  }

  void incrementHeadcount() {
    if (!canIncrementHeadcount) return;
    _condition = _condition.copyWith(headcount: _condition.headcount + 1);
    notifyListeners();
  }

  void decrementHeadcount() {
    if (!canDecrementHeadcount) return;
    _condition = _condition.copyWith(headcount: _condition.headcount - 1);
    notifyListeners();
  }

  void toggleRequirement(Requirement r) {
    final next = {..._condition.requirements};
    if (!next.remove(r)) next.add(r);
    _condition = _condition.copyWith(requirements: next);
    notifyListeners();
  }

  void toggleSortKey(SortKey k) {
    final next = {..._condition.sortKeys};
    if (!next.remove(k)) next.add(k);
    _condition = _condition.copyWith(sortKeys: next);
    notifyListeners();
  }

  // ── 검색 ─────────────────────────────────────────────

  /// '공간 찾기'. 결과가 비었으면 US-05, 아니면 US-04(1위부터)로 View가 보낸다.
  /// 실패하면 null을 돌려주고 [searchError]를 채운다.
  Future<SearchResult?> search() async {
    if (!_condition.isComplete || _isSearching) return null;
    _isSearching = true;
    _searchError = null;
    notifyListeners();
    try {
      final result = await _search.search(_condition);
      _lastResult = result;
      _editEntry = null;
      return result;
    } on Exception catch (e) {
      _searchError = e;
      return null;
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// US-05에서 고른 대안의 결과를 그대로 쓴다. 이미 검색한 결과라 다시 부르지 않는다.
  void adopt(SearchResult result) {
    _condition = result.condition;
    _lastResult = result;
    notifyListeners();
  }

  /// US-05 '처음부터 다시 설정', US-04 닫기, US-08 확인.
  void reset() {
    _condition = const SearchCondition();
    _step = SearchStep.origin;
    _originStatus = OriginStatus.idle;
    _editEntry = null;
    _lastResult = null;
    _searchError = null;
    notifyListeners();
  }
}

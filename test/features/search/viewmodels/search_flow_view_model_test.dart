import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/location/location_repository.dart';
import 'package:team_frontend/core/models/purpose.dart';
import 'package:team_frontend/core/utils/geo.dart';
import 'package:team_frontend/features/search/models/origin.dart';
import 'package:team_frontend/features/search/models/requirement.dart';
import 'package:team_frontend/features/search/models/search_condition.dart';
import 'package:team_frontend/features/search/models/search_result.dart';
import 'package:team_frontend/features/search/models/sort_key.dart';
import 'package:team_frontend/features/search/viewmodels/search_flow_view_model.dart';

import '../../../fakes/fake_location_repository.dart';
import '../../../fakes/fake_search_repository.dart';
import '../../../fakes/sample_space.dart';

void main() {
  late FakeSearchRepository search;
  late FakeLocationRepository location;
  late SearchFlowViewModel vm;

  setUp(() {
    search = FakeSearchRepository(
      buildings: const [engineering, centralLibrary, lifeScience],
      onSearch: (_) => [1, 2, 3],
    );
    location = FakeLocationRepository(
      fix: LocationFix(point: engineering.point, accuracyMeters: 20),
    );
    vm = SearchFlowViewModel(searchRepository: search, locationRepository: location);
  });

  group('시작', () {
    test('목적 타일로 들어오면 목적이 채워지고 진행 바 2번째 칸도 채워진다', () {
      vm.startWithPurpose(Purpose.solo);

      expect(vm.condition.purpose, Purpose.solo);
      expect(vm.step, SearchStep.origin);
      expect(vm.isStepFilled(SearchStep.purpose), isTrue);
      expect(vm.isStepFilled(SearchStep.headcount), isFalse);
    });

    test('다시 시작하면 이전 조건을 버린다', () {
      vm.startWithPurpose(Purpose.solo);
      vm.incrementHeadcount();

      vm.startWithPurpose(Purpose.team);

      expect(vm.condition.headcount, SearchCondition.minHeadcount);
      expect(vm.condition.purpose, Purpose.team);
    });
  });

  group('출발점', () {
    test('위치를 얻으면 가장 가까운 건물로 현재 위치 출발점이 된다', () async {
      vm.startWithPurpose(Purpose.solo);

      await vm.locate();

      expect(vm.originStatus, OriginStatus.located);
      final origin = vm.condition.origin as CurrentLocationOrigin;
      expect(origin.nearestBuilding, engineering);
      expect(origin.fix.accuracyMeters, 20);
      expect(vm.canProceed, isTrue);
    });

    test('권한이 없으면 출발점 없이 unavailable이 된다', () async {
      location.permission = LocationPermissionStatus.denied;
      vm.startWithPurpose(Purpose.solo);

      await vm.locate();

      expect(vm.originStatus, OriginStatus.unavailable);
      expect(vm.condition.origin, isNull);
      expect(vm.canProceed, isFalse);
    });

    test('위치 조회가 null이면 unavailable이 된다', () async {
      location.fix = null;

      await vm.locate();

      expect(vm.originStatus, OriginStatus.unavailable);
    });

    test('건물 목록을 못 받아도 unavailable이다', () async {
      search.failBuildings = true;

      await vm.locate();

      expect(vm.originStatus, OriginStatus.unavailable);
      expect(vm.buildingsFailed, isTrue);
    });

    test('공개 공간이 있는 건물이 없어도(빈 목록) 받은 것으로 보고 다시 부르지 않는다', () async {
      search.buildings = const [];

      await vm.loadBuildings();
      await vm.loadBuildings();

      expect(vm.buildingsLoaded, isTrue);
      expect(vm.buildings, isEmpty);
      expect(search.buildingCalls, 1);
    });

    test('건물을 고르면 출발점이 되고 인원 단계로 간다 (목적 단계는 건너뛴다)', () {
      vm.startWithPurpose(Purpose.chat);

      vm.chooseBuilding(centralLibrary);

      expect(vm.condition.origin, BuildingOrigin(centralLibrary));
      expect(vm.step, SearchStep.headcount);
    });

    test('출발점이 없으면 다음으로 가지 않는다', () {
      vm.next();

      expect(vm.step, SearchStep.origin);
    });
  });

  group('단계 이동', () {
    test('뒤로 가도 값을 유지하고 목적 단계는 건너뛴다', () {
      vm.startWithPurpose(Purpose.team);
      vm.chooseBuilding(centralLibrary);
      vm.incrementHeadcount();

      final moved = vm.back();

      expect(moved, isTrue);
      expect(vm.step, SearchStep.origin);
      expect(vm.condition.headcount, 2);
      expect(vm.condition.origin, BuildingOrigin(centralLibrary));
    });

    test('첫 단계에서 뒤로 가면 false다 (View가 퍼널을 닫는다)', () {
      expect(vm.back(), isFalse);
    });

    test('조건 시트에서 들어온 단계에서 뒤로 가면 false다', () {
      vm.editFromSheet(SearchStep.requirements);

      expect(vm.isEditing, isTrue);
      expect(vm.back(), isFalse);
      expect(vm.isEditing, isFalse);
    });

    test('조건 시트에서 목적을 고치면 다음은 인원 단계다', () {
      vm.startWithPurpose(Purpose.solo);
      vm.editFromSheet(SearchStep.purpose);

      vm.selectPurpose(Purpose.team);
      vm.next();

      expect(vm.condition.purpose, Purpose.team);
      expect(vm.step, SearchStep.headcount);
    });

    test('마지막 단계에서 next는 아무것도 하지 않는다', () {
      vm.startWithPurpose(Purpose.solo);
      vm.chooseBuilding(centralLibrary);
      vm.next();
      vm.next();
      expect(vm.step, SearchStep.sort);

      vm.next();

      expect(vm.step, SearchStep.sort);
    });
  });

  group('인원·필요 조건·정렬', () {
    test('인원은 1~10명 범위를 벗어나지 않는다', () {
      vm.decrementHeadcount();
      expect(vm.condition.headcount, 1);
      expect(vm.canDecrementHeadcount, isFalse);

      for (var i = 0; i < 20; i++) {
        vm.incrementHeadcount();
      }
      expect(vm.condition.headcount, 10);
      expect(vm.canIncrementHeadcount, isFalse);
    });

    test('필요 조건과 정렬 기준은 토글된다', () {
      vm.toggleRequirement(Requirement.quiet);
      vm.toggleRequirement(Requirement.charging);
      vm.toggleRequirement(Requirement.quiet);
      vm.toggleSortKey(SortKey.distance);

      expect(vm.condition.requirements, {Requirement.charging});
      expect(vm.condition.sortKeys, {SortKey.distance});
    });

    test('0개 선택해도 다음으로 갈 수 있다', () {
      vm.startWithPurpose(Purpose.solo);
      vm.chooseBuilding(centralLibrary);
      vm.next();
      expect(vm.step, SearchStep.requirements);

      expect(vm.canProceed, isTrue);
    });
  });

  group('검색', () {
    void completeCondition() {
      vm.startWithPurpose(Purpose.solo);
      vm.chooseBuilding(centralLibrary);
    }

    test('조건이 완성되면 검색해서 결과를 돌려준다', () async {
      completeCondition();

      final result = await vm.search();

      expect(result!.candidates.map((c) => c.spaceId), ['1', '2', '3']);
      expect(search.searchCalls.single, vm.condition);
      expect(vm.lastResult, same(result));
      expect(vm.isSearching, isFalse);
    });

    test('출발점이나 목적이 없으면 검색하지 않는다', () async {
      final result = await vm.search();

      expect(result, isNull);
      expect(search.searchCalls, isEmpty);
    });

    test('실패하면 null을 돌려주고 오류를 남긴다', () async {
      completeCondition();
      search.failSearch = true;

      final result = await vm.search();

      expect(result, isNull);
      expect(vm.searchError, isNotNull);
      expect(vm.isSearching, isFalse);
    });

    test('adopt는 대안 결과의 조건을 현재 조건으로 쓴다', () async {
      completeCondition();
      final result = await vm.search();
      final changed = vm.condition.copyWith(headcount: 3);

      vm.adopt(SearchResult(condition: changed, candidates: result!.candidates));

      expect(vm.condition.headcount, 3);
    });

    test('reset은 모든 상태를 처음으로 돌린다', () async {
      completeCondition();
      await vm.search();

      vm.reset();

      expect(vm.condition, const SearchCondition());
      expect(vm.step, SearchStep.origin);
      expect(vm.lastResult, isNull);
    });
  });
}

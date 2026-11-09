import 'package:flutter/foundation.dart';

import '../data/admin_space_repository.dart';
import '../models/admin_space.dart';

enum AdminSpaceFilter { all, privateOnly, reinspection }

class AdminSpaceListViewModel extends ChangeNotifier {
  AdminSpaceListViewModel(this._repository);

  final AdminSpaceRepository _repository;

  List<AdminSpace> _spaces = [];
  String _searchQuery = '';
  AdminSpaceFilter _filter = AdminSpaceFilter.all;
  bool _isLoading = false;
  String? _errorMessage;

  List<AdminSpace> get spaces => _spaces;
  String get searchQuery => _searchQuery;
  AdminSpaceFilter get filter => _filter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalCount => _spaces.length;

  int get privateCount => _spaces.where((space) => !space.isPublic).length;

  int get reinspectionSpaceCount =>
      _spaces.where((space) => space.hasReinspectionRequest).length;

  List<AdminSpace> get visibleSpaces {
    final keyword = _searchQuery.trim().toLowerCase();

    final filtered = _spaces.where((space) {
      final matchesSearch =
          keyword.isEmpty ||
          space.name.toLowerCase().contains(keyword) ||
          space.location.toLowerCase().contains(keyword);

      final matchesFilter = switch (_filter) {
        AdminSpaceFilter.all => true,
        AdminSpaceFilter.privateOnly => !space.isPublic,
        AdminSpaceFilter.reinspection => space.hasReinspectionRequest,
      };

      return matchesSearch && matchesFilter;
    }).toList();

    // 백엔드가 재조사 요청 우선 및 오래된 수정 시각 순으로 정렬하므로
    // 클라이언트에서는 검색·필터만 적용하고 서버 순서를 유지한다.
    return filtered;
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _spaces = await _repository.fetchSpaces();
    } catch (_) {
      _errorMessage = '공간 목록을 불러오지 못했어요.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAfterCreate() async {
    _searchQuery = '';
    _filter = AdminSpaceFilter.all;
    notifyListeners();

    await load();
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  void setFilter(AdminSpaceFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }
}

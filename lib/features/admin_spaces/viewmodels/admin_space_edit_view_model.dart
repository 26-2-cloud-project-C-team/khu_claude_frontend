import 'package:flutter/foundation.dart';

import '../../../core/models/building.dart';
import '../data/admin_space_repository.dart';
import '../models/admin_space_detail.dart';

class AdminSpaceEditViewModel extends ChangeNotifier {
  factory AdminSpaceEditViewModel({
    required AdminSpaceRepository repository,
    required String spaceId,
  }) {
    return AdminSpaceEditViewModel._(repository, spaceId);
  }

  AdminSpaceEditViewModel._(
    this._repository,
    this._spaceId,
  );

  final AdminSpaceRepository _repository;
  final String _spaceId;

  AdminSpaceDetail? _detail;
  List<Building> _buildings = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  AdminSpaceDetail? get detail => _detail;
  List<Building> get buildings => _buildings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _detail = await _repository.fetchSpaceDetailById(_spaceId);
      if (_detail == null) _errorMessage = '공간 정보를 찾을 수 없습니다.';
    } catch (_) {
      _errorMessage = '공간 정보를 불러오지 못했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 위치 섹션의 건물 시트에 쓸 목록. 이미 받았으면 다시 부르지 않는다.
  Future<List<Building>> loadBuildings() async {
    if (_buildings.isNotEmpty) return _buildings;
    try {
      _buildings = await _repository.fetchBuildings();
    } catch (_) {
      _buildings = const [];
    }
    notifyListeners();
    return _buildings;
  }

  Future<bool> save(
    AdminSpaceDetail detail, {
    required String sectionLabel,
  }) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateSpaceDetail(
        _spaceId,
        detail,
        sectionLabel: sectionLabel,
      );
      _detail = await _repository.fetchSpaceDetailById(_spaceId);
      if (_detail == null) {
        throw StateError('저장된 공간 정보를 다시 불러오지 못했습니다.');
      }
      return true;
    } catch (_) {
      _errorMessage = '수정 내용을 저장하지 못했습니다. 다시 시도해주세요.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}

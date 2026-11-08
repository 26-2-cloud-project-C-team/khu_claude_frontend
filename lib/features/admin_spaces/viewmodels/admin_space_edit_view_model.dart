import 'package:flutter/foundation.dart';

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
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  AdminSpaceDetail? get detail => _detail;
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

import 'package:flutter/foundation.dart';

import '../data/admin_space_repository.dart';
import '../models/admin_space_detail.dart';
import '../models/admin_space.dart';

class AdminSpaceDetailViewModel extends ChangeNotifier {
  AdminSpaceDetailViewModel({
    required this._repository,
    required this._spaceId,
  });

  final AdminSpaceRepository _repository;
  final String _spaceId;

  AdminSpaceDetail? _detail;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;

  AdminSpaceDetail? get detail => _detail;

  // 기존 화면에서 사용하던 기본 정보 접근도 유지
  AdminSpace? get space => _detail?.space;

  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _detail = await _repository.fetchSpaceDetailById(_spaceId);

      if (_detail == null) {
        _errorMessage = '공간 정보를 찾을 수 없습니다.';
      }
    } catch (e) {
      _errorMessage = '공간 정보를 불러오지 못했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 공개 상태 변경
  Future<bool> updateVisibility(bool isPublic) async {
    if (_isUpdating || _detail == null) return false;

    _isUpdating = true;
    notifyListeners();

    try {
      await _repository.updateVisibility(_spaceId, isPublic);
      await _refreshDetail();
      return true;
    } catch (e) {
      _errorMessage = '공개 상태 변경에 실패했습니다.';
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // 재조사 요청 처리
  Future<bool> resolveReinspection(String requestId) async {
    if (_isUpdating || _detail == null) return false;

    _isUpdating = true;
    notifyListeners();

    try {
      await _repository.resolveReinspection(_spaceId, requestId);
      await _refreshDetail();
      return true;
    } catch (e) {
      _errorMessage = '재조사 요청 처리에 실패했습니다.';
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // 현재 공간의 미처리 재조사 요청 전체 처리
  Future<bool> resolveAllReinspections({String result = ''}) async {
    if (_isUpdating || _detail == null) return false;

    final hasPendingRequests = _detail!.reinspectionRequests.any(
      (request) => !request.isResolved,
    );

    if (!hasPendingRequests) return true;

    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.resolveAllReinspections(_spaceId, result: result);

      await _refreshDetail();

      return true;
    } catch (_) {
      try {
        await _refreshDetail();
      } catch (_) {
        // 최신 정보를 불러오지 못하면 기존 상세 정보 유지
      }

      _errorMessage = '재조사 요청 처리에 실패했습니다.';
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // 변경된 상세 데이터 다시 불러오기
  Future<void> _refreshDetail() async {
    final updatedDetail = await _repository.fetchSpaceDetailById(_spaceId);

    if (updatedDetail == null) {
      throw StateError('변경된 공간 정보를 불러오지 못했습니다.');
    }

    _detail = updatedDetail;
    _errorMessage = null;
    notifyListeners();
  }
}

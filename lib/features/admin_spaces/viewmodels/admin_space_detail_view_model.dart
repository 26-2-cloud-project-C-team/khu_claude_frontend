import 'package:flutter/foundation.dart';

import '../data/admin_space_repository.dart';
import '../models/admin_space.dart';
import '../models/admin_space_detail.dart';

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
    _errorMessage = null;
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
  Future<bool> resolveReinspection(String requestId, {String? result}) async {
    if (_isUpdating || _detail == null) return false;

    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.resolveReinspection(
        _spaceId,
        requestId,
        result: result,
      );
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

  /// 현재 공간에 접수된 미처리 요청을 한 번에 처리한다.
  Future<bool> resolveAllReinspections({String result = ''}) async {
    if (_isUpdating || _detail == null) return false;

    final requestIds = _detail!.reinspectionRequests
        .where((request) => !request.isResolved)
        .map((request) => request.id)
        .toList(growable: false);

    if (requestIds.isEmpty) return true;

    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.resolveAllReinspections(_spaceId, result: result);
      await _refreshDetail();
      return true;
    } catch (_) {
      // 일부 요청이 먼저 처리됐을 수 있으므로 서버의 최신 상태를 다시 반영한다.
      try {
        await _refreshDetail();
      } catch (_) {
        // 처리 실패 시 기존 상세 데이터라도 유지한다.
      }
      _errorMessage = '재조사 요청 처리에 실패했습니다.';
      notifyListeners();
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

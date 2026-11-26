import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/models/building.dart';
import '../../../core/models/noise_level.dart';
import '../../../core/models/purpose.dart';
import '../../../core/models/space_photo.dart';
import '../../admin_auth/models/admin_user.dart';
import '../data/admin_space_repository.dart';
import '../models/admin_space.dart';
import '../models/admin_space_detail.dart';
import '../models/form_photo.dart';
import '../models/selected_space_photo.dart';
import '../models/space_limits.dart';

class AdminSpaceFormViewModel extends ChangeNotifier {
  AdminSpaceFormViewModel({
    required this._repository,
    this._currentAdminEmail,
  }) {
    loadBuildings();
    loadAdmins();
  }

  static const maxPhotos = 10;

  final AdminSpaceRepository _repository;
  final String? _currentAdminEmail;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  List<Building> _buildings = const [];
  bool _isLoadingBuildings = false;
  String? _buildingError;

  List<Building> get buildings => List.unmodifiable(_buildings);
  bool get isLoadingBuildings => _isLoadingBuildings;
  String? get buildingError => _buildingError;

  Future<void> loadBuildings() async {
    if (_isLoadingBuildings) return;
    _isLoadingBuildings = true;
    _buildingError = null;
    _notify();
    try {
      _buildings = await _repository.fetchBuildings();
    } catch (_) {
      _buildingError = '건물 목록을 불러오지 못했습니다. 다시 시도해주세요.';
    } finally {
      _isLoadingBuildings = false;
      _notify();
    }
  }

  int _currentStep = 1;

  int get currentStep => _currentStep;
  int get totalSteps => 5;

  // STEP 1: 사진

  final Map<PhotoTag, FormPhoto?> _requiredPhotos = {
    for (final tag in PhotoTag.values) tag: null,
  };
  final Map<PhotoTag, String> _requiredPhotoErrors = {};
  final List<FormPhoto> _extraPhotos = [];
  String? _extraPhotoError;
  Future<void> _uploadQueue = Future.value();

  Map<PhotoTag, FormPhoto?> get requiredPhotos => Map.unmodifiable(_requiredPhotos);
  Map<PhotoTag, String> get requiredPhotoErrors => Map.unmodifiable(_requiredPhotoErrors);
  List<FormPhoto> get extraPhotos => List.unmodifiable(_extraPhotos);
  String? get extraPhotoError => _extraPhotoError;

  int get photoCount =>
      _requiredPhotos.values.where((photo) => photo != null).length +
      _extraPhotos.length;

  bool get hasRequiredPhotos =>
      _requiredPhotos.values.every((photo) => photo != null);

  Iterable<FormPhoto> get _allPhotos => [
    for (final tag in PhotoTag.values)
      if (_requiredPhotos[tag] != null) _requiredPhotos[tag]!,
    ..._extraPhotos,
  ];

  bool get isUploadingPhotos => _allPhotos.any((photo) => !photo.isUploaded);

  void setRequiredPhoto(PhotoTag tag, SelectedSpacePhoto photo) {
    final entry = FormPhoto(photo);
    _requiredPhotos[tag] = entry;
    _requiredPhotoErrors.remove(tag);
    _notify();
    _enqueueUpload(
      entry,
      isCurrent: () => _requiredPhotos[tag] == entry,
      onFailed: (message) {
        _requiredPhotos[tag] = null;
        _requiredPhotoErrors[tag] = message;
      },
    );
  }

  void removeRequiredPhoto(PhotoTag tag) {
    _requiredPhotos[tag] = null;
    _requiredPhotoErrors.remove(tag);
    _notify();
  }

  bool addExtraPhoto(SelectedSpacePhoto photo) {
    if (photoCount >= maxPhotos) return false;

    final entry = FormPhoto(photo);
    _extraPhotos.add(entry);
    _extraPhotoError = null;
    _notify();
    _enqueueUpload(
      entry,
      isCurrent: () => _extraPhotos.contains(entry),
      onFailed: (message) {
        _extraPhotos.remove(entry);
        _extraPhotoError = message;
      },
    );
    return true;
  }

  void removeExtraPhoto(int index) {
    if (index < 0 || index >= _extraPhotos.length) return;

    _extraPhotos.removeAt(index);
    _notify();
  }

  // 업로드는 한 장씩 고른 순서대로 한다. 기다리는 사이 칸을 비우거나 바꾸면 그 사진은 건너뛴다.
  void _enqueueUpload(
    FormPhoto entry, {
    required bool Function() isCurrent,
    required void Function(String message) onFailed,
  }) {
    _uploadQueue = _uploadQueue.then((_) async {
      if (_disposed || !isCurrent()) return;
      entry.status = PhotoUploadStatus.uploading;
      _notify();
      try {
        entry.photo = await _repository.uploadPhoto(entry.photo);
        entry.status = PhotoUploadStatus.uploaded;
      } catch (error) {
        if (isCurrent()) onFailed(_uploadErrorMessage(error));
      }
      _notify();
    });
  }

  static String _uploadErrorMessage(Object error) {
    if (error is AppException && error.message != null) {
      return '사진을 올리지 못했어요. ${error.message}';
    }
    return '사진을 올리지 못했어요. 다시 골라주세요.';
  }

  // STEP 2: 위치
  String _spaceName = '';
  Building? _building;
  int? _floor;
  String _detailLocation = '';
  final Set<Purpose> _purposes = {};

  String get spaceName => _spaceName;
  Building? get building => _building;
  int? get floor => _floor;
  String get detailLocation => _detailLocation;
  List<Purpose> get purposes =>
      Purpose.values.where(_purposes.contains).toList(growable: false);

  void setSpaceName(String value) {
    _spaceName = value;
    _notify();
  }

  void setBuilding(Building value) {
    _building = value;
    _floor = null;
    _notify();
  }

  void setFloor(int value) {
    if (_building == null || !_building!.floorRange.floors.contains(value)) {
      return;
    }

    _floor = value;
    _notify();
  }

  void setDetailLocation(String value) {
    _detailLocation = value;
    _notify();
  }

  void togglePurpose(Purpose value) {
    if (!_purposes.remove(value)) _purposes.add(value);
    _notify();
  }

  // STEP 3: 이용 규칙과 소음
  bool _isCafe = false;
  bool _canTalk = false;
  bool _is24Hours = false;

  int _startMinutes = 9 * 60;
  int _endMinutes = 22 * 60;

  NoiseLevel _noiseLevel = NoiseLevel.quiet;

  bool get cafeEnabled => _isCafe;
  bool get conversationEnabled => _canTalk;
  bool get is24Hours => _is24Hours;

  int get startMinutes => _startMinutes;
  int get endMinutes => _endMinutes;

  NoiseLevel get noiseLevel => _noiseLevel;

  void updateCafeEnabled(bool value) {
    _isCafe = value;
    _notify();
  }

  void updateConversationEnabled(bool value) {
    _canTalk = value;
    _notify();
  }

  void update24HourAvailability(bool value) {
    _is24Hours = value;

    if (value) {
      _startMinutes = 0;
      _endMinutes = 1440;
    }

    _notify();
  }

  void updateOperatingHours({
    required int startMinutes,
    required int endMinutes,
  }) {
    _is24Hours = false;
    _startMinutes = startMinutes.clamp(0, 1439).toInt();
    _endMinutes = endMinutes.clamp(1, 1440).toInt();
    _notify();
  }

  void updateNoiseLevel(NoiseLevel value) {
    _noiseLevel = value;
    _notify();
  }

  // STEP 4: 테이블과 시설
  int _tableCount = 10;
  int _maxPeoplePerTable = 8;
  int _chargingTableCount = 8;
  bool _hasFreeWifi = true;

  int get tableCount => _tableCount;
  int get maxPeoplePerTable => _maxPeoplePerTable;
  int get chargingTableCount => _chargingTableCount;
  bool get hasFreeWifi => _hasFreeWifi;

  void setTableCount(int value) {
    _tableCount = value.clamp(1, SpaceLimits.maxTableCount);
    _chargingTableCount = _chargingTableCount.clamp(0, _tableCount);
    _notify();
  }

  void setMaxPeoplePerTable(int value) {
    _maxPeoplePerTable = value.clamp(1, SpaceLimits.maxSeatsPerTable);
    _notify();
  }

  void setChargingTableCount(int value) {
    _chargingTableCount = value.clamp(0, _tableCount);
    _notify();
  }

  void setFreeWifi(bool value) {
    _hasFreeWifi = value;
    _notify();
  }

  // STEP 5: 현장 의견 및 조사자
  String _goodPoints = '';
  String _badPoints = '';
  String _memo = '';
  String get goodPoints => _goodPoints;
  String get badPoints => _badPoints;
  String get memo => _memo;

  void setGoodPoints(String value) {
    _goodPoints = _limit(value, 40);
    _notify();
  }

  void setBadPoints(String value) {
    _badPoints = _limit(value, 40);
    _notify();
  }

  void setMemo(String value) {
    _memo = _limit(value, 100);
    _notify();
  }

  List<AdminUser> _admins = const [];
  AdminUser? _surveyor;

  /// 조사자 시트 순서: 로그인한 본인을 맨 위에, 나머지는 이름 가나다순.
  List<AdminUser> get surveyorOptions => [
    ..._admins.where(isCurrentAdmin),
    ..._admins.where((admin) => !isCurrentAdmin(admin)),
  ];
  AdminUser? get surveyor => _surveyor;

  bool isCurrentAdmin(AdminUser admin) => admin.email == _currentAdminEmail;

  Future<void> loadAdmins() async {
    try {
      final admins = await _repository.fetchAdmins();
      _admins = [...admins]..sort((a, b) => a.name.compareTo(b.name));
    } catch (_) {
      _admins = const [];
    }
    _surveyor ??= _admins.where(isCurrentAdmin).firstOrNull;
    _notify();
  }

  void selectSurveyor(AdminUser admin) {
    _surveyor = admin;
    _notify();
  }

  // 단계 검증
  bool get canProceed {
    switch (_currentStep) {
      case 1:
        return hasRequiredPhotos;

      case 2:
        return _spaceName.trim().isNotEmpty &&
            _building != null &&
            _floor != null &&
            _detailLocation.trim().isNotEmpty &&
            _purposes.isNotEmpty;

      case 3:
        return _is24Hours || _endMinutes > _startMinutes;

      case 4:
        return _tableCount >= 1 && _chargingTableCount <= _tableCount;

      case 5:
        return _goodPoints.trim().isNotEmpty &&
            _badPoints.trim().isNotEmpty &&
            _memo.trim().isNotEmpty &&
            _surveyor != null &&
            hasRequiredPhotos &&
            !isUploadingPhotos &&
            !_isSubmitting;

      default:
        return false;
    }
  }

  bool nextStep() {
    if (!canProceed || _currentStep >= totalSteps) {
      return false;
    }

    _currentStep++;
    _notify();
    return true;
  }

  void previousStep() {
    if (_currentStep <= 1) return;

    _currentStep--;
    _notify();
  }

  bool _isSubmitting = false;
  String? _submitError;

  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;

  /// 등록에 성공하면 새 공간 ID를, 실패하면 null을 돌려준다. 실패 사유는 [submitError]에 둔다.
  Future<String?> submit() async {
    if (_currentStep != totalSteps || !canProceed) return null;
    final building = _building!;
    final floor = _floor!;

    _isSubmitting = true;
    _submitError = null;
    _notify();

    final floorLabel = floor < 0 ? '지하 ${floor.abs()}층' : '$floor층';
    final space = AdminSpace(
      id: '',
      name: _spaceName.trim(),
      location: '${building.name} · $floorLabel · ${_detailLocation.trim()}',
      updatedAt: DateTime.now(),
      isPublic: true,
      buildingId: building.id,
      buildingName: building.name,
      floor: floor,
      locationDetail: _detailLocation.trim(),
      purposes: [for (final purpose in purposes) purpose.code],
    );
    final detail = AdminSpaceDetail(
      space: space,
      photos: [for (final photo in _allPhotos) photo.photo],
      purpose: purposes.map((purpose) => purpose.label).join(', '),
      isCafe: _isCafe,
      canTalk: _canTalk,
      is24Hours: _is24Hours,
      startMinute: _startMinutes,
      endMinute: _endMinutes,
      noiseLevel: _noiseLevel.label,
      tableCount: _tableCount,
      maxPeoplePerTable: _maxPeoplePerTable,
      chargingTableCount: _chargingTableCount,
      hasFreeWifi: _hasFreeWifi,
      goodPoints: _goodPoints,
      badPoints: _badPoints,
      memo: _memo,
      surveyor: _surveyor!.email,
    );

    try {
      return await _repository.addSpace(
        space,
        detail: detail,
        surveyorEmail: _surveyor!.email,
      );
    } catch (error) {
      _submitError = _submitErrorMessage(error);
      return null;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  static String _submitErrorMessage(Object error) {
    if (error is AppException) {
      final fields = error.fieldErrors.map((f) => '${f.field}: ${f.reason}');
      return [
        '공간을 등록하지 못했어요.',
        if (error.message != null) error.message!,
        ...fields,
      ].join('\n');
    }
    if (error is ArgumentError) return '공간을 등록하지 못했어요.\n${error.message}';
    return '공간을 등록하지 못했어요. 다시 시도해주세요.';
  }

  static String _limit(String value, int max) {
    final runes = value.runes;

    if (runes.length <= max) {
      return value;
    }

    return String.fromCharCodes(runes.take(max));
  }
}

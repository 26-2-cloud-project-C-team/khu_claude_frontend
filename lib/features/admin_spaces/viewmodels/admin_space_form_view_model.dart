import 'package:flutter/foundation.dart';

import '../../../core/models/building.dart';
import '../../../core/models/noise_level.dart';
import '../../../core/models/purpose.dart';
import '../../../core/models/space_photo.dart';
import '../models/selected_space_photo.dart';

class AdminSpaceFormViewModel extends ChangeNotifier {
  int _currentStep = 1;

  int get currentStep => _currentStep;
  int get totalSteps => 5;

  // STEP 1: 사진

  final Map<PhotoTag, SelectedSpacePhoto?> _requiredPhotos = {
    for (final tag in PhotoTag.values) tag: null,
  };

  final List<SelectedSpacePhoto> _extraPhotos = [];

  Map<PhotoTag, SelectedSpacePhoto?> get requiredPhotos =>
      Map.unmodifiable(_requiredPhotos);

  List<SelectedSpacePhoto> get extraPhotos => List.unmodifiable(_extraPhotos);

  int get photoCount =>
      _requiredPhotos.values.where((photo) => photo != null).length +
      _extraPhotos.length;

  bool get hasRequiredPhotos =>
      _requiredPhotos.values.every((photo) => photo != null);

  void setRequiredPhoto(PhotoTag tag, SelectedSpacePhoto photo) {
    _requiredPhotos[tag] = photo;
    notifyListeners();
  }

  void removeRequiredPhoto(PhotoTag tag) {
    _requiredPhotos[tag] = null;
    notifyListeners();
  }

  bool addExtraPhoto(SelectedSpacePhoto photo) {
    if (photoCount >= 10) return false;

    _extraPhotos.add(photo);
    notifyListeners();
    return true;
  }

  void removeExtraPhoto(int index) {
    if (index < 0 || index >= _extraPhotos.length) return;

    _extraPhotos.removeAt(index);
    notifyListeners();
  }

  // STEP 2: 위치
  String _spaceName = '';
  Building? _building;
  int? _floor;
  String _detailLocation = '';
  Purpose? _purpose;

  String get spaceName => _spaceName;
  Building? get building => _building;
  int? get floor => _floor;
  String get detailLocation => _detailLocation;
  Purpose? get purpose => _purpose;

  void setSpaceName(String value) {
    _spaceName = value;
    notifyListeners();
  }

  void setBuilding(Building value) {
    _building = value;
    _floor = null;
    notifyListeners();
  }

  void setFloor(int value) {
    if (_building == null || !_building!.floorRange.floors.contains(value)) {
      return;
    }

    _floor = value;
    notifyListeners();
  }

  void setDetailLocation(String value) {
    _detailLocation = value;
    notifyListeners();
  }

  void setPurpose(Purpose value) {
    _purpose = value;
    notifyListeners();
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

  // 3단계 상태 변경
  void updateCafeEnabled(bool value) {
    _isCafe = value;
    notifyListeners();
  }

  void updateConversationEnabled(bool value) {
    _canTalk = value;
    notifyListeners();
  }

  void update24HourAvailability(bool value) {
    _is24Hours = value;

    if (value) {
      _startMinutes = 0;
      _endMinutes = 1440;
    }

    notifyListeners();
  }

  void updateOperatingHours({
    required int startMinutes,
    required int endMinutes,
  }) {
    _is24Hours = false;
    _startMinutes = startMinutes.clamp(0, 1439).toInt();
    _endMinutes = endMinutes.clamp(1, 1440).toInt();
    notifyListeners();
  }

  void updateNoiseLevel(NoiseLevel value) {
    _noiseLevel = value;
    notifyListeners();
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
    _tableCount = value.clamp(0, 40);
    _chargingTableCount = _chargingTableCount.clamp(0, _tableCount);
    notifyListeners();
  }

  void setMaxPeoplePerTable(int value) {
    _maxPeoplePerTable = value.clamp(1, 8);
    notifyListeners();
  }

  void setChargingTableCount(int value) {
    _chargingTableCount = value.clamp(0, _tableCount);
    notifyListeners();
  }

  void setFreeWifi(bool value) {
    _hasFreeWifi = value;
    notifyListeners();
  }

  // STEP 5: 현장 의견 및 조사자
  String _goodPoints = '';
  String _badPoints = '';
  String _memo = '';
  String? _surveyor;

  String get goodPoints => _goodPoints;
  String get badPoints => _badPoints;
  String get memo => _memo;
  String? get surveyor => _surveyor;

  void setGoodPoints(String value) {
    _goodPoints = _limit(value, 40);
    notifyListeners();
  }

  void setBadPoints(String value) {
    _badPoints = _limit(value, 40);
    notifyListeners();
  }

  void setMemo(String value) {
    _memo = _limit(value, 100);
    notifyListeners();
  }

  void setSurveyor(String value) {
    _surveyor = value;
    notifyListeners();
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
            _purpose != null;

      case 3:
        return _is24Hours || _endMinutes > _startMinutes;

      case 4:
        return _chargingTableCount <= _tableCount;

      case 5:
        return _surveyor != null && _surveyor!.isNotEmpty;

      default:
        return false;
    }
  }

  bool nextStep() {
    if (!canProceed || _currentStep >= totalSteps) {
      return false;
    }

    _currentStep++;
    notifyListeners();
    return true;
  }

  void previousStep() {
    if (_currentStep <= 1) return;

    _currentStep--;
    notifyListeners();
  }

  static String _limit(String value, int max) {
    final runes = value.runes;

    if (runes.length <= max) {
      return value;
    }

    return String.fromCharCodes(runes.take(max));
  }
}

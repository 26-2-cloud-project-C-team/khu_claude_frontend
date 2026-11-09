import '../../../core/models/building.dart';
import '../../../core/models/noise_level.dart';
import '../../../core/models/purpose.dart';
import '../../../core/models/reinspection_category.dart';
import '../../../core/network/api_client.dart';
import '../models/admin_space.dart';
import '../models/admin_space_activity.dart';
import '../models/admin_space_detail.dart';
import '../models/reinspection_request.dart';
import '../models/selected_space_photo.dart';
import 'admin_space_repository.dart';

/// 관리자 공간 관련 API를 호출하는 실제 Repository 구현체.
///
/// 백엔드 OpenAPI 응답을 화면 모델로 변환하고, 화면 모델을 API 요청 DTO로 변환한다.
class ApiAdminSpaceRepository implements AdminSpaceRepository {
  ApiAdminSpaceRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<Building>> fetchBuildings() async {
    final response = _asMap(await _apiClient.get('/api/admin/buildings'));
    final items = _asList(response['buildings']);
    return [
      for (final item in items) Building.fromJson(_asMap(item)),
    ];
  }

  @override
  Future<List<AdminSpace>> fetchSpaces() async {
    final response = _asMap(await _apiClient.get('/api/admin/spaces'));
    final items = _asList(response['spaces']);
    return [
      for (final item in items) _spaceFromSummary(_asMap(item)),
    ];
  }

  @override
  Future<AdminSpace?> fetchSpaceById(String id) async {
    final detail = await fetchSpaceDetailById(id);
    return detail?.space;
  }

  @override
  Future<AdminSpaceDetail?> fetchSpaceDetailById(String id) async {
    final response = await _apiClient.get('/api/admin/spaces/$id');
    if (response == null) return null;
    return _spaceDetailFromJson(_asMap(response));
  }

  @override
  Future<void> addSpace(
    AdminSpace space, {
    AdminSpaceDetail? detail,
    required String surveyorEmail,
  }) async {
    if (detail == null) {
      throw ArgumentError('공간 등록에는 상세 정보가 필요합니다.');
    }
    if (surveyorEmail.trim().isEmpty) {
      throw ArgumentError('로그인한 관리자 이메일을 확인할 수 없습니다.');
    }
    if (detail.photos.length < 3 || detail.photos.length > 10) {
      throw ArgumentError('필수 사진 3장과 추가 사진 최대 7장을 등록해주세요.');
    }
    final buildingId = _requiredString(
      space.buildingId,
      '공간의 건물 ID가 없습니다. 건물 목록에서 다시 선택해주세요.',
    );
    final floor = space.floor;
    if (floor == null) {
      throw ArgumentError('공간 층 정보가 없습니다. 층을 다시 선택해주세요.');
    }
    final purposeCodes = space.purposes.isNotEmpty
        ? space.purposes
        : _purposeCodesFromLabel(detail.purpose);

    // 입력 오류로 사진만 먼저 업로드되는 일을 줄이기 위해 요청 DTO를 먼저 검증·구성한다.
    final rules = _rulesRequest(detail);
    final facilities = _facilitiesRequest(detail);
    final impressions = _impressionsRequest(detail);
    _validateCreateValues(
      space: space,
      detail: detail,
      purposeCodes: purposeCodes,
    );

    final photoRefs = await _uploadPhotoRefs(detail.photos);

    final request = {
      'surveyorEmail': surveyorEmail.trim(),
      'location': {
        'name': space.name.trim(),
        'buildingId': buildingId,
        'floor': floor,
        'locationDetail': _requiredString(
          space.locationDetail,
          '상세 위치를 입력해주세요.',
        ),
        'purposes': purposeCodes,
      },
      'photos': {
        'entrance': photoRefs[0],
        'approach': photoRefs[1],
        'inside': photoRefs[2],
        'extras': photoRefs.skip(3).toList(growable: false),
      },
      'rules': rules,
      'facilities': facilities,
      'impressions': impressions,
    };

    await _apiClient.post('/api/admin/spaces', body: request);
  }

  @override
  Future<void> updateVisibility(String id, bool isPublic) async {
    await _apiClient.put(
      '/api/admin/spaces/$id/visibility',
      body: {'isPublic': isPublic},
    );
  }

  @override
  Future<void> updateSpaceDetail(
    String id,
    AdminSpaceDetail detail, {
    required String sectionLabel,
  }) async {
    final path = '/api/admin/spaces/$id';

    switch (sectionLabel) {
      case '위치':
        final space = detail.space;
        final floor = space.floor;
        if (floor == null) {
          throw ArgumentError('층 정보가 없어 위치를 수정할 수 없습니다.');
        }
        await _apiClient.put(
          '$path/location',
          body: {
            'name': space.name.trim(),
            'buildingId': _requiredString(
              space.buildingId,
              '건물 정보가 없어 위치를 수정할 수 없습니다.',
            ),
            'floor': floor,
            'locationDetail': _requiredString(
              space.locationDetail,
              '상세 위치를 입력해주세요.',
            ),
            // 현재 편집 UI는 단일 이용 목적을 선택하므로 사용자가 고른 값으로 교체한다.
            'purposes': _purposeCodesFromLabel(detail.purpose),
          },
        );
        break;
      case '사진':
        if (detail.photos.length < 3 || detail.photos.length > 10) {
          throw ArgumentError('필수 사진 3장과 추가 사진 최대 7장을 등록해주세요.');
        }
        final photoRefs = await _uploadPhotoRefs(detail.photos);
        await _apiClient.put(
          '$path/photos',
          body: {
            'entrance': photoRefs[0],
            'approach': photoRefs[1],
            'inside': photoRefs[2],
            'extras': photoRefs.skip(3).toList(growable: false),
          },
        );
        break;
      case '이용 규칙과 소음':
        await _apiClient.put('$path/rules', body: _rulesRequest(detail));
        break;
      case '테이블과 시설':
        await _apiClient.put(
          '$path/facilities',
          body: _facilitiesRequest(detail),
        );
        break;
      case '현장에서 느낀 점':
        await _apiClient.put(
          '$path/impressions',
          body: _impressionsRequest(detail),
        );
        break;
      default:
        throw ArgumentError('지원하지 않는 수정 섹션입니다: $sectionLabel');
    }
  }

  @override
  Future<void> resolveAllReinspections(
    String spaceId, {
    required String result,
    bool makePrivate = false,
  }) async {
    await _apiClient.post(
      '/api/admin/spaces/$spaceId/reinspections/resolve',
      body: {'result': result.trim(), 'makePrivate': makePrivate},
    );
  }

  Future<List<Map<String, String>>> _uploadPhotoRefs(
    List<SelectedSpacePhoto> photos,
  ) async {
    final refs = <Map<String, String>>[];
    // 서버는 한 요청당 사진 한 장을 받으므로 순차 업로드한다.
    for (final photo in photos) {
      final existingId = photo.id;
      if (existingId != null && existingId.isNotEmpty) {
        refs.add({'id': existingId});
        continue;
      }

      final bytes = photo.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw ArgumentError('업로드할 사진 데이터가 없습니다: ${photo.name}');
      }
      final uploaded = _asMap(
        await _apiClient.postMultipart(
          '/api/admin/photos',
          bytes: bytes,
          fileName: photo.name,
          mimeType: photo.mimeType,
        ),
      );
      refs.add({'id': _requiredString(uploaded['id'], '사진 업로드 응답에 ID가 없습니다.')});
    }
    return refs;
  }

  Map<String, dynamic> _rulesRequest(AdminSpaceDetail detail) {
    final noise = NoiseLevel.values.firstWhere(
      (value) => value.label == detail.noiseLevel || value.code == detail.noiseLevel,
      orElse: () => NoiseLevel.normal,
    );
    return {
      'isCafe': detail.isCafe,
      'talkAllowed': detail.canTalk,
      'hours': {
        'open': _formatMinute(detail.startMinute),
        'close': _formatMinute(detail.endMinute),
      },
      'noiseLevel': noise.code,
    };
  }

  Map<String, dynamic> _facilitiesRequest(AdminSpaceDetail detail) => {
    'tableCount': detail.tableCount,
    'maxSeatsPerTable': detail.maxPeoplePerTable,
    'chargeableTables': detail.chargingTableCount,
    'freeWifi': detail.hasFreeWifi,
  };

  Map<String, dynamic> _impressionsRequest(AdminSpaceDetail detail) => {
    'pros': detail.goodPoints.trim(),
    'cons': detail.badPoints.trim(),
    'note': detail.memo.trim(),
  };

  void _validateCreateValues({
    required AdminSpace space,
    required AdminSpaceDetail detail,
    required List<String> purposeCodes,
  }) {
    if (space.name.trim().isEmpty || space.name.runes.length > 40) {
      throw ArgumentError('공간 이름은 1~40자로 입력해주세요.');
    }
    if ((space.locationDetail ?? '').trim().isEmpty ||
        space.locationDetail!.runes.length > 40) {
      throw ArgumentError('상세 위치는 1~40자로 입력해주세요.');
    }
    if (purposeCodes.isEmpty || purposeCodes.length > 3) {
      throw ArgumentError('이용 목적을 1~3개 선택해주세요.');
    }
    if (detail.tableCount < 1 || detail.maxPeoplePerTable < 1) {
      throw ArgumentError('테이블 수와 테이블 최대 인원은 1 이상이어야 합니다.');
    }
    if (detail.chargingTableCount < 0 ||
        detail.chargingTableCount > detail.tableCount) {
      throw ArgumentError('충전 가능한 테이블 수를 확인해주세요.');
    }
    if (detail.goodPoints.trim().isEmpty ||
        detail.goodPoints.runes.length > 40 ||
        detail.badPoints.trim().isEmpty ||
        detail.badPoints.runes.length > 40 ||
        detail.memo.trim().isEmpty ||
        detail.memo.runes.length > 100) {
      throw ArgumentError('현장 의견은 항목별 글자 수와 필수 입력 여부를 확인해주세요.');
    }
  }

  AdminSpace _spaceFromSummary(Map<String, dynamic> json) {
    final building = _asMap(json['building']);
    return AdminSpace(
      id: _requiredString(json['id'], '공간 목록 응답에 ID가 없습니다.'),
      name: _string(json['name']),
      location: _string(building['name']),
      updatedAt: _date(json['lastModifiedAt']),
      isPublic: json['isPublic'] == true,
      reinspectionRequestCount: _integer(json['pendingReinspectionCount']),
      buildingId: _nullableString(building['id']),
      buildingName: _nullableString(building['name']),
      isStale: json['stale'] == true,
    );
  }

  AdminSpaceDetail _spaceDetailFromJson(Map<String, dynamic> json) {
    final location = _asMap(json['location']);
    final building = _asMap(json['building']);
    final rules = _asMap(json['rules']);
    final hours = _asMap(rules['hours']);
    final facilities = _asMap(json['facilities']);
    final impressions = _asMap(json['impressions']);
    final photos = _asMap(json['photos']);
    final history = _asMap(json['history']);

    final buildingName = _string(building['name']);
    final floor = _integer(location['floor']);
    final locationDetail = _string(location['locationDetail']);
    final locationText = [
      buildingName,
      _floorLabel(floor),
      locationDetail,
    ].where((value) => value.isNotEmpty).join(' · ');
    final purposeCodes = _asList(location['purposes'])
        .map((value) => value.toString())
        .toList(growable: false);
    final purposes = purposeCodes
        .map(Purpose.fromCode)
        .whereType<Purpose>()
        .map((value) => value.label)
        .toList(growable: false);

    final rulesHoursOpen = _string(hours['open'], fallback: '09:00');
    final rulesHoursClose = _string(hours['close'], fallback: '22:00');
    final startMinute = _parseMinute(rulesHoursOpen);
    final endMinute = _parseMinute(rulesHoursClose);

    final space = AdminSpace(
      id: _requiredString(json['id'], '공간 상세 응답에 ID가 없습니다.'),
      name: _string(location['name']),
      location: locationText,
      updatedAt: _activityDate(history['lastModified']) ??
          _activityDate(history['firstSurvey']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isPublic: json['isPublic'] == true,
      reinspectionRequestCount: _asList(json['pendingReinspections']).length,
      buildingId: _nullableString(location['buildingId']),
      buildingName: buildingName,
      floor: floor,
      locationDetail: locationDetail,
      purposes: purposeCodes,
    );

    final selectedPhotos = <SelectedSpacePhoto>[
      _remotePhoto(photos['entrance'], '입구'),
      _remotePhoto(photos['approach'], '가는 길'),
      _remotePhoto(photos['inside'], '내부'),
      for (final extra in _asList(photos['extras']))
        if (extra != null) _remotePhoto(extra, '추가 사진'),
    ];

    final requests = <ReinspectionRequest>[
      for (final item in _asList(json['pendingReinspections']))
        _reinspectionFromJson(_asMap(item)),
    ];

    final activities = <AdminSpaceActivity>[
      if (history['firstSurvey'] != null)
        _activityFromJson(history['firstSurvey'], '최초 조사'),
      if (history['lastModified'] != null)
        _activityFromJson(history['lastModified'], '최근 수정'),
    ];
    final firstSurvey = _asNullableMap(history['firstSurvey']);
    final firstSurveyBy = _asNullableMap(firstSurvey?['by']);
    final lastResolvedAt = _nullableDate(json['lastResolvedAt']);
    final noise = NoiseLevel.fromCode(_string(rules['noiseLevel'], fallback: 'NORMAL'));

    return AdminSpaceDetail(
      space: space,
      photos: selectedPhotos,
      purpose: purposes.join(', '),
      isCafe: rules['isCafe'] == true,
      canTalk: rules['talkAllowed'] == true,
      is24Hours: startMinute == 0 && endMinute == 1440,
      startMinute: startMinute,
      endMinute: endMinute,
      noiseLevel: noise.label,
      tableCount: _integer(facilities['tableCount'], fallback: 1),
      maxPeoplePerTable: _integer(facilities['maxSeatsPerTable'], fallback: 1),
      chargingTableCount: _integer(facilities['chargeableTables']),
      hasFreeWifi: facilities['freeWifi'] == true,
      goodPoints: _string(impressions['pros']),
      badPoints: _string(impressions['cons']),
      memo: _string(impressions['note']),
      surveyor: _string(firstSurveyBy?['email']),
      reinspectionRequests: requests,
      lastResolvedAt: lastResolvedAt,
      activities: activities,
    );
  }

  AdminSpaceActivity _activityFromJson(Object? raw, String title) {
    final activity = _asMap(raw);
    final by = _asNullableMap(activity['by']);
    final name = _string(by?['name']);
    final email = _string(by?['email']);
    return AdminSpaceActivity(
      id: '$title-${activity['at'] ?? ''}',
      title: title,
      description: email.isEmpty ? '' : email,
      createdAt: _date(activity['at']),
      actor: name.isEmpty ? '관리자' : name,
    );
  }

  ReinspectionRequest _reinspectionFromJson(Map<String, dynamic> json) {
    final categories = _asList(json['categories'])
        .map((value) => ReinspectionCategory.fromCode(value.toString()))
        .toList(growable: false);
    return ReinspectionRequest(
      id: _requiredString(json['id'], '재조사 요청 ID가 없습니다.'),
      message: _string(json['detail']),
      requestedAt: _date(json['createdAt']),
      categories: categories,
    );
  }

  SelectedSpacePhoto _remotePhoto(Object? raw, String name) {
    // 백엔드는 기존 데이터에 사진이 없는 경우 필수 사진 URL을 null로 반환할 수 있다.
    // 화면에서 해당 슬롯을 비워 두고 새 사진을 선택할 수 있도록 placeholder로 변환한다.
    if (raw == null) return SelectedSpacePhoto(name: name);

    final json = _asMap(raw);
    return SelectedSpacePhoto(
      name: name,
      mimeType: 'image/webp',
      id: _nullableString(json['id']),
      url: _nullableString(json['url']),
    );
  }

  static List<String> _purposeCodesFromLabel(String label) {
    final selected = Purpose.values.where((value) => label.contains(value.label));
    final codes = selected.map((value) => value.code).toList(growable: false);
    if (codes.isEmpty) throw ArgumentError('이용 목적을 선택해주세요.');
    return codes;
  }

  static String _formatMinute(int minute) {
    if (minute < 0 || minute > 1440 || minute % 30 != 0) {
      throw ArgumentError('이용 시간은 30분 단위로 선택해주세요.');
    }
    if (minute == 1440) return '24:00';
    final hour = minute ~/ 60;
    final minutes = minute % 60;
    return '${hour.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  static int _parseMinute(String value) {
    if (value == '24:00') return 1440;
    final parts = value.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 +
        (int.tryParse(parts[1]) ?? 0);
  }

  static String _floorLabel(int floor) =>
      floor < 0 ? '지하 ${floor.abs()}층' : '$floor층';

  static String _requiredString(Object? value, String message) {
    final result = value?.toString().trim() ?? '';
    if (result.isEmpty) throw ArgumentError(message);
    return result;
  }

  static String _string(Object? value, {String fallback = ''}) =>
      value is String ? value : fallback;

  static String? _nullableString(Object? value) => value?.toString();

  static int _integer(Object? value, {int fallback = 0}) =>
      value is num ? value.toInt() : fallback;

  static DateTime _date(Object? value) =>
      value is String ? DateTime.parse(value) : DateTime.fromMillisecondsSinceEpoch(0);

  static DateTime? _nullableDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static DateTime? _activityDate(Object? value) {
    final map = _asNullableMap(value);
    return _nullableDate(map?['at']);
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('서버 응답이 올바른 객체 형식이 아닙니다.');
  }

  static Map<String, dynamic>? _asNullableMap(Object? value) {
    if (value == null) return null;
    return _asMap(value);
  }

  static List<dynamic> _asList(Object? value) =>
      value is List ? value : const <dynamic>[];
}

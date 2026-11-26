import '../../../core/models/purpose.dart';
import 'admin_space_detail.dart';
import 'admin_space_edit_section.dart';
import 'selected_space_photo.dart';

/// [detail]의 이용 목적. 서버 코드가 있으면 그것을, 없으면 표시 문구에서 읽는다.
Set<Purpose> purposesOf(AdminSpaceDetail detail) {
  final fromCodes = detail.space.purposes
      .map(Purpose.fromCode)
      .whereType<Purpose>()
      .toSet();
  if (fromCodes.isNotEmpty) return fromCodes;
  return Purpose.values
      .where((purpose) => detail.purpose.contains(purpose.label))
      .toSet();
}

/// AD-05에서 [section]의 값이 처음 연 값과 달라졌는지 본다.
bool hasSectionChanged(
  AdminSpaceEditSection section,
  AdminSpaceDetail original,
  AdminSpaceDetail edited,
) {
  switch (section) {
    case AdminSpaceEditSection.location:
      final a = original.space;
      final b = edited.space;
      return a.name.trim() != b.name.trim() ||
          (a.locationDetail ?? '').trim() != (b.locationDetail ?? '').trim() ||
          a.buildingId != b.buildingId ||
          a.floor != b.floor ||
          !_sameSet(purposesOf(original), purposesOf(edited));
    case AdminSpaceEditSection.photos:
      if (original.photos.length != edited.photos.length) return true;
      for (var i = 0; i < original.photos.length; i++) {
        if (!_samePhoto(original.photos[i], edited.photos[i])) return true;
      }
      return false;
    case AdminSpaceEditSection.rules:
      final hoursChanged = original.is24Hours != edited.is24Hours ||
          (!edited.is24Hours &&
              (original.startMinute != edited.startMinute ||
                  original.endMinute != edited.endMinute));
      return original.isCafe != edited.isCafe ||
          original.canTalk != edited.canTalk ||
          hoursChanged ||
          original.noiseLevel != edited.noiseLevel;
    case AdminSpaceEditSection.facilities:
      return original.tableCount != edited.tableCount ||
          original.maxPeoplePerTable != edited.maxPeoplePerTable ||
          original.chargingTableCount != edited.chargingTableCount ||
          original.hasFreeWifi != edited.hasFreeWifi;
    case AdminSpaceEditSection.fieldSurvey:
      return original.goodPoints.trim() != edited.goodPoints.trim() ||
          original.badPoints.trim() != edited.badPoints.trim() ||
          original.memo.trim() != edited.memo.trim();
  }
}

/// [section]이 서버에 보낼 수 있는 값인지 본다. 필수 · 글자 수 규칙은 AD-03과 같다.
///
/// 테이블 수와 최대 인원은 서버에 상한이 없다. 화면 상한보다 큰 값이 저장돼 있어도
/// 다른 값을 고칠 수 있도록 상한은 입력 위젯에서만 막는다.
bool isSectionValid(AdminSpaceEditSection section, AdminSpaceDetail edited) {
  switch (section) {
    case AdminSpaceEditSection.location:
      final space = edited.space;
      final name = space.name.trim();
      final detail = (space.locationDetail ?? '').trim();
      final purposes = purposesOf(edited);
      return name.isNotEmpty &&
          name.length <= 40 &&
          detail.isNotEmpty &&
          detail.length <= 40 &&
          space.buildingId != null &&
          space.floor != null &&
          purposes.isNotEmpty &&
          purposes.length <= 3;
    case AdminSpaceEditSection.photos:
      final photos = edited.photos;
      return photos.length >= 3 &&
          photos.length <= 10 &&
          photos.every((photo) => photo.isUploaded || photo.hasLocalBytes);
    case AdminSpaceEditSection.rules:
      return edited.is24Hours || edited.endMinute > edited.startMinute;
    case AdminSpaceEditSection.facilities:
      return edited.tableCount >= 1 &&
          edited.maxPeoplePerTable >= 1 &&
          edited.chargingTableCount >= 0 &&
          edited.chargingTableCount <= edited.tableCount;
    case AdminSpaceEditSection.fieldSurvey:
      bool ok(String value, int max) =>
          value.trim().isNotEmpty && value.length <= max;
      return ok(edited.goodPoints, 40) &&
          ok(edited.badPoints, 40) &&
          ok(edited.memo, 100);
  }
}

bool _sameSet<T>(Set<T> a, Set<T> b) => a.length == b.length && a.containsAll(b);

bool _samePhoto(SelectedSpacePhoto a, SelectedSpacePhoto b) {
  if (a.isUploaded || b.isUploaded) return a.id == b.id;
  return identical(a.bytes, b.bytes);
}

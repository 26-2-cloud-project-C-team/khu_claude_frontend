import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/models/purpose.dart';
import 'package:team_frontend/features/admin_spaces/models/admin_space.dart';
import 'package:team_frontend/features/admin_spaces/models/admin_space_detail.dart';
import 'package:team_frontend/features/admin_spaces/models/admin_space_edit_section.dart';
import 'package:team_frontend/features/admin_spaces/models/selected_space_photo.dart';
import 'package:team_frontend/features/admin_spaces/models/space_section_edit.dart';

AdminSpaceDetail _detail({
  int tableCount = 10,
  int maxPeople = 4,
  int charging = 8,
  bool wifi = true,
  List<String> purposes = const ['TEAM', 'CHAT'],
}) {
  return AdminSpaceDetail(
    space: AdminSpace(
      id: 's1',
      name: '공학관 2층 라운지',
      location: '공학관 · 2층 · 중앙 계단 옆',
      updatedAt: DateTime.utc(2026, 11, 25),
      isPublic: true,
      buildingId: 'b1',
      buildingName: '공학관',
      floor: 2,
      locationDetail: '중앙 계단 옆',
      purposes: purposes,
    ),
    photos: [
      for (final id in ['p1', 'p2', 'p3'])
        SelectedSpacePhoto(name: id, id: id, url: 'https://cdn/$id'),
    ],
    purpose: '팀 프로젝트 · 회의, 사담',
    isCafe: false,
    canTalk: true,
    is24Hours: false,
    startMinute: 9 * 60,
    endMinute: 22 * 60,
    noiseLevel: '보통',
    tableCount: tableCount,
    maxPeoplePerTable: maxPeople,
    chargingTableCount: charging,
    hasFreeWifi: wifi,
    goodPoints: '좋아요',
    badPoints: '아쉬워요',
    memo: '비고',
    surveyor: '관리자',
  );
}

void main() {
  group('hasSectionChanged', () {
    test('처음 값 그대로면 모든 섹션이 바뀌지 않은 것으로 본다', () {
      final detail = _detail();
      for (final section in AdminSpaceEditSection.values) {
        expect(hasSectionChanged(section, detail, detail), isFalse, reason: section.name);
      }
    });

    test('와이파이만 바꿔도 테이블과 시설이 바뀐 것으로 본다', () {
      final original = _detail();
      final edited = original.copyWith(hasFreeWifi: false);
      expect(hasSectionChanged(AdminSpaceEditSection.facilities, original, edited), isTrue);
    });

    test('이용 목적 집합이 같으면 순서와 상관없이 바뀌지 않은 것으로 본다', () {
      final original = _detail(purposes: ['TEAM', 'CHAT']);
      final edited = original.copyWith(
        space: original.space.copyWith(purposes: ['CHAT', 'TEAM']),
      );
      expect(hasSectionChanged(AdminSpaceEditSection.location, original, edited), isFalse);
    });

    test('건물이나 층이 바뀌면 위치가 바뀐 것으로 본다', () {
      final original = _detail();
      final edited = original.copyWith(
        space: original.space.copyWith(buildingId: 'b2', floor: 3),
      );
      expect(hasSectionChanged(AdminSpaceEditSection.location, original, edited), isTrue);
    });

    test('새로 고른 사진이 있으면 사진이 바뀐 것으로 본다', () {
      final original = _detail();
      final edited = original.copyWith(
        photos: [
          SelectedSpacePhoto(name: 'new.jpg', bytes: Uint8List.fromList([1, 2, 3])),
          ...original.photos.skip(1),
        ],
      );
      expect(hasSectionChanged(AdminSpaceEditSection.photos, original, edited), isTrue);
    });
  });

  group('isSectionValid', () {
    test('화면 상한보다 큰 값이 저장돼 있어도 테이블과 시설을 저장할 수 있다', () {
      final detail = _detail(tableCount: 412, maxPeople: 12, charging: 200);
      expect(isSectionValid(AdminSpaceEditSection.facilities, detail), isTrue);
    });

    test('충전 테이블이 전체 테이블보다 많으면 저장할 수 없다', () {
      final detail = _detail(tableCount: 3, charging: 4);
      expect(isSectionValid(AdminSpaceEditSection.facilities, detail), isFalse);
    });

    test('이용 목적이 하나도 없으면 위치를 저장할 수 없다', () {
      final original = _detail();
      final edited = original.copyWith(
        space: original.space.copyWith(purposes: const []),
        purpose: '',
      );
      expect(isSectionValid(AdminSpaceEditSection.location, edited), isFalse);
    });

    test('층을 비우면 위치를 저장할 수 없다', () {
      final original = _detail();
      final edited = AdminSpaceDetail(
        space: AdminSpace(
          id: 's1',
          name: original.space.name,
          location: original.space.location,
          updatedAt: original.space.updatedAt,
          isPublic: true,
          buildingId: 'b2',
          locationDetail: '중앙 계단 옆',
          purposes: const ['TEAM'],
        ),
        photos: original.photos,
        purpose: original.purpose,
        isCafe: false,
        canTalk: true,
        is24Hours: false,
        startMinute: 540,
        endMinute: 1320,
        noiseLevel: '보통',
        tableCount: 10,
        maxPeoplePerTable: 4,
        chargingTableCount: 8,
        hasFreeWifi: true,
        goodPoints: 'a',
        badPoints: 'b',
        memo: 'c',
        surveyor: '관리자',
      );
      expect(isSectionValid(AdminSpaceEditSection.location, edited), isFalse);
    });
  });

  test('purposesOf는 서버 코드가 없으면 표시 문구에서 목적을 읽는다', () {
    final original = _detail(purposes: const []);
    expect(purposesOf(original), {Purpose.team, Purpose.chat});
  });
}

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/models/building.dart';
import 'package:team_frontend/core/models/purpose.dart';
import 'package:team_frontend/core/models/space_photo.dart';
import 'package:team_frontend/features/admin_auth/models/admin_user.dart';
import 'package:team_frontend/features/admin_spaces/data/admin_space_repository.dart';
import 'package:team_frontend/features/admin_spaces/models/admin_space.dart';
import 'package:team_frontend/features/admin_spaces/models/admin_space_detail.dart';
import 'package:team_frontend/features/admin_spaces/models/form_photo.dart';
import 'package:team_frontend/features/admin_spaces/models/selected_space_photo.dart';
import 'package:team_frontend/features/admin_spaces/models/space_limits.dart';
import 'package:team_frontend/features/admin_spaces/viewmodels/admin_space_form_view_model.dart';

class _FakeRepository implements AdminSpaceRepository {
  final admins = <AdminUser>[
    const AdminUser(name: '조사자 나', email: 'b@example.com'),
    const AdminUser(name: 'Local Admin', email: 'me@example.com'),
    const AdminUser(name: '조사자 가', email: 'a@example.com'),
  ];

  /// 업로드를 테스트에서 하나씩 끝내도록 요청을 쌓아 둔다.
  final uploads = <(SelectedSpacePhoto, Completer<SelectedSpacePhoto>)>[];
  final uploadOrder = <String>[];
  int activeUploads = 0;
  int maxActiveUploads = 0;
  AdminSpace? addedSpace;
  String? addedSurveyorEmail;

  @override
  Future<List<Building>> fetchBuildings() async => const [];

  @override
  Future<List<AdminUser>> fetchAdmins() async => admins;

  @override
  Future<SelectedSpacePhoto> uploadPhoto(SelectedSpacePhoto photo) {
    uploadOrder.add(photo.name);
    activeUploads++;
    if (activeUploads > maxActiveUploads) maxActiveUploads = activeUploads;
    final completer = Completer<SelectedSpacePhoto>();
    uploads.add((photo, completer));
    return completer.future.whenComplete(() => activeUploads--);
  }

  void finishUpload(int index, {bool fail = false}) {
    final (photo, completer) = uploads[index];
    if (fail) {
      completer.completeError(Exception('upload failed'));
    } else {
      completer.complete(
        SelectedSpacePhoto(name: photo.name, bytes: photo.bytes, id: 'id-${photo.name}'),
      );
    }
  }

  @override
  Future<String> addSpace(
    AdminSpace space, {
    AdminSpaceDetail? detail,
    required String surveyorEmail,
  }) async {
    addedSpace = space;
    addedSurveyorEmail = surveyorEmail;
    return 'new-space-id';
  }

  @override
  Future<List<AdminSpace>> fetchSpaces() => throw UnimplementedError();
  @override
  Future<AdminSpace?> fetchSpaceById(String id) => throw UnimplementedError();
  @override
  Future<AdminSpaceDetail?> fetchSpaceDetailById(String id) => throw UnimplementedError();
  @override
  Future<void> updateVisibility(String id, bool isPublic) => throw UnimplementedError();
  @override
  Future<void> updateSpaceDetail(String id, AdminSpaceDetail detail, {required String sectionLabel}) =>
      throw UnimplementedError();
  @override
  Future<void> resolveAllReinspections(String spaceId, {required String result, bool makePrivate = false}) =>
      throw UnimplementedError();
}

SelectedSpacePhoto _photo(String name) =>
    SelectedSpacePhoto(name: name, mimeType: 'image/jpeg', bytes: Uint8List.fromList([1, 2, 3]));

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeRepository repository;
  late AdminSpaceFormViewModel viewModel;

  setUp(() async {
    repository = _FakeRepository();
    viewModel = AdminSpaceFormViewModel(repository: repository, currentAdminEmail: 'me@example.com');
    await _settle();
  });

  tearDown(() => viewModel.dispose());

  group('사진 업로드', () {
    test('고른 순서대로 한 장씩 올린다', () async {
      viewModel.setRequiredPhoto(PhotoTag.entrance, _photo('a'));
      viewModel.setRequiredPhoto(PhotoTag.approach, _photo('b'));
      await _settle();

      expect(repository.uploads, hasLength(1));
      expect(viewModel.requiredPhotos[PhotoTag.entrance]!.status, PhotoUploadStatus.uploading);
      expect(viewModel.requiredPhotos[PhotoTag.approach]!.status, PhotoUploadStatus.waiting);

      repository.finishUpload(0);
      await _settle();
      await _settle();

      expect(viewModel.requiredPhotos[PhotoTag.entrance]!.isUploaded, isTrue);
      expect(viewModel.requiredPhotos[PhotoTag.entrance]!.photo.id, 'id-a');
      expect(repository.uploadOrder, ['a', 'b']);
      expect(repository.maxActiveUploads, 1);
    });

    test('업로드에 실패한 칸만 비우고 사유를 남긴다', () async {
      viewModel.setRequiredPhoto(PhotoTag.entrance, _photo('a'));
      viewModel.setRequiredPhoto(PhotoTag.approach, _photo('b'));
      await _settle();
      repository.finishUpload(0, fail: true);
      await _settle();
      await _settle();
      repository.finishUpload(1);
      await _settle();
      await _settle();

      expect(viewModel.requiredPhotos[PhotoTag.entrance], isNull);
      expect(viewModel.requiredPhotoErrors[PhotoTag.entrance], isNotNull);
      expect(viewModel.requiredPhotos[PhotoTag.approach]!.isUploaded, isTrue);
    });

    test('추가 사진 업로드가 실패하면 그 사진만 빠진다', () async {
      viewModel.addExtraPhoto(_photo('x'));
      viewModel.addExtraPhoto(_photo('y'));
      await _settle();
      repository.finishUpload(0, fail: true);
      await _settle();
      await _settle();
      repository.finishUpload(1);
      await _settle();
      await _settle();

      expect(viewModel.extraPhotos.map((p) => p.photo.name), ['y']);
      expect(viewModel.extraPhotoError, isNotNull);
    });

    test('기다리는 동안 칸을 비우면 그 사진은 올리지 않는다', () async {
      viewModel.setRequiredPhoto(PhotoTag.entrance, _photo('a'));
      viewModel.setRequiredPhoto(PhotoTag.approach, _photo('b'));
      viewModel.removeRequiredPhoto(PhotoTag.approach);
      await _settle();
      repository.finishUpload(0);
      await _settle();
      await _settle();

      expect(repository.uploadOrder, ['a']);
    });

    test('사진은 모두 10장까지다', () {
      for (final tag in PhotoTag.values) {
        viewModel.setRequiredPhoto(tag, _photo(tag.name));
      }
      for (var i = 0; i < 7; i++) {
        expect(viewModel.addExtraPhoto(_photo('e$i')), isTrue);
      }

      expect(viewModel.addExtraPhoto(_photo('over')), isFalse);
      expect(viewModel.photoCount, 10);
    });
  });

  group('이용 목적', () {
    test('여러 개를 고르고 다시 누르면 빠진다', () {
      viewModel.togglePurpose(Purpose.solo);
      viewModel.togglePurpose(Purpose.team);
      viewModel.togglePurpose(Purpose.chat);
      viewModel.togglePurpose(Purpose.chat);

      expect(viewModel.purposes, [Purpose.team, Purpose.solo]);
    });
  });

  group('테이블과 시설', () {
    test('테이블 수와 최대 인원은 공용 상한까지 받는다', () {
      viewModel.setTableCount(412);
      viewModel.setMaxPeoplePerTable(10);
      expect(viewModel.tableCount, 412);
      expect(viewModel.maxPeoplePerTable, 10);

      viewModel.setTableCount(SpaceLimits.maxTableCount + 1);
      viewModel.setMaxPeoplePerTable(SpaceLimits.maxSeatsPerTable + 1);
      expect(viewModel.tableCount, SpaceLimits.maxTableCount);
      expect(viewModel.maxPeoplePerTable, SpaceLimits.maxSeatsPerTable);
    });

    test('충전 테이블은 전체 테이블 수를 넘지 않는다', () {
      viewModel.setTableCount(3);
      expect(viewModel.chargingTableCount, 3);
      viewModel.setChargingTableCount(9);
      expect(viewModel.chargingTableCount, 3);
    });
  });

  group('조사자', () {
    test('로그인한 본인을 맨 위에 두고 기본으로 고른다', () {
      expect(viewModel.surveyorOptions.map((a) => a.name), ['Local Admin', '조사자 가', '조사자 나']);
      expect(viewModel.surveyor?.email, 'me@example.com');
    });

    test('다른 조사자를 고르면 그 이메일로 등록한다', () async {
      viewModel.selectSurveyor(repository.admins.first);
      await _fillAllSteps(viewModel, repository);

      final id = await viewModel.submit();

      expect(id, 'new-space-id');
      expect(repository.addedSurveyorEmail, 'b@example.com');
      expect(repository.addedSpace!.purposes, ['TEAM', 'CHAT']);
    });
  });

  test('사진이 올라가는 중에는 등록할 수 없다', () async {
    await _fillAllSteps(viewModel, repository, finishUploads: false);

    expect(viewModel.currentStep, 5);
    expect(viewModel.isUploadingPhotos, isTrue);
    expect(viewModel.canProceed, isFalse);
  });
}

Future<void> _fillAllSteps(
  AdminSpaceFormViewModel viewModel,
  _FakeRepository repository, {
  bool finishUploads = true,
}) async {
  for (final tag in PhotoTag.values) {
    viewModel.setRequiredPhoto(tag, _photo(tag.name));
  }
  if (finishUploads) {
    for (var i = 0; i < 3; i++) {
      await _settle();
      repository.finishUpload(i);
      await _settle();
    }
    await _settle();
  }
  viewModel.nextStep();

  viewModel
    ..setSpaceName('S1 열람실')
    ..setBuilding(Building(
      id: 'b1',
      name: '중앙도서관',
      lat: 0,
      lng: 0,
      floorRange: const FloorRange(min: -3, max: 15),
    ))
    ..setFloor(4)
    ..setDetailLocation('왼쪽 끝')
    ..togglePurpose(Purpose.team)
    ..togglePurpose(Purpose.chat)
    ..nextStep()
    ..nextStep()
    ..nextStep()
    ..setGoodPoints('좋아요')
    ..setBadPoints('아쉬워요')
    ..setMemo('비고');
}

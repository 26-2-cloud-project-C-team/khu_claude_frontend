import 'package:flutter/foundation.dart';

import '../models/admin_space.dart';
import 'selected_space_photo.dart';
import 'reinspection_request.dart';
import 'admin_space_activity.dart';

@immutable
class AdminSpaceDetail {
  const AdminSpaceDetail({
    required this.space,
    required this.photos,
    required this.purpose,
    required this.isCafe,
    required this.canTalk,
    required this.is24Hours,
    required this.startMinute,
    required this.endMinute,
    required this.noiseLevel,
    required this.tableCount,
    required this.maxPeoplePerTable,
    required this.chargingTableCount,
    required this.hasFreeWifi,
    required this.goodPoints,
    required this.badPoints,
    required this.memo,
    required this.surveyor,
    this.reinspectionRequests = const [],
    this.reinspectionResult = '',
    this.activities = const [],
  });

  final AdminSpace space;

  // 사진
  final List<SelectedSpacePhoto> photos;

  // 이용 목적 및 이용 규칙
  final String purpose;
  final bool isCafe;
  final bool canTalk;
  final bool is24Hours;
  final int startMinute;
  final int endMinute;
  final String noiseLevel;

  // 시설 정보
  final int tableCount;
  final int maxPeoplePerTable;
  final int chargingTableCount;
  final bool hasFreeWifi;

  // 현장 조사 정보
  final String goodPoints;
  final String badPoints;
  final String memo;
  final String surveyor;

  // 재조사 요청 및 활동 이력
  final List<ReinspectionRequest> reinspectionRequests;
  final String reinspectionResult;
  final List<AdminSpaceActivity> activities;

  AdminSpaceDetail copyWith({
    AdminSpace? space,
    List<SelectedSpacePhoto>? photos,
    String? purpose,
    bool? isCafe,
    bool? canTalk,
    bool? is24Hours,
    int? startMinute,
    int? endMinute,
    String? noiseLevel,
    int? tableCount,
    int? maxPeoplePerTable,
    int? chargingTableCount,
    bool? hasFreeWifi,
    String? goodPoints,
    String? badPoints,
    String? memo,
    String? surveyor,
    List<ReinspectionRequest>? reinspectionRequests,
    String? reinspectionResult,
    List<AdminSpaceActivity>? activities,
  }) {
    return AdminSpaceDetail(
      space: space ?? this.space,
      photos: photos ?? this.photos,
      purpose: purpose ?? this.purpose,
      isCafe: isCafe ?? this.isCafe,
      canTalk: canTalk ?? this.canTalk,
      is24Hours: is24Hours ?? this.is24Hours,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      noiseLevel: noiseLevel ?? this.noiseLevel,
      tableCount: tableCount ?? this.tableCount,
      maxPeoplePerTable: maxPeoplePerTable ?? this.maxPeoplePerTable,
      chargingTableCount: chargingTableCount ?? this.chargingTableCount,
      hasFreeWifi: hasFreeWifi ?? this.hasFreeWifi,
      goodPoints: goodPoints ?? this.goodPoints,
      badPoints: badPoints ?? this.badPoints,
      memo: memo ?? this.memo,
      surveyor: surveyor ?? this.surveyor,
      reinspectionRequests: reinspectionRequests ?? this.reinspectionRequests,
      reinspectionResult: reinspectionResult ?? this.reinspectionResult,
      activities: activities ?? this.activities,
    );
  }
}

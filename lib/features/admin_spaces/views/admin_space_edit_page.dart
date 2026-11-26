import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/models/building.dart';
import '../../../core/models/noise_level.dart';
import '../../../core/models/purpose.dart';
import '../../../core/models/space_photo.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/selected_space_photo_image.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_stepper.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/building_list.dart';
import '../data/admin_space_repository.dart';
import '../models/admin_space_detail.dart';
import '../models/admin_space_edit_section.dart';
import '../models/selected_space_photo.dart';
import '../models/space_limits.dart';
import '../models/space_section_edit.dart';
import '../viewmodels/admin_space_edit_view_model.dart';
import '../utils/photo_file_type.dart';

class AdminSpaceEditPage extends StatelessWidget {
  const AdminSpaceEditPage({
    super.key,
    required this.spaceId,
    required this.section,
  });

  final String spaceId;
  final AdminSpaceEditSection section;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AdminSpaceEditViewModel(
        repository: context.read<AdminSpaceRepository>(),
        spaceId: spaceId,
      )..load(),
      child: _AdminSpaceEditView(section: section),
    );
  }
}

class _AdminSpaceEditView extends StatelessWidget {
  const _AdminSpaceEditView({required this.section});

  final AdminSpaceEditSection section;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: '닫기',
          onPressed: () => Navigator.of(context).maybePop(false),
          icon: const Icon(Icons.close),
        ),
        title: Text('부분 수정', style: AppTypography.h2),
        centerTitle: false,
      ),
      body: Consumer<AdminSpaceEditViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading && viewModel.detail == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (viewModel.detail == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: Text(
                  viewModel.errorMessage ?? '공간 정보를 찾을 수 없습니다.',
                  style: AppTypography.body1,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return _AdminSpaceEditForm(
            key: ValueKey('${viewModel.detail!.space.id}-${section.name}'),
            detail: viewModel.detail!,
            section: section,
            isSaving: viewModel.isSaving,
            onSave: (updatedDetail) async {
              final success = await viewModel.save(
                updatedDetail,
                sectionLabel: section.label,
              );
              if (!context.mounted) return;
              if (success) {
                Navigator.of(context).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      viewModel.errorMessage ?? '수정 내용을 저장하지 못했습니다.',
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class _AdminSpaceEditForm extends StatefulWidget {
  const _AdminSpaceEditForm({
    super.key,
    required this.detail,
    required this.section,
    required this.isSaving,
    required this.onSave,
  });

  final AdminSpaceDetail detail;
  final AdminSpaceEditSection section;
  final bool isSaving;
  final ValueChanged<AdminSpaceDetail> onSave;

  @override
  State<_AdminSpaceEditForm> createState() => _AdminSpaceEditFormState();
}

class _AdminSpaceEditFormState extends State<_AdminSpaceEditForm> {
  final _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _goodPointsController;
  late final TextEditingController _badPointsController;
  late final TextEditingController _memoController;

  late Set<Purpose> _purposes;
  String? _buildingId;
  String? _buildingName;
  int? _floor;
  FloorRange _floorRange = const FloorRange(min: -3, max: 15);

  late final List<SelectedSpacePhoto?> _requiredPhotos;
  late final List<SelectedSpacePhoto> _extraPhotos;
  late bool _isCafe;
  late bool _canTalk;
  late bool _is24Hours;
  late int _startMinute;
  late int _endMinute;
  late int _backupStartMinute;
  late int _backupEndMinute;
  late String _noiseLevel;
  late int _tableCount;
  late int _maxPeoplePerTable;
  late int _chargingTableCount;
  late bool _hasFreeWifi;
  String? _photoError;

  @override
  void initState() {
    super.initState();
    final detail = widget.detail;
    _nameController = TextEditingController(text: detail.space.name);
    _locationController = TextEditingController(
      text: detail.space.locationDetail ?? detail.space.location,
    );
    _purposes = purposesOf(detail);
    _buildingId = detail.space.buildingId;
    _buildingName = detail.space.buildingName;
    _floor = detail.space.floor;
    _goodPointsController = TextEditingController(text: detail.goodPoints);
    _badPointsController = TextEditingController(text: detail.badPoints);
    _memoController = TextEditingController(text: detail.memo);

    _requiredPhotos = List<SelectedSpacePhoto?>.generate(
      3,
      (index) => index < detail.photos.length ? detail.photos[index] : null,
    );
    _extraPhotos = detail.photos.length > 3
        ? detail.photos.sublist(3).toList()
        : <SelectedSpacePhoto>[];
    _isCafe = detail.isCafe;
    _canTalk = detail.canTalk;
    _is24Hours = detail.is24Hours;
    _startMinute = detail.startMinute;
    _endMinute = detail.endMinute;
    _backupStartMinute = detail.is24Hours ? 9 * 60 : detail.startMinute;
    _backupEndMinute = detail.is24Hours ? 22 * 60 : detail.endMinute;
    _noiseLevel = detail.noiseLevel;
    _tableCount = detail.tableCount;
    _maxPeoplePerTable = detail.maxPeoplePerTable;
    _chargingTableCount = detail.chargingTableCount;
    _hasFreeWifi = detail.hasFreeWifi;

    for (final controller in [
      _nameController,
      _locationController,
      _goodPointsController,
      _badPointsController,
      _memoController,
    ]) {
      controller.addListener(_onInputChanged);
    }
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _goodPointsController.dispose();
    _badPointsController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              16,
              AppSpacing.screenHorizontal,
              AppSpacing.section,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.section.title, style: AppTypography.h2),
                const SizedBox(height: 20),
                _buildSectionFields(),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: AppButton(
                label: widget.isSaving ? '저장 중...' : '고친 내용 반영하기',
                onPressed: widget.isSaving || !_canSave ? null : _save,
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool get _canSave {
    final edited = _editedDetail();
    return isSectionValid(widget.section, edited) &&
        hasSectionChanged(widget.section, widget.detail, edited);
  }

  Widget _buildSectionFields() {
    switch (widget.section) {
      case AdminSpaceEditSection.location:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FieldLabel('공간 이름'),
            AppTextField(controller: _nameController, maxLength: 40),
            const SizedBox(height: 20),
            _FieldLabel('건물'),
            _SelectField(
              value: _buildingName ?? '선택',
              isSelected: _buildingId != null,
              onTap: _selectBuilding,
            ),
            const SizedBox(height: 20),
            _FieldLabel('층'),
            _SelectField(
              value: _floor == null ? '선택' : _floorLabel(_floor!),
              isSelected: _floor != null,
              onTap: _buildingId == null ? null : _selectFloor,
            ),
            const SizedBox(height: 20),
            _FieldLabel('상세 위치'),
            AppTextField(controller: _locationController, maxLength: 40),
            const SizedBox(height: 20),
            _FieldLabel('어울리는 이용 목적 · 1개 이상'),
            for (final purpose in Purpose.values) ...[
              _PurposeOption(
                label: purpose.label,
                selected: _purposes.contains(purpose),
                onTap: () => setState(() {
                  if (!_purposes.remove(purpose)) _purposes.add(purpose);
                }),
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      case AdminSpaceEditSection.photos:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < PhotoTag.values.length; index++) ...[
              _PhotoEditTile(
                label: PhotoTag.values[index].label,
                photo: _requiredPhotos[index],
                onTap: () => _pickRequiredPhoto(index),
                onRemove: _requiredPhotos[index] == null
                    ? null
                    : () => setState(() => _requiredPhotos[index] = null),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: _requiredPhotos.length + _extraPhotos.length >= 10
                  ? null
                  : _pickExtraPhoto,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('추가 사진 올리기'),
            ),
            if (_extraPhotos.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (var index = 0; index < _extraPhotos.length; index++) ...[
                _PhotoEditTile(
                  label: '추가 사진 ${index + 1}',
                  photo: _extraPhotos[index],
                  onTap: () => _pickExtraPhoto(replaceIndex: index),
                  onRemove: () => setState(() => _extraPhotos.removeAt(index)),
                ),
                const SizedBox(height: 10),
              ],
            ],
            if (_photoError != null) ...[
              const SizedBox(height: 8),
              Text(
                _photoError!,
                style: AppTypography.caption.copyWith(color: AppColors.primary),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '입구, 가는 길, 내부 사진은 필수입니다. (최대 10장)',
              style: AppTypography.caption,
            ),
          ],
        );
      case AdminSpaceEditSection.rules:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ToggleEditRow(
              title: '카페',
              value: _isCafe,
              onChanged: (value) => setState(() => _isCafe = value),
            ),
            const Divider(height: 1, color: AppColors.gray200),
            _ToggleEditRow(
              title: '대화 가능',
              value: _canTalk,
              onChanged: (value) => setState(() => _canTalk = value),
            ),
            const SizedBox(height: 20),
            _FieldLabel('이용 가능 시간'),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('24시간 이용'),
              value: _is24Hours,
              activeTrackColor: AppColors.positive,
              onChanged: (value) => setState(() {
                _is24Hours = value;
                if (value) {
                  _backupStartMinute = _startMinute;
                  _backupEndMinute = _endMinute;
                  _startMinute = 0;
                  _endMinute = 1440;
                } else {
                  _startMinute = _backupStartMinute;
                  _endMinute = _backupEndMinute;
                }
              }),
            ),
            if (!_is24Hours) ...[
              Row(
                children: [
                  Expanded(
                    child: _TimeEditButton(
                      label: '시작',
                      minute: _startMinute,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeEditButton(
                      label: '종료',
                      minute: _endMinute,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              if (_endMinute <= _startMinute) ...[
                const SizedBox(height: 6),
                Text(
                  '종료 시간은 시작 시간보다 늦어야 합니다.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 20),
            _FieldLabel('조용한 정도'),
            Wrap(
              spacing: 8,
              children: [
                for (final level in NoiseLevel.values)
                  ChoiceChip(
                    label: Text(level.label),
                    selected: _noiseLevel == level.label,
                    onSelected: (_) =>
                        setState(() => _noiseLevel = level.label),
                    selectedColor: AppColors.primaryTint,
                    labelStyle: AppTypography.label.copyWith(
                      color: _noiseLevel == level.label
                          ? AppColors.primary
                          : AppColors.gray700,
                    ),
                    side: BorderSide(
                      color: _noiseLevel == level.label
                          ? AppColors.primary
                          : AppColors.gray200,
                    ),
                  ),
              ],
            ),
          ],
        );
      case AdminSpaceEditSection.facilities:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('테이블 정보', style: AppTypography.h3),
            const SizedBox(height: 12),
            AppStepperRow(
              label: '테이블',
              value: _tableCount,
              min: 1,
              max: math.max(SpaceLimits.maxTableCount, widget.detail.tableCount),
              unit: '개',
              onChanged: _setTableCount,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _enterTableCount,
                child: const Text('테이블 수 직접 입력'),
              ),
            ),
            const SizedBox(height: 12),
            AppStepperRow(
              label: '한 테이블 최대 인원',
              value: _maxPeoplePerTable,
              min: 1,
              max: math.max(
                SpaceLimits.maxSeatsPerTable,
                widget.detail.maxPeoplePerTable,
              ),
              unit: '명',
              onChanged: (value) => setState(() => _maxPeoplePerTable = value),
            ),
            const SizedBox(height: 12),
            AppStepperRow(
              label: '충전되는 테이블',
              value: _chargingTableCount,
              min: 0,
              max: _tableCount,
              unit: '개',
              onChanged: (value) => setState(() => _chargingTableCount = value),
            ),
            const SizedBox(height: 28),
            Text('편의시설', style: AppTypography.h3),
            const SizedBox(height: 12),
            _ToggleEditRow(
              title: '무료 와이파이',
              value: _hasFreeWifi,
              onChanged: (value) => setState(() => _hasFreeWifi = value),
            ),
          ],
        );
      case AdminSpaceEditSection.fieldSurvey:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FieldLabel('좋았던 점'),
            AppTextField(
              controller: _goodPointsController,
              maxLength: 40,
              lines: 3,
            ),
            const SizedBox(height: 20),
            _FieldLabel('아쉬웠던 점'),
            AppTextField(
              controller: _badPointsController,
              maxLength: 40,
              lines: 3,
            ),
            const SizedBox(height: 20),
            _FieldLabel('비고'),
            AppTextField(controller: _memoController, maxLength: 100, lines: 3),
            const SizedBox(height: 8),
            Text('조사자는 로그인 계정으로 자동 기록됩니다.', style: AppTypography.caption),
          ],
        );
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _startMinute : _endMinute;
    final initial = TimeOfDay(
      hour: current == 1440 ? 23 : current ~/ 60,
      // 백엔드 시간 형식은 30분 단위다. 24:00은 23:45로 열어
      // 그대로 확인했을 때 24:00으로 반올림되도록 한다.
      minute: current == 1440 ? 45 : (current % 60),
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (!mounted || picked == null) return;
    setState(() {
      final roundedMinutes = ((picked.hour * 60 + picked.minute + 15) ~/ 30) * 30;
      final minutes = roundedMinutes.clamp(0, isStart ? 1410 : 1440).toInt();
      if (isStart) {
        _startMinute = minutes;
      } else {
        _endMinute = minutes;
      }
    });
  }

  
  Future<SelectedSpacePhoto> _convertPhoto(XFile file) async {
    final sourceBytes = await file.readAsBytes();
    final type = PhotoFileType.validate(sourceBytes);

    return SelectedSpacePhoto(
      name: 'photo.${type.extension}',
      mimeType: type.mimeType,
      bytes: sourceBytes,
    );
  }

  Future<SelectedSpacePhoto?> _pickPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (file == null) return null;

    return _convertPhoto(file);
  }


  Future<void> _pickRequiredPhoto(int index) async {
    try {
      final photo = await _pickPhoto();
      if (!mounted || photo == null) return;
      setState(() {
        _requiredPhotos[index] = photo;
        _photoError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _photoError = error is FormatException
            ? error.message
            : '사진을 불러오지 못했어요. 다시 시도해주세요.',
      );
    }
  }

  
  Future<void> _pickExtraPhoto({int? replaceIndex}) async {
    try {
      // 기존 사진 교체는 한 장만 선택
      if (replaceIndex != null) {
        final photo = await _pickPhoto();

        if (!mounted || photo == null) return;

        setState(() {
          _extraPhotos[replaceIndex] = photo;
          _photoError = null;
        });

        return;
      }

      // 새 사진 추가는 여러 장 선택
      final requiredCount =
          _requiredPhotos.where((photo) => photo != null).length;

      final remaining = 10 - requiredCount - _extraPhotos.length;

      if (remaining <= 0) {
        setState(() => _photoError = '사진은 최대 10장까지 선택할 수 있습니다.');
        return;
      }

      final files = await _picker.pickMultiImage(
        limit: remaining,
      );

      if (!mounted || files.isEmpty) return;

      final convertedPhotos = <SelectedSpacePhoto>[];
      String? lastError;

      for (final file in files) {
        try {
          convertedPhotos.add(await _convertPhoto(file));
        } catch (error) {
          lastError = error is FormatException
              ? error.message
              : '사진을 변환하지 못했습니다.';
        }
      }

      if (!mounted) return;

      setState(() {
        _extraPhotos.addAll(convertedPhotos);
        _photoError = lastError;
      });
    } catch (error) {
      if (!mounted) return;

      setState(
        () => _photoError = error is FormatException
            ? error.message
            : '사진을 불러오지 못했습니다. 다시 시도해주세요.',
      );
    }
  }


  void _setTableCount(int value) => setState(() {
    _tableCount = value;
    if (_chargingTableCount > value) _chargingTableCount = value;
  });

  Future<void> _enterTableCount() async {
    final max = math.max(SpaceLimits.maxTableCount, widget.detail.tableCount);
    final value = await showDialog<int>(
      context: context,
      builder: (context) => _NumberInputDialog(
        title: '테이블 수를 입력해주세요',
        initial: _tableCount,
        min: 1,
        max: max,
      ),
    );
    if (!mounted || value == null) return;
    _setTableCount(value);
  }

  Future<void> _selectBuilding() async {
    final buildings = await context.read<AdminSpaceEditViewModel>().loadBuildings();
    if (!mounted) return;
    if (buildings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('건물 목록을 불러오지 못했어요.')),
      );
      return;
    }
    final current = buildings.where((b) => b.id == _buildingId).firstOrNull;
    final picked = await showBuildingSelectSheet(
      context: context,
      title: '건물을 선택해주세요',
      buildings: buildings,
      selected: current,
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (picked.id != _buildingId) _floor = null;
      _buildingId = picked.id;
      _buildingName = picked.name;
      _floorRange = picked.floorRange;
    });
  }

  Future<void> _selectFloor() async {
    final buildings = context.read<AdminSpaceEditViewModel>().buildings;
    final building = buildings.where((b) => b.id == _buildingId).firstOrNull;
    final range = building?.floorRange ?? _floorRange;
    final picked = await showAppSelectSheet<int>(
      context: context,
      title: '층을 선택해주세요',
      subtitle: _buildingName,
      options: range.floors,
      selected: _floor,
      labelOf: _floorLabel,
      expanded: true,
    );
    if (!mounted || picked == null) return;
    setState(() => _floor = picked);
  }

  AdminSpaceDetail _editedDetail() {
    final current = widget.detail;

    switch (widget.section) {
      case AdminSpaceEditSection.location:
        final purposes = Purpose.values.where(_purposes.contains).toList();
        final floor = _floor;
        final floorText = floor == null ? '' : _floorLabel(floor);
        final detailText = _locationController.text.trim();
        return current.copyWith(
          space: current.space.copyWith(
            name: _nameController.text.trim(),
            locationDetail: detailText,
            buildingId: _buildingId,
            buildingName: _buildingName,
            floor: floor,
            purposes: [for (final p in purposes) p.code],
            location: [
              _buildingName ?? '',
              floorText,
              detailText,
            ].where((part) => part.isNotEmpty).join(' · '),
          ),
          purpose: purposes.map((p) => p.label).join(', '),
        );
      case AdminSpaceEditSection.photos:
        return current.copyWith(
          photos: [
            for (final photo in _requiredPhotos)
              ?photo,
            ..._extraPhotos,
          ],
        );
      case AdminSpaceEditSection.rules:
        return current.copyWith(
          isCafe: _isCafe,
          canTalk: _canTalk,
          is24Hours: _is24Hours,
          startMinute: _is24Hours ? 0 : _startMinute,
          endMinute: _is24Hours ? 1440 : _endMinute,
          noiseLevel: _noiseLevel,
        );
      case AdminSpaceEditSection.facilities:
        return current.copyWith(
          tableCount: _tableCount,
          maxPeoplePerTable: _maxPeoplePerTable,
          chargingTableCount: _chargingTableCount,
          hasFreeWifi: _hasFreeWifi,
        );
      case AdminSpaceEditSection.fieldSurvey:
        return current.copyWith(
          goodPoints: _goodPointsController.text.trim(),
          badPoints: _badPointsController.text.trim(),
          memo: _memoController.text.trim(),
        );
    }
  }

  void _save() => widget.onSave(_editedDetail());
}

String _floorLabel(int floor) => floor < 0 ? '지하 ${floor.abs()}층' : '$floor층';

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  final String value;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? AppColors.gray50 : AppColors.gray100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: AppTypography.body1.copyWith(
                    color: isSelected && enabled
                        ? AppColors.gray900
                        : AppColors.gray400,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: AppColors.gray500),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurposeOption extends StatelessWidget {
  const _PurposeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: selected,
      child: Material(
        color: selected ? AppColors.primaryTint : AppColors.gray50,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.gray200,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.body1.copyWith(
                      color: selected ? AppColors.primary : AppColors.gray900,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberInputDialog extends StatefulWidget {
  const _NumberInputDialog({
    required this.title,
    required this.initial,
    required this.min,
    required this.max,
  });

  final String title;
  final int initial;
  final int min;
  final int max;

  @override
  State<_NumberInputDialog> createState() => _NumberInputDialogState();
}

class _NumberInputDialogState extends State<_NumberInputDialog> {
  late final _controller = TextEditingController(text: '${widget.initial}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _value {
    final value = int.tryParse(_controller.text);
    if (value == null || value < widget.min || value > widget.max) return null;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: AppTypography.h3),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          helperText: '${widget.min}~${widget.max}',
        ),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _value == null
              ? null
              : () => Navigator.of(context).pop(_value),
          child: const Text('확인'),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: AppTypography.label.copyWith(color: AppColors.gray700),
      ),
    );
  }
}

class _ToggleEditRow extends StatelessWidget {
  const _ToggleEditRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTypography.body1),
      value: value,
      activeTrackColor: AppColors.positive,
      onChanged: onChanged,
    );
  }
}

class _TimeEditButton extends StatelessWidget {
  const _TimeEditButton({
    required this.label,
    required this.minute,
    required this.onTap,
  });

  final String label;
  final int minute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hour = minute == 1440 ? 24 : minute ~/ 60;
    final minutes = minute == 1440 ? 0 : minute % 60;
    final value =
        '${hour.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: AppColors.gray900,
        side: const BorderSide(color: AppColors.gray200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text('$label  $value', style: AppTypography.body2),
    );
  }
}

class _PhotoEditTile extends StatelessWidget {
  const _PhotoEditTile({
    required this.label,
    required this.photo,
    required this.onTap,
    required this.onRemove,
  });

  final String label;
  final SelectedSpacePhoto? photo;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gray50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 62,
                  height: 62,
                  child: photo == null
                      ? const ColoredBox(
                          color: AppColors.gray200,
                          child: Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.gray500,
                          ),
                        )
                      : SelectedSpacePhotoImage(
                          photo: photo!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.gray400,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.body1),
                    const SizedBox(height: 4),
                    Text(
                      photo?.name ?? '사진 선택하기',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: '사진 삭제',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, color: AppColors.gray500),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

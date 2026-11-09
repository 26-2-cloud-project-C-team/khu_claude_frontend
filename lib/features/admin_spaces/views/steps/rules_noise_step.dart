import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/noise_level.dart';
import '../../viewmodels/admin_space_form_view_model.dart';

class RulesNoiseStep extends StatelessWidget {
  const RulesNoiseStep({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminSpaceFormViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ToggleRow(
          title: '카페',
          value: viewModel.cafeEnabled,
          onChanged: viewModel.updateCafeEnabled,
        ),
        const Divider(height: 1),
        _ToggleRow(
          title: '대화 가능',
          value: viewModel.conversationEnabled,
          onChanged: viewModel.updateConversationEnabled,
        ),
        const SizedBox(height: 28),

        const _SectionTitle(title: '이용 가능 시간'),
        const SizedBox(height: 10),

        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openHoursPicker(context, viewModel),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTime(viewModel.startMinutes),
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '시작 시간  ·  종료 시간',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text(
                  viewModel.is24Hours
                      ? '24시간 이용'
                      : '${_formatTime(viewModel.startMinutes)} – '
                            '${_formatTime(viewModel.endMinutes)}',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),
        const _SectionTitle(title: '조용한 정도'),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: NoiseLevel.values.map((level) {
            final selected = viewModel.noiseLevel == level;

            return ChoiceChip(
              label: Text(_noiseLabel(level)),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => viewModel.updateNoiseLevel(level),
              selectedColor: colorScheme.primary.withValues(alpha: 0.10),
              backgroundColor: colorScheme.surface,
              side: BorderSide(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
              labelStyle: TextStyle(
                color: selected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _openHoursPicker(
    BuildContext context,
    AdminSpaceFormViewModel viewModel,
  ) async {
    final result = await showModalBottomSheet<_HoursSelection>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OperatingHoursSheet(
        startMinutes: viewModel.startMinutes,
        endMinutes: viewModel.endMinutes,
        is24Hours: viewModel.is24Hours,
      ),
    );

    if (result == null) return;

    if (result.is24Hours) {
      viewModel.update24HourAvailability(true);
    } else {
      viewModel.updateOperatingHours(
        startMinutes: result.startMinutes,
        endMinutes: result.endMinutes,
      );
    }
  }

  static String _formatTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  static String _noiseLabel(NoiseLevel level) {
    switch (level) {
      case NoiseLevel.quiet:
        return '조용함';
      case NoiseLevel.normal:
        return '보통';
      case NoiseLevel.loud:
        return '시끄러움';
    }
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _HoursSelection {
  const _HoursSelection({
    required this.startMinutes,
    required this.endMinutes,
    required this.is24Hours,
  });

  final int startMinutes;
  final int endMinutes;
  final bool is24Hours;
}

class _OperatingHoursSheet extends StatefulWidget {
  const _OperatingHoursSheet({
    required this.startMinutes,
    required this.endMinutes,
    required this.is24Hours,
  });

  final int startMinutes;
  final int endMinutes;
  final bool is24Hours;

  @override
  State<_OperatingHoursSheet> createState() => _OperatingHoursSheetState();
}

class _OperatingHoursSheetState extends State<_OperatingHoursSheet> {
  late int _start;
  late int _end;
  late int _backupStart;
  late int _backupEnd;
  late bool _is24Hours;
  bool _selectingEnd = false;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  int get _activeMinutes => _selectingEnd ? _end : _start;

  @override
  void initState() {
    super.initState();

    _is24Hours = widget.is24Hours;

    _start = widget.is24Hours ? 9 * 60 : widget.startMinutes;
    _end = widget.is24Hours ? 22 * 60 : widget.endMinutes;

    _backupStart = _start;
    _backupEnd = _end;

    _hourController = FixedExtentScrollController(initialItem: _end ~/ 60);
    _minuteController = FixedExtentScrollController(
      initialItem: (_end % 60) ~/ 30,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _selectTime(bool selectingEnd) {
    setState(() {
      _selectingEnd = selectingEnd;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _is24Hours) return;

      _hourController.jumpToItem(_activeMinutes ~/ 60);
      _minuteController.jumpToItem((_activeMinutes % 60) ~/ 30);
    });
  }

  void _changeHour(int hour) {
    final minute = hour == 24 && _selectingEnd ? 0 : _activeMinutes % 60;

    if (hour == 24 && _selectingEnd) {
      _minuteController.jumpToItem(0);
    }

    setState(() {
      final value = hour * 60 + minute;

      if (_selectingEnd) {
        _end = value;
      } else {
        _start = value;
      }
    });
  }

  void _changeMinute(int index) {
    final hour = _activeMinutes ~/ 60;

    if (_selectingEnd && hour == 24) return;

    setState(() {
      final value = hour * 60 + index * 30;

      if (_selectingEnd) {
        _end = value;
      } else {
        _start = value;
      }
    });
  }

  void _toggle24Hours(bool value) {
    setState(() {
      _is24Hours = value;

      if (value) {
        _backupStart = _start;
        _backupEnd = _end;
        _start = 0;
        _end = 1440;
        _selectingEnd = true;
      } else {
        _start = _backupStart;
        _end = _backupEnd;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _is24Hours) return;

      _hourController.jumpToItem(_activeMinutes ~/ 60);
      _minuteController.jumpToItem((_activeMinutes % 60) ~/ 30);
    });
  }

  String _format(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeHour = _activeMinutes ~/ 60;
    final minuteCount = _selectingEnd && activeHour == 24 ? 1 : 2;
    final validHours = _is24Hours || _end > _start;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '이용 가능 시간을 선택해주세요',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _TimeTarget(
                  title: '시작',
                  time: _format(_start),
                  selected: !_selectingEnd,
                  onTap: () => _selectTime(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeTarget(
                  title: '종료',
                  time: _format(_end),
                  selected: _selectingEnd,
                  onTap: () => _selectTime(true),
                ),
              ),
            ],
          ),

          if (!_is24Hours) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: _hourController,
                      itemExtent: 38,
                      useMagnifier: true,
                      magnification: 1.12,
                      onSelectedItemChanged: _changeHour,
                      children: List.generate(
                        _selectingEnd ? 25 : 24,
                        (index) => Center(
                          child: Text(
                            index.toString().padLeft(2, '0'),
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Text('시'),
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: _minuteController,
                      itemExtent: 38,
                      useMagnifier: true,
                      magnification: 1.12,
                      onSelectedItemChanged: _changeMinute,
                      children: List.generate(
                        minuteCount,
                        (index) => Center(
                          child: Text(
                            (index * 30).toString().padLeft(2, '0'),
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Text('분'),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 28),
            const Text('00:00부터 24:00까지 이용할 수 있습니다.'),
            const SizedBox(height: 28),
          ],

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('24시간 이용'),
            value: _is24Hours,
            onChanged: _toggle24Hours,
          ),

          if (!_is24Hours && _end <= _start)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '종료 시간은 시작 시간보다 늦어야 합니다.',
                style: TextStyle(color: colorScheme.error),
              ),
            ),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: validHours
                  ? () {
                      Navigator.pop(
                        context,
                        _HoursSelection(
                          startMinutes: _start,
                          endMinutes: _end,
                          is24Hours: _is24Hours,
                        ),
                      );
                    }
                  : null,
              child: const Text('확인'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeTarget extends StatelessWidget {
  const _TimeTarget({
    required this.title,
    required this.time,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String time;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.06)
              : colorScheme.surface,
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              time,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

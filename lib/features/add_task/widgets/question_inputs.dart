import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/time_format.dart';
import '../../../domain/entities/day_schedule.dart';
import '../../../domain/entities/subject.dart';

// ───────────────── Name input ─────────────────────────────────────────
class NameInput extends StatefulWidget {
  const NameInput({required this.onSubmit, super.key});

  final ValueChanged<String> onSubmit;

  @override
  State<NameInput> createState() => _NameInputState();
}

class _NameInputState extends State<NameInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.tab1Primary, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                hintText: 'Escribe el nombre…',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          _SendButton(onTap: _send),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.tab1Accent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.send_rounded, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

// ───────────────── Subject picker ─────────────────────────────────────
class SubjectPicker extends StatelessWidget {
  const SubjectPicker({
    required this.subjects,
    required this.onSelect,
    super.key,
  });

  final List<Subject> subjects;
  final ValueChanged<Subject> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in subjects)
          InkWell(
            onTap: () => onSelect(s),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Color(s.colorValue).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                s.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.graphite,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

// ───────────────── Date picker ────────────────────────────────────────
class DueDatePicker extends StatefulWidget {
  const DueDatePicker({required this.onSubmit, super.key});

  final ValueChanged<DateTime> onSubmit;

  @override
  State<DueDatePicker> createState() => _DueDatePickerState();
}

class _DueDatePickerState extends State<DueDatePicker> {
  DateTime? _picked;

  Future<void> _openPicker() async {
    final today = dateOnly(DateTime.now());
    final result = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDate: _picked ?? today,
      locale: const Locale('es'),
    );
    if (result != null) setState(() => _picked = result);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _openPicker,
            icon: const Icon(Icons.event_rounded, size: 18),
            label: Text(
              _picked == null
                  ? 'Elegir fecha'
                  : TimeFormat.fullDate(_picked!),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.graphite,
              side: const BorderSide(color: AppColors.tab1Primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _ConfirmButton(
          enabled: _picked != null,
          onTap: () {
            if (_picked != null) widget.onSubmit(_picked!);
          },
        ),
      ],
    );
  }
}

// ───────────────── Difficulty picker ──────────────────────────────────
class DifficultyPicker extends StatefulWidget {
  const DifficultyPicker({
    required this.color,
    required this.onSubmit,
    super.key,
  });

  final Color color;
  final ValueChanged<int> onSubmit;

  @override
  State<DifficultyPicker> createState() => _DifficultyPickerState();
}

class _DifficultyPickerState extends State<DifficultyPicker> {
  int _value = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 1; i <= 5; i++)
                  InkResponse(
                    onTap: () => setState(() => _value = i),
                    radius: 22,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _value >= i ? widget.color : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _value >= i
                              ? widget.color
                              : AppColors.warmGray,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '$i',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _value >= i
                              ? Colors.white
                              : AppColors.graphiteSoft,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ConfirmButton(
            enabled: _value >= 1,
            onTap: () => widget.onSubmit(_value),
          ),
        ],
      ),
    );
  }
}

// ───────────────── Duration picker ────────────────────────────────────
class DurationPicker extends StatefulWidget {
  const DurationPicker({required this.onSubmit, super.key});

  final ValueChanged<int> onSubmit;

  @override
  State<DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  int _minutes = 60;

  void _adjust(int delta) {
    final next = (_minutes + delta).clamp(30, 600);
    setState(() => _minutes = next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            onTap: _minutes > 30 ? () => _adjust(-30) : null,
          ),
          Expanded(
            child: Center(
              child: Text(
                TimeFormat.duration(_minutes),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.graphite,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            onTap: _minutes < 600 ? () => _adjust(30) : null,
          ),
          const SizedBox(width: 8),
          _ConfirmButton(
            enabled: true,
            onTap: () => widget.onSubmit(_minutes),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? AppColors.tab1Tint : AppColors.warmGray,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.tab1Accent : AppColors.graphiteSoft,
          ),
        ),
      ),
    );
  }
}

// ───────────────── Discard days picker ────────────────────────────────
class DiscardDaysPicker extends StatelessWidget {
  const DiscardDaysPicker({
    required this.days,
    required this.discarded,
    required this.onToggle,
    required this.onConfirm,
    super.key,
  });

  final List<DateTime> days;
  final List<DateTime> discarded;
  final ValueChanged<DateTime> onToggle;
  final VoidCallback onConfirm;

  bool _isDiscarded(DateTime d) =>
      discarded.any((x) => x.isAtSameMomentAs(d));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in days)
                    _DayChip(
                      date: d,
                      discarded: _isDiscarded(d),
                      onTap: () => onToggle(d),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Toca un día para descartarlo.',
                  style: TextStyle(
                    color: AppColors.graphiteSoft,
                    fontSize: 12,
                  ),
                ),
              ),
              _ConfirmButton(enabled: true, onTap: onConfirm),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.date,
    required this.discarded,
    required this.onTap,
  });

  final DateTime date;
  final bool discarded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weekday = TimeFormat.weekdayShort(date);
    final day = date.day.toString();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: discarded ? AppColors.warmGray : AppColors.tab1Tint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: discarded ? AppColors.graphiteSoft : AppColors.tab1Primary,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              weekday,
              style: TextStyle(
                fontSize: 11,
                color: discarded
                    ? AppColors.graphiteSoft
                    : AppColors.graphite,
                decoration:
                    discarded ? TextDecoration.lineThrough : null,
              ),
            ),
            Text(
              day,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: discarded
                    ? AppColors.graphiteSoft
                    : AppColors.graphite,
                decoration:
                    discarded ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────── Time range picker ──────────────────────────────────
class TimeRangePicker extends StatefulWidget {
  const TimeRangePicker({
    required this.prefill,
    required this.onSubmit,
    this.minStartMinutes = 0,
    super.key,
  });

  final DaySchedule? prefill;
  final int minStartMinutes;
  final void Function(int startMinutes, int endMinutes) onSubmit;

  @override
  State<TimeRangePicker> createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<TimeRangePicker> {
  late int _startMinutes;
  late int _endMinutes;

  static const int _minutesInDay = 24 * 60;

  @override
  void initState() {
    super.initState();
    _applyInitialFromWidget();
  }

  @override
  void didUpdateWidget(covariant TimeRangePicker old) {
    super.didUpdateWidget(old);
    if (old.prefill != widget.prefill ||
        old.minStartMinutes != widget.minStartMinutes) {
      _applyInitialFromWidget();
    }
  }

  void _applyInitialFromWidget() {
    final basePrefillStart = widget.prefill?.startMinutes ?? 14 * 60;
    final basePrefillEnd = widget.prefill?.endMinutes ?? 18 * 60;
    _startMinutes = math.max(basePrefillStart, widget.minStartMinutes);
    _endMinutes = basePrefillEnd;
    if (_endMinutes <= _startMinutes) {
      _endMinutes = math.min(_startMinutes + 60, _minutesInDay);
    }
  }

  Future<void> _pickStart() async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _startMinutes ~/ 60,
        minute: _startMinutes % 60,
      ),
    );
    if (result == null) return;
    final rounded = _round(result);
    final next = math.max(rounded, widget.minStartMinutes);
    setState(() {
      _startMinutes = next;
      if (_endMinutes <= _startMinutes) {
        _endMinutes = math.min(_startMinutes + 60, _minutesInDay);
      }
    });
  }

  Future<void> _pickEnd() async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _endMinutes ~/ 60,
        minute: _endMinutes % 60,
      ),
    );
    if (result == null) return;
    final next = result.hour * 60 + result.minute;
    if (next <= _startMinutes) return;
    setState(() => _endMinutes = next);
  }

  int _round(TimeOfDay t) {
    final total = t.hour * 60 + t.minute;
    return (total / 30).round() * 30;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TimeChip(
              label: 'Inicio',
              minutes: _startMinutes,
              onTap: _pickStart,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TimeChip(
              label: 'Fin',
              minutes: _endMinutes,
              onTap: _pickEnd,
            ),
          ),
          const SizedBox(width: 8),
          _ConfirmButton(
            enabled: _endMinutes > _startMinutes,
            onTap: () => widget.onSubmit(_startMinutes, _endMinutes),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.minutes,
    required this.onTap,
  });

  final String label;
  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.tab1Tint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.tab1Primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.graphiteSoft,
              ),
            ),
            Text(
              TimeFormat.minutesToClock(minutes),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.graphite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────── Confirm button (shared) ────────────────────────────
class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.tab1Accent : AppColors.warmGray,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.check_rounded,
            size: 22,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

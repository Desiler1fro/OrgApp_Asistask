import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/time_format.dart';
import '../../../data/repositories/task_repository_provider.dart';
import '../../../domain/entities/availability_slot.dart';
import '../../../domain/entities/task.dart';

/// Bottom sheet de edición de una tarea existente.
///
/// Permite modificar dificultad, tiempo estimado y los rangos horarios
/// de cada slot asignado. Al guardar, llama a `updateFields` y el
/// listado se recomputa automáticamente vía Riverpod.
class EditTaskSheet extends ConsumerStatefulWidget {
  const EditTaskSheet({
    required this.task,
    required this.slots,
    super.key,
  });

  final Task task;
  final List<AvailabilitySlot> slots;

  static Future<void> show(
    BuildContext context, {
    required Task task,
    required List<AvailabilitySlot> slots,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditTaskSheet(task: task, slots: slots),
    );
  }

  @override
  ConsumerState<EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends ConsumerState<EditTaskSheet> {
  late int _difficulty;
  late int _estimatedMinutes;
  late int _workedMinutes;
  late List<_DraftSlot> _slots;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _difficulty = widget.task.difficulty;
    _estimatedMinutes = widget.task.estimatedMinutes;
    _workedMinutes = widget.task.workedMinutes;
    _slots = widget.slots
        .map(
          (s) => _DraftSlot(
            date: s.date,
            startMinutes: s.startMinutes,
            endMinutes: s.endMinutes,
          ),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  bool get _isValid {
    if (_estimatedMinutes < 30) return false;
    for (final s in _slots) {
      if (s.endMinutes <= s.startMinutes) return false;
      if (s.endMinutes - s.startMinutes < 30) return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_isValid || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(taskRepositoryProvider).updateFields(
            taskId: widget.task.id,
            difficulty: _difficulty,
            estimatedMinutes: _estimatedMinutes,
            workedMinutes: _workedMinutes,
            slots: _slots
                .map(
                  (s) => AvailabilitySlotInput(
                    date: s.date,
                    startMinutes: s.startMinutes,
                    endMinutes: s.endMinutes,
                  ),
                )
                .toList(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'No se pudo guardar. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.warmGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Editar tarea',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.graphite,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.task.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.graphiteSoft,
                    ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('Dificultad'),
                      const SizedBox(height: 8),
                      _DifficultyRow(
                        value: _difficulty,
                        onChanged: (v) => setState(() => _difficulty = v),
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel('Tiempo estimado'),
                      const SizedBox(height: 8),
                      _DurationStepper(
                        minutes: _estimatedMinutes,
                        onChanged: (v) => setState(() {
                          _estimatedMinutes = v;
                          if (_workedMinutes > v) _workedMinutes = v;
                        }),
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel('Tiempo trabajado'),
                      const SizedBox(height: 8),
                      _WorkedStepper(
                        minutes: _workedMinutes,
                        maxMinutes: _estimatedMinutes,
                        onChanged: (v) => setState(() => _workedMinutes = v),
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel('Disponibilidad horaria'),
                      const SizedBox(height: 8),
                      if (_slots.isEmpty)
                        Text(
                          'Esta tarea no tiene días asignados.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.graphiteSoft,
                                  ),
                        )
                      else
                        ..._slots.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _SlotEditor(
                                  slot: entry.value,
                                  onChange: (s) => setState(
                                    () => _slots[entry.key] = s,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.calendarDeadline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.graphiteSoft,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: (_isValid && !_saving) ? _save : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.tab2Accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Guardar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftSlot {
  _DraftSlot({
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
  });

  final DateTime date;
  int startMinutes;
  int endMinutes;

  _DraftSlot copyWith({int? startMinutes, int? endMinutes}) => _DraftSlot(
        date: date,
        startMinutes: startMinutes ?? this.startMinutes,
        endMinutes: endMinutes ?? this.endMinutes,
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.tab2Accent,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final level = i + 1;
        final selected = level == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(level),
            child: Container(
              margin: EdgeInsets.only(right: i == 4 ? 0 : 6),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.tab2Accent : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? AppColors.tab2Accent : AppColors.warmGray,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$level',
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.graphite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DurationStepper extends StatelessWidget {
  const _DurationStepper({required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warmGray, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: minutes > 30 ? () => onChanged(minutes - 30) : null,
            icon: const Icon(Icons.remove_rounded),
            color: AppColors.tab2Accent,
          ),
          Expanded(
            child: Center(
              child: Text(
                TimeFormat.duration(minutes),
                style: const TextStyle(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => onChanged(minutes + 30),
            icon: const Icon(Icons.add_rounded),
            color: AppColors.tab2Accent,
          ),
        ],
      ),
    );
  }
}

class _WorkedStepper extends StatelessWidget {
  const _WorkedStepper({
    required this.minutes,
    required this.maxMinutes,
    required this.onChanged,
  });

  final int minutes;
  final int maxMinutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warmGray, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: minutes > 0
                ? () => onChanged((minutes - 30).clamp(0, maxMinutes))
                : null,
            icon: const Icon(Icons.remove_rounded),
            color: AppColors.tab2Accent,
          ),
          Expanded(
            child: Center(
              child: Text(
                minutes == 0 ? 'Sin avance' : TimeFormat.duration(minutes),
                style: const TextStyle(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: minutes < maxMinutes
                ? () => onChanged((minutes + 30).clamp(0, maxMinutes))
                : null,
            icon: const Icon(Icons.add_rounded),
            color: AppColors.tab2Accent,
          ),
        ],
      ),
    );
  }
}

class _SlotEditor extends StatelessWidget {
  const _SlotEditor({required this.slot, required this.onChange});

  final _DraftSlot slot;
  final ValueChanged<_DraftSlot> onChange;

  Future<void> _pickStart(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: slot.startMinutes ~/ 60,
        minute: slot.startMinutes % 60,
      ),
      helpText: 'Hora de inicio',
    );
    if (picked == null) return;
    final newStart = picked.hour * 60 + picked.minute;
    final newEnd = slot.endMinutes <= newStart ? newStart + 30 : slot.endMinutes;
    onChange(slot.copyWith(startMinutes: newStart, endMinutes: newEnd));
  }

  Future<void> _pickEnd(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: slot.endMinutes ~/ 60,
        minute: slot.endMinutes % 60,
      ),
      helpText: 'Hora de fin',
    );
    if (picked == null) return;
    final newEnd = picked.hour * 60 + picked.minute;
    onChange(slot.copyWith(endMinutes: newEnd));
  }

  @override
  Widget build(BuildContext context) {
    final invalid = slot.endMinutes - slot.startMinutes < 30;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: invalid ? AppColors.calendarDeadline : AppColors.warmGray,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TimeFormat.fullDate(slot.date),
                  style: const TextStyle(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _TimeChip(
                      label: TimeFormat.minutesToClock(slot.startMinutes),
                      onTap: () => _pickStart(context),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('—'),
                    ),
                    _TimeChip(
                      label: TimeFormat.minutesToClock(slot.endMinutes),
                      onTap: () => _pickEnd(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.tab2Tint,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.tab2Primary, width: 1),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.tab2Accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

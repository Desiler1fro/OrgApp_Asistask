import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/time_format.dart';
import '../../../data/repositories/day_schedule_repository_provider.dart';
import '../../../data/repositories/task_repository_provider.dart';
import '../../../domain/entities/availability_slot.dart';
import '../../../domain/entities/day_schedule.dart';
import '../../../domain/entities/subject.dart';
import '../../../domain/entities/task.dart';

import 'add_task_state.dart';

final addTaskNotifierProvider =
    NotifierProvider<AddTaskNotifier, AddTaskState>(AddTaskNotifier.new);

class AddTaskNotifier extends Notifier<AddTaskState> {
  @override
  AddTaskState build() {
    return AddTaskState(
      messages: [_pug('¡Hola! ¿Cómo se llama la tarea?')],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────
  ChatMessage _pug(String text) =>
      ChatMessage(sender: ChatSender.pug, text: text);
  ChatMessage _user(String text) =>
      ChatMessage(sender: ChatSender.user, text: text);

  void _appendUser(String text) {
    state = state.copyWith(
      messages: [...state.messages, _user(text)],
      pugMood: PugMood.happy,
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (state.pugMood == PugMood.happy) {
        state = state.copyWith(pugMood: PugMood.idle);
      }
    });
  }

  void _appendPug(String text) {
    state = state.copyWith(
      messages: [...state.messages, _pug(text)],
    );
  }

  // ─── Step 1: name ─────────────────────────────────────────────────
  void submitName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || state.step != AddTaskStep.askName) return;
    _appendUser(trimmed);
    state = state.copyWith(name: trimmed, step: AddTaskStep.askSubject);
    _appendPug('¿A qué materia pertenece?');
  }

  // ─── Step 2: subject ──────────────────────────────────────────────
  void submitSubject(Subject subject) {
    if (state.step != AddTaskStep.askSubject) return;
    _appendUser(subject.name);
    state = state.copyWith(
      subjectId: subject.id,
      step: AddTaskStep.askDueDate,
    );
    _appendPug('¿Cuándo es la fecha de entrega?');
  }

  // ─── Step 3: due date ─────────────────────────────────────────────
  void submitDueDate(DateTime date) {
    if (state.step != AddTaskStep.askDueDate) return;
    final normalized = dateOnly(date);
    _appendUser(TimeFormat.fullDate(normalized));
    state = state.copyWith(
      dueDate: normalized,
      step: AddTaskStep.askDifficulty,
    );
    _appendPug('¿Qué tan difícil es?');
  }

  // ─── Step 4: difficulty ───────────────────────────────────────────
  void submitDifficulty(int difficulty) {
    if (state.step != AddTaskStep.askDifficulty) return;
    if (difficulty < 1 || difficulty > 5) return;
    _appendUser('Dificultad: $difficulty / 5');
    state = state.copyWith(
      difficulty: difficulty,
      step: AddTaskStep.askDuration,
    );
    _appendPug('¿Cuánto tiempo crees que te tomará?');
  }

  // ─── Step 5: duration ─────────────────────────────────────────────
  void submitDuration(int estimatedMinutes) {
    if (state.step != AddTaskStep.askDuration) return;
    if (estimatedMinutes < 30) return;
    _appendUser(TimeFormat.duration(estimatedMinutes));
    state = state.copyWith(
      estimatedMinutes: estimatedMinutes,
      step: AddTaskStep.askDiscardDays,
    );
    _appendPug(
      'Marca los días que NO vas a usar. Los demás se toman como disponibles.',
    );
  }

  // ─── Step 6: toggle discarded ─────────────────────────────────────
  void toggleDiscarded(DateTime date) {
    if (state.step != AddTaskStep.askDiscardDays) return;
    final d = dateOnly(date);
    final exists = state.discardedDates.any((x) => x.isAtSameMomentAs(d));
    final next = exists
        ? state.discardedDates.where((x) => !x.isAtSameMomentAs(d)).toList()
        : [...state.discardedDates, d];
    state = state.copyWith(discardedDates: next);
  }

  Future<void> confirmDiscardedDays() async {
    if (state.step != AddTaskStep.askDiscardDays) return;
    final dueDate = state.dueDate;
    if (dueDate == null) return;

    if (_activeDays().isEmpty) {
      _appendPug(
        'Necesito al menos un día disponible. Quita el descarte de alguno.',
      );
      return;
    }

    if (state.discardedDates.isEmpty) {
      _appendUser('Mantengo todos los días.');
    } else {
      final names =
          state.discardedDates.map(TimeFormat.shortDate).join(', ');
      _appendUser('Descarté: $names');
    }

    _autoDiscardTodayIfNoTimeLeft();

    final activeDays = _activeDays();
    if (activeDays.isEmpty) {
      _appendPug(
        'Necesito al menos un día disponible. Quita el descarte de alguno.',
      );
      state = state.copyWith(step: AddTaskStep.askDiscardDays);
      return;
    }

    final first = activeDays.first;
    final prefill = await _prefillFor(first);
    final minStart = _minStartMinutesFor(first);

    state = state.copyWith(
      step: AddTaskStep.askSchedules,
      currentScheduleIndex: 0,
      currentPrefill: prefill,
      currentMinStartMinutes: minStart,
    );
    _appendPug(_scheduleQuestion(first, prefill, minStart));
  }

  // ─── Step 7: schedules per day ────────────────────────────────────
  Future<void> submitSchedule(int startMinutes, int endMinutes) async {
    if (state.step != AddTaskStep.askSchedules) return;
    if (endMinutes <= startMinutes) return;
    if (startMinutes < state.currentMinStartMinutes) return;

    final activeDays = _activeDays();
    final idx = state.currentScheduleIndex;
    if (idx >= activeDays.length) return;
    final date = activeDays[idx];

    final next = [
      ...state.schedules,
      DraftSchedule(
        date: date,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
      ),
    ];

    _appendUser(
      '${TimeFormat.shortDate(date)} · '
      '${TimeFormat.range(startMinutes, endMinutes)}',
    );

    final nextIndex = idx + 1;
    if (nextIndex < activeDays.length) {
      final upcoming = activeDays[nextIndex];
      final prefill = await _prefillFor(upcoming);
      final minStart = _minStartMinutesFor(upcoming);
      state = state.copyWith(
        schedules: next,
        currentScheduleIndex: nextIndex,
        currentPrefill: prefill,
        currentMinStartMinutes: minStart,
      );
      _appendPug(_scheduleQuestion(upcoming, prefill, minStart));
    } else {
      state = state.copyWith(
        schedules: next,
        currentScheduleIndex: nextIndex,
        currentPrefill: null,
        currentMinStartMinutes: 0,
        step: AddTaskStep.celebrating,
        pugMood: PugMood.celebrate,
      );
      await _persist();
    }
  }

  // ─── Persistence + reset ──────────────────────────────────────────
  Future<void> _persist() async {
    final name = state.name;
    final subjectId = state.subjectId;
    final dueDate = state.dueDate;
    final difficulty = state.difficulty;
    final estimatedMinutes = state.estimatedMinutes;
    if (name == null ||
        subjectId == null ||
        dueDate == null ||
        difficulty == null ||
        estimatedMinutes == null) {
      return;
    }

    state = state.copyWith(saving: true);
    try {
      await ref.read(taskRepositoryProvider).create(
            TaskInput(
              name: name,
              subjectId: subjectId,
              dueDate: dueDate,
              difficulty: difficulty,
              estimatedMinutes: estimatedMinutes,
            ),
            state.schedules
                .map(
                  (s) => AvailabilitySlotInput(
                    date: s.date,
                    startMinutes: s.startMinutes,
                    endMinutes: s.endMinutes,
                  ),
                )
                .toList(),
          );

      final dayScheduleRepo = ref.read(dayScheduleRepositoryProvider);
      for (final s in state.schedules) {
        await dayScheduleRepo.remember(
          DaySchedule(
            dayOfWeek: s.date.weekday,
            startMinutes: s.startMinutes,
            endMinutes: s.endMinutes,
          ),
        );
      }

      state = state.copyWith(
        messages: [
          ...state.messages,
          _pug('¡Listo! Tu tarea quedó guardada.'),
        ],
        saving: false,
        recentlySaved: true,
        pugMood: PugMood.celebrate,
      );
    } catch (_) {
      state = state.copyWith(saving: false);
      _appendPug('Algo falló al guardar. Inténtalo de nuevo.');
      rethrow;
    }
  }

  void reset() {
    state = AddTaskState(
      messages: [_pug('¡Hola! ¿Cómo se llama la tarea?')],
    );
  }

  // ─── Derived helpers ──────────────────────────────────────────────
  List<DateTime> windowDays() {
    final dueDate = state.dueDate;
    if (dueDate == null) return const [];
    final start = dateOnly(DateTime.now());
    final end = dateOnly(dueDate);
    if (end.isBefore(start)) return const [];
    final days = <DateTime>[];
    var cursor = start;
    while (!cursor.isAfter(end)) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return days;
  }

  List<DateTime> activeDays() {
    final all = windowDays();
    final discarded = state.discardedDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
    return all
        .where((d) => !discarded.any((x) => x.isAtSameMomentAs(d)))
        .toList();
  }

  DateTime? currentScheduleDate() {
    final days = activeDays();
    final idx = state.currentScheduleIndex;
    if (idx >= days.length) return null;
    return days[idx];
  }

  List<DateTime> _activeDays() => activeDays();

  // Prefill dinámico: prioriza el horario más usado entre tareas activas
  // (refleja lo que el usuario está haciendo ahora). Si no hay tareas
  // activas para ese día de semana, cae al respaldo persistido en la
  // tabla (último horario ingresado, vía last-wins).
  Future<DaySchedule?> _prefillFor(DateTime date) async {
    final repo = ref.read(dayScheduleRepositoryProvider);
    final fromActive =
        await repo.mostFrequentActiveScheduleForWeekday(date.weekday);
    if (fromActive != null) return fromActive;
    return repo.findByDayOfWeek(date.weekday);
  }

  String _scheduleQuestion(
    DateTime date,
    DaySchedule? prefill,
    int minStart,
  ) {
    final isToday = dateOnly(date).isAtSameMomentAs(dateOnly(DateTime.now()));

    if (isToday && minStart > 0) {
      final prefillValid =
          prefill != null && prefill.startMinutes >= minStart;

      final now = DateTime.now();
      final nowClock = TimeFormat.minutesToClock(now.hour * 60 + now.minute);
      final minClock = TimeFormat.minutesToClock(minStart);

      if (prefillValid) {
        return '¿Entre qué horas puedes trabajar hoy? '
            'Como ya son las $nowClock, el inicio más temprano disponible es las $minClock. '
            'Lo de siempre fue ${TimeFormat.range(prefill.startMinutes, prefill.endMinutes)} — '
            'puedes confirmarlo o cambiarlo.';
      }
      return '¿Entre qué horas puedes trabajar hoy? '
          'Como ya son las $nowClock, el inicio más temprano disponible es las $minClock.';
    }

    final label = TimeFormat.fullDate(date);
    if (prefill == null) {
      return '¿Entre qué horas puedes trabajar el $label?';
    }
    return '¿Entre qué horas puedes trabajar el $label? '
        'Lo de siempre fue ${TimeFormat.range(prefill.startMinutes, prefill.endMinutes)} — '
        'puedes confirmarlo o cambiarlo.';
  }

  // Minutos restantes mínimos de un bloque (30) para no descartar el día.
  static const int _minBlockMinutes = 30;
  static const int _minutesInDay = 24 * 60;

  // Devuelve el inicio mínimo permitido para `date`:
  // - Si es hoy: la hora actual redondeada hacia arriba al siguiente bloque
  //   de 30 min.
  // - Si es otro día: 0 (sin restricción).
  int _minStartMinutesFor(DateTime date) {
    final today = dateOnly(DateTime.now());
    if (!dateOnly(date).isAtSameMomentAs(today)) return 0;
    final now = DateTime.now();
    final totalNow = now.hour * 60 + now.minute;
    return ((totalNow + _minBlockMinutes - 1) ~/ _minBlockMinutes) *
        _minBlockMinutes;
  }

  // ¿Hoy ya no entra un bloque completo de 30 min antes de medianoche?
  bool _todayHasNoTimeLeft() {
    final today = dateOnly(DateTime.now());
    final minStart = _minStartMinutesFor(today);
    return _minutesInDay - minStart < _minBlockMinutes;
  }

  void _autoDiscardTodayIfNoTimeLeft() {
    final today = dateOnly(DateTime.now());
    final isActive =
        _activeDays().any((d) => d.isAtSameMomentAs(today));
    if (!isActive) return;
    if (!_todayHasNoTimeLeft()) return;

    state = state.copyWith(
      discardedDates: [...state.discardedDates, today],
    );
    _appendPug(
      'Ya casi no queda tiempo hoy, así que lo descarté automáticamente.',
    );
  }
}

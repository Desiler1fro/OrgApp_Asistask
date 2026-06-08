import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/time_format.dart';
import '../../../data/repositories/day_limit_repository_provider.dart';
import '../../../data/repositories/subject_repository_provider.dart';
import '../../../data/repositories/task_repository_provider.dart';
import '../../../domain/entities/availability_slot.dart';
import '../../../domain/entities/day_limit.dart';
import '../../../domain/entities/subject.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/prediction/ranker.dart';
import '../../../domain/prediction/scheduler.dart';

/// Vista mínima de una tarea vencida: solo necesita la tarea y su materia.
class OverdueTaskView {
  const OverdueTaskView({required this.task, required this.subject});

  final Task task;
  final Subject subject;
}

/// Vista mínima de una tarea completada.
class CompletedTaskView {
  const CompletedTaskView({required this.task, required this.subject});

  final Task task;
  final Subject subject;
}

/// Provider para tareas vencidas (dueDate < hoy, no completadas).
final overdueTasksProvider = Provider<AsyncValue<List<OverdueTaskView>>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  final subjectsAsync = ref.watch(subjectsStreamProvider);

  return tasksAsync.whenData((tasks) {
    final subjects = subjectsAsync.valueOrNull ?? const <Subject>[];
    final subjectsById = {for (final s in subjects) s.id: s};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final overdue = <OverdueTaskView>[];
    for (final task in tasks) {
      if (task.isCompleted) continue;
      final due = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );
      if (!due.isBefore(today)) continue;
      final subject = subjectsById[task.subjectId];
      if (subject == null) continue;
      overdue.add(OverdueTaskView(task: task, subject: subject));
    }
    overdue.sort((a, b) => b.task.dueDate.compareTo(a.task.dueDate));
    return overdue;
  });
});

/// Provider para tareas completadas (sin importar fecha).
final completedTasksProvider =
    Provider<AsyncValue<List<CompletedTaskView>>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  final subjectsAsync = ref.watch(subjectsStreamProvider);

  return tasksAsync.whenData((tasks) {
    final subjects = subjectsAsync.valueOrNull ?? const <Subject>[];
    final subjectsById = {for (final s in subjects) s.id: s};

    final completed = <CompletedTaskView>[];
    for (final task in tasks) {
      if (!task.isCompleted) continue;
      final subject = subjectsById[task.subjectId];
      if (subject == null) continue;
      completed.add(CompletedTaskView(task: task, subject: subject));
    }
    completed.sort((a, b) => b.task.dueDate.compareTo(a.task.dueDate));
    return completed;
  });
});

/// Vista combinada de una tarea para el listado: incluye la tarea, su
/// materia, su score, sus bloques calculados por el Scheduler y los
/// slots crudos (necesarios para la edición de disponibilidad).
class RankedTaskView {
  const RankedTaskView({
    required this.task,
    required this.subject,
    required this.score,
    required this.schedule,
    required this.slots,
  });

  final Task task;
  final Subject subject;
  final TaskScore score;
  final TaskSchedule schedule;
  final List<AvailabilitySlot> slots;

  /// Bloque programado más cercano en el futuro (o `null` si todos los
  /// bloques son del pasado o no hay bloques).
  ScheduledBlock? nextBlock(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    for (final block in schedule.blocks) {
      if (!block.date.isBefore(today)) return block;
    }
    return schedule.blocks.isEmpty ? null : schedule.blocks.first;
  }
}

/// Provider derivado: combina tasks + slots + subjects, ejecuta
/// Ranker + Scheduler y expone la lista ordenada.
///
/// Excluye tareas vencidas y completadas.
final rankedTasksProvider = Provider<AsyncValue<List<RankedTaskView>>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  final slotsAsync = ref.watch(availabilitySlotsStreamProvider);
  final subjectsAsync = ref.watch(subjectsStreamProvider);
  final dayLimitsAsync = ref.watch(dayLimitsStreamProvider);

  return tasksAsync.whenData((allTasks) {
    final slots = slotsAsync.valueOrNull ?? const <AvailabilitySlot>[];
    final subjects = subjectsAsync.valueOrNull ?? const <Subject>[];
    final dayLimits = dayLimitsAsync.valueOrNull ?? const <DayLimit>[];

    final subjectsById = {for (final s in subjects) s.id: s};
    final slotsByTaskId = <int, List<AvailabilitySlot>>{};
    for (final slot in slots) {
      slotsByTaskId.putIfAbsent(slot.taskId, () => []).add(slot);
    }
    final maxTasksByDay = {
      for (final l in dayLimits) dateOnly(l.date): l.maxTasks,
    };

    const ranker = Ranker();
    const scheduler = Scheduler();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Excluir tareas vencidas y completadas del ranking.
    final tasks = allTasks.where((t) {
      if (t.isCompleted) return false;
      final due = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      return !due.isBefore(today);
    }).toList();

    final ordered = ranker.rank(
      tasks: tasks,
      subjectsById: subjectsById,
      slotsByTaskId: slotsByTaskId,
      now: now,
    );

    final taskById = {for (final t in tasks) t.id: t};

    // El Scheduler asigna contra un pool compartido respetando la
    // prioridad: las tareas se procesan en el orden del Ranker.
    final tasksInPriorityOrder = [
      for (final ts in ordered)
        if (taskById[ts.taskId] != null) taskById[ts.taskId]!,
    ];

    final schedules = scheduler.schedule(
      tasksInPriorityOrder: tasksInPriorityOrder,
      slotsByTaskId: slotsByTaskId,
      now: now,
      maxTasksByDay: maxTasksByDay,
    );
    final views = <RankedTaskView>[];
    for (final ts in ordered) {
      final task = taskById[ts.taskId];
      if (task == null) continue;
      final subject = subjectsById[task.subjectId];
      if (subject == null) continue;
      views.add(
        RankedTaskView(
          task: task,
          subject: subject,
          score: ts,
          schedule: schedules[task.id] ??
              TaskSchedule(
                taskId: task.id,
                estimatedMinutes: task.estimatedMinutes,
                workedMinutes: task.workedMinutes,
                blocks: const [],
              ),
          slots: List.unmodifiable(slotsByTaskId[task.id] ?? const []),
        ),
      );
    }

    return views;
  });
});

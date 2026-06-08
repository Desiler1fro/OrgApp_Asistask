import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/availability_slots_table.dart';
import '../tables/day_schedules_table.dart';
import '../tables/tasks_table.dart';

part 'day_schedules_dao.g.dart';

/// Slot horario de una tarea activa (no completada y no vencida) junto
/// con el `dueDate` de su tarea — el dueDate sirve para desempatar
/// cuando dos horarios distintos aparecen con la misma frecuencia.
class ActiveTaskSlot {
  const ActiveTaskSlot({
    required this.slotDate,
    required this.startMinutes,
    required this.endMinutes,
    required this.taskDueDate,
  });

  final DateTime slotDate;
  final int startMinutes;
  final int endMinutes;
  final DateTime taskDueDate;
}

@DriftAccessor(tables: [DaySchedules, AvailabilitySlots, Tasks])
class DaySchedulesDao extends DatabaseAccessor<AppDatabase>
    with _$DaySchedulesDaoMixin {
  DaySchedulesDao(super.db);

  Future<DayScheduleRow?> findByDayOfWeek(int dayOfWeek) {
    return (select(daySchedules)..where((d) => d.dayOfWeek.equals(dayOfWeek)))
        .getSingleOrNull();
  }

  Future<List<DayScheduleRow>> all() {
    return select(daySchedules).get();
  }

  /// Sobrescribe siempre (last-wins). La tabla mantiene el último
  /// horario ingresado por día de semana como respaldo del prefill.
  Future<void> upsert(DaySchedulesCompanion entry) async {
    await into(daySchedules).insertOnConflictUpdate(entry);
  }

  /// Devuelve los slots de todas las tareas activas (no completadas y
  /// con `dueDate >= today`). El repo lo usa para computar el prefill
  /// dinámico basado en lo que el usuario está usando ahora, en lugar
  /// de depender de horarios congelados en la tabla.
  Future<List<ActiveTaskSlot>> activeSlots(DateTime today) async {
    final query = select(availabilitySlots).join([
      innerJoin(tasks, tasks.id.equalsExp(availabilitySlots.taskId)),
    ])
      ..where(
        tasks.isCompleted.equals(false) &
            tasks.dueDate.isBiggerOrEqualValue(today),
      );

    final rows = await query.get();
    return rows.map((row) {
      final slot = row.readTable(availabilitySlots);
      final task = row.readTable(tasks);
      return ActiveTaskSlot(
        slotDate: slot.date,
        startMinutes: slot.startMinutes,
        endMinutes: slot.endMinutes,
        taskDueDate: task.dueDate,
      );
    }).toList();
  }
}

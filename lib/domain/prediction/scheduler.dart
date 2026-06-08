import '../entities/availability_slot.dart';
import '../entities/task.dart';

/// Bloque horario concreto en el que se trabajará una tarea.
class ScheduledBlock {
  const ScheduledBlock({
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
  });

  final DateTime date;
  final int startMinutes;
  final int endMinutes;

  int get durationMinutes => endMinutes - startMinutes;
}

/// Plan de ejecución de una tarea: lista de bloques + métricas.
///
/// `workedMinutes` es el tiempo ya registrado como trabajado por el
/// usuario. Solo se planifican bloques para el tiempo restante
/// (`estimatedMinutes - workedMinutes`); las métricas de completitud
/// consideran ambos.
class TaskSchedule {
  const TaskSchedule({
    required this.taskId,
    required this.estimatedMinutes,
    required this.blocks,
    this.workedMinutes = 0,
  });

  final int taskId;
  final int estimatedMinutes;
  final int workedMinutes;
  final List<ScheduledBlock> blocks;

  /// Minutos planificados a futuro (suma de los bloques).
  int get scheduledMinutes =>
      blocks.fold<int>(0, (acc, b) => acc + b.durationMinutes);

  /// Minutos del estimado que aún no están cubiertos ni por el trabajo ya
  /// hecho ni por los bloques planificados.
  int get remainingMinutes {
    final remaining = estimatedMinutes - workedMinutes - scheduledMinutes;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isComplete => workedMinutes + scheduledMinutes >= estimatedMinutes;
}

/// Intervalo horario simple (minutos desde medianoche) dentro de un día.
class _Interval {
  const _Interval(this.start, this.end);
  final int start;
  final int end;
}

/// Distribuye las tareas en bloques horarios reales contra un pool de
/// capacidad **compartido y mirando solo hacia el futuro**.
///
/// Diferencias clave frente a una asignación por tarea aislada:
/// - Las tareas se procesan en el orden de prioridad que entrega el
///   Ranker. La de mayor prioridad reserva su tiempo primero; las
///   siguientes solo pueden usar el tiempo que aún quede libre ese día.
///   Esto impide que dos tareas ocupen el mismo minuto del mismo día.
/// - Los días ya pasados se ignoran por completo. En el día de hoy, el
///   tiempo ya transcurrido se descarta (el inicio se mueve a la hora
///   actual redondeada al siguiente bloque de 30 min). Así, el tiempo de
///   una tarea no completada se replanifica automáticamente en los días
///   futuros que aún quedan.
/// - Si tras agotar la capacidad futura queda tiempo sin asignar, el plan
///   queda incompleto (`isComplete == false`) y la UI lo advierte.
///
/// Domain-puro: sin dependencias de Flutter ni Drift.
class Scheduler {
  const Scheduler();

  static const int _blockStepMinutes = 30;
  static const int _minutesInDay = 24 * 60;

  Map<int, TaskSchedule> schedule({
    required List<Task> tasksInPriorityOrder,
    required Map<int, List<AvailabilitySlot>> slotsByTaskId,
    required DateTime now,
    Map<DateTime, int> maxTasksByDay = const {},
  }) {
    final result = <int, TaskSchedule>{};

    final nowDay = DateTime(now.year, now.month, now.day);
    final nowMinutes = _roundUpToBlock(now.hour * 60 + now.minute);

    // Reservas globales por día: intervalos ya ocupados por tareas previas
    // (de mayor prioridad). Cada lista se mantiene ordenada y sin solapes.
    final reservations = <DateTime, List<_Interval>>{};

    // Cuántas tareas distintas ya tienen bloques en cada día (para el tope).
    final tasksPerDay = <DateTime, Set<int>>{};

    for (final task in tasksInPriorityOrder) {
      final slots = [
        ...(slotsByTaskId[task.id] ?? const <AvailabilitySlot>[]),
      ]..sort((a, b) {
          final byDate = a.date.compareTo(b.date);
          if (byDate != 0) return byDate;
          return a.startMinutes.compareTo(b.startMinutes);
        });

      final blocks = <ScheduledBlock>[];
      // Solo se planifica el tiempo que aún falta por trabajar.
      var remaining = task.estimatedMinutes - task.workedMinutes;
      if (remaining < 0) remaining = 0;

      for (final slot in slots) {
        if (remaining <= 0) break;

        final day = DateTime(slot.date.year, slot.date.month, slot.date.day);

        // Descartar días pasados por completo.
        if (day.isBefore(nowDay)) continue;

        // Tope de tareas por día: si el día ya alcanzó su máximo y esta
        // tarea aún no tiene bloques ahí, se salta el día (mantiene la
        // prioridad: las de mayor rango ocupan los cupos primero).
        final limit = maxTasksByDay[day];
        if (limit != null) {
          final assigned = tasksPerDay[day];
          final alreadyHere = assigned?.contains(task.id) ?? false;
          if (!alreadyHere && (assigned?.length ?? 0) >= limit) {
            continue;
          }
        }

        // En el día de hoy, recortar el tiempo ya transcurrido.
        var slotStart = slot.startMinutes;
        if (day.isAtSameMomentAs(nowDay) && slotStart < nowMinutes) {
          slotStart = nowMinutes;
        }
        final slotEnd = slot.endMinutes;
        if (slotEnd <= slotStart) continue;

        // Restar lo ya reservado por otras tareas → sub-intervalos libres.
        final free = _subtractReserved(
          slotStart,
          slotEnd,
          reservations[day] ?? const [],
        );

        for (final gap in free) {
          if (remaining <= 0) break;
          final gapDuration = gap.end - gap.start;
          if (gapDuration <= 0) continue;
          final take = gapDuration < remaining ? gapDuration : remaining;
          final blockEnd = gap.start + take;
          blocks.add(
            ScheduledBlock(
              date: day,
              startMinutes: gap.start,
              endMinutes: blockEnd,
            ),
          );
          _reserve(reservations, day, _Interval(gap.start, blockEnd));
          tasksPerDay.putIfAbsent(day, () => <int>{}).add(task.id);
          remaining -= take;
        }
      }

      result[task.id] = TaskSchedule(
        taskId: task.id,
        estimatedMinutes: task.estimatedMinutes,
        workedMinutes: task.workedMinutes,
        blocks: blocks,
      );
    }

    return result;
  }

  /// Redondea hacia arriba al siguiente múltiplo de 30 min. Coincide con
  /// la convención usada al crear slots para "hoy".
  static int _roundUpToBlock(int minutes) {
    final rounded =
        ((minutes + _blockStepMinutes - 1) ~/ _blockStepMinutes) *
            _blockStepMinutes;
    return rounded > _minutesInDay ? _minutesInDay : rounded;
  }

  /// Devuelve los sub-intervalos de [start, end) que NO están cubiertos por
  /// los intervalos reservados (asumidos ordenados y sin solapes).
  static List<_Interval> _subtractReserved(
    int start,
    int end,
    List<_Interval> reserved,
  ) {
    final free = <_Interval>[];
    var cursor = start;
    for (final r in reserved) {
      if (r.end <= cursor) continue;
      if (r.start >= end) break;
      if (r.start > cursor) {
        free.add(_Interval(cursor, r.start));
      }
      if (r.end > cursor) cursor = r.end;
      if (cursor >= end) break;
    }
    if (cursor < end) free.add(_Interval(cursor, end));
    return free;
  }

  /// Inserta un intervalo en las reservas del día, manteniéndolas
  /// ordenadas y fusionando solapes/contiguos.
  static void _reserve(
    Map<DateTime, List<_Interval>> reservations,
    DateTime day,
    _Interval interval,
  ) {
    final list = reservations.putIfAbsent(day, () => <_Interval>[]);
    list.add(interval);
    list.sort((a, b) => a.start.compareTo(b.start));

    final merged = <_Interval>[];
    for (final current in list) {
      if (merged.isEmpty || merged.last.end < current.start) {
        merged.add(current);
      } else {
        final last = merged.removeLast();
        merged.add(
          _Interval(
            last.start,
            current.end > last.end ? current.end : last.end,
          ),
        );
      }
    }
    reservations[day] = merged;
  }
}

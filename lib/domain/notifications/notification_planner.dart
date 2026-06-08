import '../entities/notification_preferences.dart';
import 'notification_request.dart';

/// Datos mínimos por tarea que necesita el planner. Se construye en la
/// capa de features a partir de RankedTaskView para mantener este módulo
/// libre de dependencias de Flutter/UI.
class PlannerTask {
  const PlannerTask({
    required this.id,
    required this.name,
    required this.dueDate,
    required this.isCritical,
    required this.blocks,
  });

  final int id;
  final String name;
  final DateTime dueDate;
  final bool isCritical;
  final List<PlannerBlock> blocks;
}

class PlannerBlock {
  const PlannerBlock({
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
  });

  final DateTime date;
  final int startMinutes;
  final int endMinutes;
}

/// Decide QUÉ notificaciones programar. Es puro: dadas las tareas y las
/// preferencias, devuelve una lista de requests con fechas absolutas.
///
/// Reglas:
/// - **Deadline** (24 h antes): se dispara a las 09:00 del día anterior
///   a `dueDate`, si esa hora es futura.
/// - **Bloque de trabajo** (15 min antes): se dispara para cada bloque
///   futuro de hoy o después, 15 min antes de su `startMinutes`.
/// - **Urgencia crítica**: si la tarea es `isCritical` (daysAvailable ≤ 2)
///   se dispara a las próximas 09:00 (hoy si todavía no han pasado, mañana
///   si ya pasaron), siempre antes del fin del día de `dueDate`.
///
/// Tareas completadas o vencidas no llegan al planner (se filtran arriba).
class NotificationPlanner {
  const NotificationPlanner();

  static const int _deadlineHour = 9;
  static const int _criticalHour = 9;
  static const int _workBlockLeadMinutes = 15;

  List<NotificationRequest> plan({
    required List<PlannerTask> tasks,
    required NotificationPreferences prefs,
    required DateTime now,
  }) {
    final out = <NotificationRequest>[];

    for (final task in tasks) {
      if (prefs.deadlineEnabled) {
        final fire = _deadlineFireTime(task.dueDate);
        if (fire.isAfter(now)) {
          out.add(
            NotificationRequest(
              kind: NotificationRequestKind.deadline,
              taskId: task.id,
              taskName: task.name,
              fireAt: fire,
            ),
          );
        }
      }

      if (prefs.workBlockEnabled) {
        for (var i = 0; i < task.blocks.length; i++) {
          final block = task.blocks[i];
          final fire = _workBlockFireTime(block);
          if (fire.isAfter(now)) {
            out.add(
              NotificationRequest(
                kind: NotificationRequestKind.workBlock,
                taskId: task.id,
                taskName: task.name,
                fireAt: fire,
                blockIndex: i,
                hourRange:
                    '${_clock(block.startMinutes)}–${_clock(block.endMinutes)}',
              ),
            );
          }
        }
      }

      if (prefs.criticalEnabled && task.isCritical) {
        final fire = _criticalFireTime(now: now, dueDate: task.dueDate);
        if (fire != null && fire.isAfter(now)) {
          out.add(
            NotificationRequest(
              kind: NotificationRequestKind.critical,
              taskId: task.id,
              taskName: task.name,
              fireAt: fire,
            ),
          );
        }
      }
    }

    return out;
  }

  /// 09:00 del día anterior al `dueDate`.
  static DateTime _deadlineFireTime(DateTime dueDate) {
    final dayBefore = DateTime(dueDate.year, dueDate.month, dueDate.day)
        .subtract(const Duration(days: 1));
    return DateTime(
      dayBefore.year,
      dayBefore.month,
      dayBefore.day,
      _deadlineHour,
    );
  }

  /// 15 min antes del comienzo del bloque.
  static DateTime _workBlockFireTime(PlannerBlock block) {
    final startMinute = block.startMinutes - _workBlockLeadMinutes;
    final base = DateTime(block.date.year, block.date.month, block.date.day);
    return base.add(Duration(minutes: startMinute));
  }

  /// Próximas 09:00 a partir de `now`. Si ese instante es posterior al
  /// fin del día del `dueDate`, retorna `null` (ya no tiene sentido).
  static DateTime? _criticalFireTime({
    required DateTime now,
    required DateTime dueDate,
  }) {
    final today9 = DateTime(now.year, now.month, now.day, _criticalHour);
    final candidate = today9.isAfter(now)
        ? today9
        : today9.add(const Duration(days: 1));
    final dueEnd = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      23,
      59,
    );
    if (candidate.isAfter(dueEnd)) return null;
    return candidate;
  }

  static String _clock(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

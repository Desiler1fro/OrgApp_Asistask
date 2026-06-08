import '../entities/availability_slot.dart';
import '../entities/subject.dart';
import '../entities/task.dart';
import 'factors/factors.dart';
import 'prediction_weights.dart';

/// Desglose por factor del score de una tarea (útil para UI/debug).
class FactorBreakdown {
  const FactorBreakdown({
    required this.urgency,
    required this.difficulty,
    required this.duration,
    required this.availability,
    required this.liking,
  });

  final double urgency;
  final double difficulty;
  final double duration;
  final double availability;
  final double liking;
}

/// Resultado del Ranker para una tarea.
class TaskScore {
  const TaskScore({
    required this.taskId,
    required this.score,
    required this.isForToday,
    required this.isCritical,
    required this.daysAvailable,
    required this.breakdown,
  });

  final int taskId;
  final double score;
  final bool isForToday;
  final bool isCritical;
  final int daysAvailable;
  final FactorBreakdown breakdown;
}

/// Calcula el orden sugerido de tareas a partir de los cinco factores.
///
/// Reglas críticas (en orden de aplicación):
/// 1. Tareas con `dueDate == hoy` o con al menos un slot futuro para hoy
///    (`isForToday`) se ordenan SIEMPRE arriba del resto.
/// 2. Tareas con `daysAvailable <= criticalDaysThreshold` (`isCritical`)
///    se ordenan a continuación, antes del ranking por score. Garantiza
///    que el caso "queda solo 1-2 días disponibles" no quede sepultado
///    por una tarea con muchos días pero alta dificultad/duración.
/// 3. Dentro de cada tier, se ordena por score desc; a igualdad, por
///    `dueDate` asc y luego por id asc para que el orden sea estable.
/// 4. El Ranker NO asigna bloques horarios — eso es trabajo del Scheduler.
class Ranker {
  const Ranker();

  List<TaskScore> rank({
    required List<Task> tasks,
    required Map<int, Subject> subjectsById,
    required Map<int, List<AvailabilitySlot>> slotsByTaskId,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final nowMinutes = _roundUpToBlock(now.hour * 60 + now.minute);
    final scored = <TaskScore>[];

    for (final task in tasks) {
      final slots = slotsByTaskId[task.id] ?? const <AvailabilitySlot>[];
      final subject = subjectsById[task.subjectId];

      final dueDate = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );

      // Solo cuentan los días presentes/futuros; en hoy se descuenta el
      // tiempo ya transcurrido. Coherente con la capacidad real que verá
      // el Scheduler.
      final activeDays = <DateTime>{};
      var futureMinutes = 0;
      for (final s in slots) {
        final day = DateTime(s.date.year, s.date.month, s.date.day);
        if (day.isBefore(today)) continue;
        var start = s.startMinutes;
        if (day.isAtSameMomentAs(today) && start < nowMinutes) {
          start = nowMinutes;
        }
        final end = s.endMinutes;
        if (end <= start) continue;
        activeDays.add(day);
        futureMinutes += end - start;
      }

      final daysAvailable = activeDays.isEmpty
          ? _daysBetween(today, dueDate)
          : activeDays.length;

      final isForToday = dueDate.isAtSameMomentAs(today) ||
          activeDays.any((d) => d.isAtSameMomentAs(today));

      final isCritical =
          daysAvailable <= PredictionWeights.criticalDaysThreshold;

      final avgDaily = activeDays.isEmpty
          ? 0
          : (futureMinutes / activeDays.length).round();

      final breakdown = FactorBreakdown(
        urgency: urgencyScore(daysAvailable: daysAvailable),
        difficulty: difficultyScore(task.difficulty),
        duration: durationScore(task.estimatedMinutes),
        availability: availabilityScore(
          averageDailyAvailableMinutes: avgDaily,
        ),
        liking: likingScore(subject?.liking ?? 3),
      );

      final score = breakdown.urgency * PredictionWeights.urgency +
          breakdown.difficulty * PredictionWeights.difficulty +
          breakdown.duration * PredictionWeights.duration +
          breakdown.availability * PredictionWeights.availability +
          breakdown.liking * PredictionWeights.liking;

      scored.add(
        TaskScore(
          taskId: task.id,
          score: score,
          isForToday: isForToday,
          isCritical: isCritical,
          daysAvailable: daysAvailable,
          breakdown: breakdown,
        ),
      );
    }

    final taskById = {for (final t in tasks) t.id: t};

    scored.sort((a, b) {
      if (a.isForToday != b.isForToday) {
        return a.isForToday ? -1 : 1;
      }
      if (a.isCritical != b.isCritical) {
        return a.isCritical ? -1 : 1;
      }
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final aDue = taskById[a.taskId]!.dueDate;
      final bDue = taskById[b.taskId]!.dueDate;
      final byDue = aDue.compareTo(bDue);
      if (byDue != 0) return byDue;
      return a.taskId.compareTo(b.taskId);
    });

    return scored;
  }

  static int _daysBetween(DateTime from, DateTime to) {
    if (to.isBefore(from)) return 0;
    return to.difference(from).inDays + 1;
  }

  // Redondea hacia arriba al siguiente bloque de 30 min (misma convención
  // que el Scheduler y el flujo de crear tarea para "hoy").
  static int _roundUpToBlock(int minutes) {
    const step = 30;
    const minutesInDay = 24 * 60;
    final rounded = ((minutes + step - 1) ~/ step) * step;
    return rounded > minutesInDay ? minutesInDay : rounded;
  }
}

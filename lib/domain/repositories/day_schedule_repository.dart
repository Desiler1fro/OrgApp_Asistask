import '../entities/day_schedule.dart';

abstract class DayScheduleRepository {
  Future<DaySchedule?> findByDayOfWeek(int dayOfWeek);
  Future<List<DaySchedule>> all();

  /// Persiste el horario para el día de semana indicado con política
  /// last-wins (sobrescribe lo previo). Sirve como respaldo del prefill
  /// cuando no hay tareas activas en ese día de semana.
  Future<void> remember(DaySchedule schedule);

  /// Calcula el horario más frecuente (moda) entre los slots de tareas
  /// activas (no completadas y con `dueDate >= hoy`) cuyo `date.weekday`
  /// coincide con el día solicitado. En caso de empate gana el horario
  /// de la tarea con `dueDate` más cercano a hoy. Devuelve `null` si no
  /// hay tareas activas para ese día de semana.
  Future<DaySchedule?> mostFrequentActiveScheduleForWeekday(int dayOfWeek);
}

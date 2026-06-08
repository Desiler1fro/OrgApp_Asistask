import '../entities/day_schedule.dart';

abstract class DayScheduleRepository {
  Future<DaySchedule?> findByDayOfWeek(int dayOfWeek);
  Future<List<DaySchedule>> all();
  Future<void> rememberIfMissing(DaySchedule schedule);
}

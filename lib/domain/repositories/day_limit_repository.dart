import '../entities/day_limit.dart';

abstract class DayLimitRepository {
  Stream<List<DayLimit>> watchAll();
  Future<void> setLimit(DateTime date, int maxTasks);
  Future<void> removeLimit(DateTime date);
}

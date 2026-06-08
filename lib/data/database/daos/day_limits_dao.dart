import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/day_limits_table.dart';

part 'day_limits_dao.g.dart';

@DriftAccessor(tables: [DayLimits])
class DayLimitsDao extends DatabaseAccessor<AppDatabase>
    with _$DayLimitsDaoMixin {
  DayLimitsDao(super.db);

  Stream<List<DayLimitRow>> watchAll() {
    return (select(dayLimits)..orderBy([(d) => OrderingTerm.asc(d.date)]))
        .watch();
  }

  Future<void> upsert(DateTime date, int maxTasks) {
    return into(dayLimits).insertOnConflictUpdate(
      DayLimitsCompanion.insert(date: date, maxTasks: maxTasks),
    );
  }

  Future<void> deleteByDate(DateTime date) {
    return (delete(dayLimits)..where((d) => d.date.equals(date))).go();
  }
}

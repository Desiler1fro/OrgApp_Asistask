import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/day_schedules_table.dart';

part 'day_schedules_dao.g.dart';

@DriftAccessor(tables: [DaySchedules])
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

  Future<void> upsertIfMissing(DaySchedulesCompanion entry) async {
    final existing = await findByDayOfWeek(entry.dayOfWeek.value);
    if (existing != null) return;
    await into(daySchedules).insert(entry);
  }
}

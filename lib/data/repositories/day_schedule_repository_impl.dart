import 'package:drift/drift.dart';

import '../../domain/entities/day_schedule.dart';
import '../../domain/repositories/day_schedule_repository.dart';
import '../database/app_database.dart';

class DayScheduleRepositoryImpl implements DayScheduleRepository {
  DayScheduleRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<DaySchedule?> findByDayOfWeek(int dayOfWeek) async {
    final row = await _db.daySchedulesDao.findByDayOfWeek(dayOfWeek);
    if (row == null) return null;
    return _toEntity(row);
  }

  @override
  Future<List<DaySchedule>> all() async {
    final rows = await _db.daySchedulesDao.all();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> rememberIfMissing(DaySchedule schedule) {
    return _db.daySchedulesDao.upsertIfMissing(
      DaySchedulesCompanion.insert(
        dayOfWeek: Value(schedule.dayOfWeek),
        startMinutes: schedule.startMinutes,
        endMinutes: schedule.endMinutes,
      ),
    );
  }

  DaySchedule _toEntity(DayScheduleRow row) {
    return DaySchedule(
      dayOfWeek: row.dayOfWeek,
      startMinutes: row.startMinutes,
      endMinutes: row.endMinutes,
    );
  }
}

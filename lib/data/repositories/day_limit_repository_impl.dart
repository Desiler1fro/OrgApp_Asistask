import '../../core/utils/time_format.dart';
import '../../domain/entities/day_limit.dart';
import '../../domain/repositories/day_limit_repository.dart';
import '../database/app_database.dart';

class DayLimitRepositoryImpl implements DayLimitRepository {
  DayLimitRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<DayLimit>> watchAll() {
    return _db.dayLimitsDao.watchAll().map(
          (rows) => rows.map(_toEntity).toList(),
        );
  }

  @override
  Future<void> setLimit(DateTime date, int maxTasks) {
    return _db.dayLimitsDao.upsert(dateOnly(date), maxTasks);
  }

  @override
  Future<void> removeLimit(DateTime date) {
    return _db.dayLimitsDao.deleteByDate(dateOnly(date));
  }

  DayLimit _toEntity(DayLimitRow row) {
    return DayLimit(date: row.date, maxTasks: row.maxTasks);
  }
}

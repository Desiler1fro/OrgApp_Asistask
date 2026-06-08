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
  Future<void> remember(DaySchedule schedule) {
    return _db.daySchedulesDao.upsert(
      DaySchedulesCompanion.insert(
        dayOfWeek: Value(schedule.dayOfWeek),
        startMinutes: schedule.startMinutes,
        endMinutes: schedule.endMinutes,
      ),
    );
  }

  @override
  Future<DaySchedule?> mostFrequentActiveScheduleForWeekday(
    int dayOfWeek,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final slots = await _db.daySchedulesDao.activeSlots(today);

    final candidates =
        slots.where((s) => s.slotDate.weekday == dayOfWeek).toList();
    if (candidates.isEmpty) return null;

    final counts = <_RangeKey, int>{};
    final earliestDue = <_RangeKey, DateTime>{};
    for (final s in candidates) {
      final key = _RangeKey(s.startMinutes, s.endMinutes);
      counts[key] = (counts[key] ?? 0) + 1;
      final current = earliestDue[key];
      if (current == null || s.taskDueDate.isBefore(current)) {
        earliestDue[key] = s.taskDueDate;
      }
    }

    _RangeKey? best;
    var bestCount = 0;
    DateTime? bestDue;
    for (final entry in counts.entries) {
      final count = entry.value;
      final due = earliestDue[entry.key]!;
      final isBetter = best == null ||
          count > bestCount ||
          (count == bestCount && due.isBefore(bestDue!));
      if (isBetter) {
        best = entry.key;
        bestCount = count;
        bestDue = due;
      }
    }

    return DaySchedule(
      dayOfWeek: dayOfWeek,
      startMinutes: best!.start,
      endMinutes: best.end,
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

class _RangeKey {
  const _RangeKey(this.start, this.end);
  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _RangeKey && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

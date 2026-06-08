import 'package:drift/drift.dart';

@DataClassName('DayScheduleRow')
class DaySchedules extends Table {
  IntColumn get dayOfWeek => integer()();
  IntColumn get startMinutes => integer()();
  IntColumn get endMinutes => integer()();

  @override
  Set<Column> get primaryKey => {dayOfWeek};
}

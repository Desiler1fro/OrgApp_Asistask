import 'package:drift/drift.dart';

/// Tope máximo de tareas a trabajar en una fecha específica.
@DataClassName('DayLimitRow')
class DayLimits extends Table {
  DateTimeColumn get date => dateTime()();
  IntColumn get maxTasks => integer()();

  @override
  Set<Column> get primaryKey => {date};
}

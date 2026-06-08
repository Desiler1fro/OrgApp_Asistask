import 'package:drift/drift.dart';

import 'tasks_table.dart';

@DataClassName('AvailabilitySlotRow')
class AvailabilitySlots extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  IntColumn get startMinutes => integer()();
  IntColumn get endMinutes => integer()();
}

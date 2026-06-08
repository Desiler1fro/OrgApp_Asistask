import 'package:drift/drift.dart';

import 'subjects_table.dart';

@DataClassName('TaskRow')
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 128)();
  IntColumn get subjectId =>
      integer().references(Subjects, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get dueDate => dateTime()();
  IntColumn get difficulty => integer()();
  IntColumn get estimatedMinutes => integer()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  IntColumn get workedMinutes => integer().withDefault(const Constant(0))();
}

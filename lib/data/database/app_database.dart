import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/day_limits_dao.dart';
import 'daos/day_schedules_dao.dart';
import 'daos/subjects_dao.dart';
import 'daos/tasks_dao.dart';
import 'tables/availability_slots_table.dart';
import 'tables/day_limits_table.dart';
import 'tables/day_schedules_table.dart';
import 'tables/subjects_table.dart';
import 'tables/tasks_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Subjects, Tasks, AvailabilitySlots, DaySchedules, DayLimits],
  daos: [SubjectsDao, TasksDao, DaySchedulesDao, DayLimitsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(tasks);
            await m.createTable(availabilitySlots);
            await m.createTable(daySchedules);
          }
          if (from < 3) {
            await m.addColumn(tasks, tasks.isCompleted);
          }
          if (from < 4) {
            await m.addColumn(tasks, tasks.workedMinutes);
          }
          if (from < 5) {
            await m.createTable(dayLimits);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'org_app_pau.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

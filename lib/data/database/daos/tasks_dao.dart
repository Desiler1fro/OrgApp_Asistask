import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/availability_slots_table.dart';
import '../tables/tasks_table.dart';

part 'tasks_dao.g.dart';

@DriftAccessor(tables: [Tasks, AvailabilitySlots])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.db);

  Stream<List<TaskRow>> watchAll() {
    return (select(tasks)..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .watch();
  }

  Future<List<AvailabilitySlotRow>> slotsForTask(int taskId) {
    return (select(availabilitySlots)
          ..where((s) => s.taskId.equals(taskId))
          ..orderBy([(s) => OrderingTerm.asc(s.date)]))
        .get();
  }

  Stream<List<AvailabilitySlotRow>> watchAllSlots() {
    return (select(availabilitySlots)
          ..orderBy([(s) => OrderingTerm.asc(s.date)]))
        .watch();
  }

  Future<int> countBySubjectId(int subjectId) async {
    final expr = tasks.id.count();
    final row = await (selectOnly(tasks)
          ..addColumns([expr])
          ..where(tasks.subjectId.equals(subjectId)))
        .getSingle();
    return row.read(expr) ?? 0;
  }

  Future<int> insertTaskWithSlots({
    required TasksCompanion task,
    required List<AvailabilitySlotsCompanion> Function(int taskId) slotsBuilder,
  }) {
    return transaction(() async {
      final taskId = await into(tasks).insert(task);
      final slots = slotsBuilder(taskId);
      if (slots.isNotEmpty) {
        await batch((b) => b.insertAll(availabilitySlots, slots));
      }
      return taskId;
    });
  }

  Future<void> updateTaskFields({
    required int taskId,
    required int difficulty,
    required int estimatedMinutes,
    required int workedMinutes,
    required List<AvailabilitySlotsCompanion> Function(int taskId) slotsBuilder,
  }) {
    return transaction(() async {
      await (update(tasks)..where((t) => t.id.equals(taskId))).write(
        TasksCompanion(
          difficulty: Value(difficulty),
          estimatedMinutes: Value(estimatedMinutes),
          workedMinutes: Value(workedMinutes),
        ),
      );
      await (delete(availabilitySlots)
            ..where((s) => s.taskId.equals(taskId)))
          .go();
      final newSlots = slotsBuilder(taskId);
      if (newSlots.isNotEmpty) {
        await batch((b) => b.insertAll(availabilitySlots, newSlots));
      }
    });
  }

  Future<void> updateWorkedMinutes(int taskId, int workedMinutes) {
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(workedMinutes: Value(workedMinutes)),
    );
  }

  Future<void> markCompleted(int taskId) {
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      const TasksCompanion(isCompleted: Value(true)),
    );
  }

  Future<int> deleteTaskById(int taskId) {
    return (delete(tasks)..where((t) => t.id.equals(taskId))).go();
  }
}

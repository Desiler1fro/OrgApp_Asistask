import '../../domain/entities/availability_slot.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../database/app_database.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Task>> watchAll() {
    return _db.tasksDao.watchAll().map(
          (rows) => rows.map(_toEntity).toList(),
        );
  }

  @override
  Stream<List<AvailabilitySlot>> watchAllSlots() {
    return _db.tasksDao.watchAllSlots().map(
          (rows) => rows.map(_toSlotEntity).toList(),
        );
  }

  @override
  Future<List<AvailabilitySlot>> slotsForTask(int taskId) async {
    final rows = await _db.tasksDao.slotsForTask(taskId);
    return rows.map(_toSlotEntity).toList();
  }

  @override
  Future<int> create(
    TaskInput task,
    List<AvailabilitySlotInput> slots,
  ) {
    return _db.tasksDao.insertTaskWithSlots(
      task: TasksCompanion.insert(
        name: task.name,
        subjectId: task.subjectId,
        dueDate: task.dueDate,
        difficulty: task.difficulty,
        estimatedMinutes: task.estimatedMinutes,
      ),
      slotsBuilder: (taskId) => slots
          .map(
            (s) => AvailabilitySlotsCompanion.insert(
              taskId: taskId,
              date: s.date,
              startMinutes: s.startMinutes,
              endMinutes: s.endMinutes,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> updateFields({
    required int taskId,
    required int difficulty,
    required int estimatedMinutes,
    required int workedMinutes,
    required List<AvailabilitySlotInput> slots,
  }) {
    return _db.tasksDao.updateTaskFields(
      taskId: taskId,
      difficulty: difficulty,
      estimatedMinutes: estimatedMinutes,
      workedMinutes: workedMinutes,
      slotsBuilder: (id) => slots
          .map(
            (s) => AvailabilitySlotsCompanion.insert(
              taskId: id,
              date: s.date,
              startMinutes: s.startMinutes,
              endMinutes: s.endMinutes,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> updateWorkedMinutes(int taskId, int workedMinutes) {
    return _db.tasksDao.updateWorkedMinutes(taskId, workedMinutes);
  }

  @override
  Future<void> markCompleted(int taskId) {
    return _db.tasksDao.markCompleted(taskId);
  }

  @override
  Future<void> deleteById(int taskId) async {
    await _db.tasksDao.deleteTaskById(taskId);
  }

  Task _toEntity(TaskRow row) {
    return Task(
      id: row.id,
      name: row.name,
      subjectId: row.subjectId,
      dueDate: row.dueDate,
      difficulty: row.difficulty,
      estimatedMinutes: row.estimatedMinutes,
      createdAt: row.createdAt,
      isCompleted: row.isCompleted,
      workedMinutes: row.workedMinutes,
    );
  }

  AvailabilitySlot _toSlotEntity(AvailabilitySlotRow row) {
    return AvailabilitySlot(
      id: row.id,
      taskId: row.taskId,
      date: row.date,
      startMinutes: row.startMinutes,
      endMinutes: row.endMinutes,
    );
  }
}

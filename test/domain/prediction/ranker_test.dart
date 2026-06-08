import 'package:flutter_test/flutter_test.dart';
import 'package:org_app_pau/domain/entities/availability_slot.dart';
import 'package:org_app_pau/domain/entities/subject.dart';
import 'package:org_app_pau/domain/entities/task.dart';
import 'package:org_app_pau/domain/prediction/ranker.dart';

Task _task({
  required int id,
  DateTime? dueDate,
  int difficulty = 3,
  int estimatedMinutes = 120,
}) {
  return Task(
    id: id,
    name: 'Task $id',
    subjectId: 1,
    dueDate: dueDate ?? DateTime(2026, 5, 30),
    difficulty: difficulty,
    estimatedMinutes: estimatedMinutes,
    createdAt: DateTime(2026, 5, 26),
  );
}

AvailabilitySlot _slot(int id, int taskId, DateTime date) {
  return AvailabilitySlot(
    id: id,
    taskId: taskId,
    date: date,
    startMinutes: 14 * 60,
    endMinutes: 18 * 60,
  );
}

void main() {
  const ranker = Ranker();
  final now = DateTime(2026, 5, 26, 10, 0);
  final subjects = {
    1: Subject(
      id: 1,
      name: 'Mate',
      colorValue: 0xFF000000,
      liking: 3,
      createdAt: DateTime(2026, 5, 1),
    ),
  };

  test('daysAvailable cuenta solo días presentes/futuros', () {
    final task = _task(id: 1);
    final slots = {
      1: [
        _slot(1, 1, DateTime(2026, 5, 24)), // pasado
        _slot(2, 1, DateTime(2026, 5, 25)), // pasado
        _slot(3, 1, DateTime(2026, 5, 28)), // futuro
      ],
    };

    final scored = ranker.rank(
      tasks: [task],
      subjectsById: subjects,
      slotsByTaskId: slots,
      now: now,
    );

    expect(scored.single.daysAvailable, 1);
  });

  test('una tarea con menos días futuros es más urgente y rankea antes',
      () {
    final taskA = _task(id: 1); // pocos días futuros
    final taskB = _task(id: 2); // muchos días futuros
    final slots = {
      1: [
        _slot(1, 1, DateTime(2026, 5, 24)), // pasado
        _slot(2, 1, DateTime(2026, 5, 28)), // único futuro
      ],
      2: [
        _slot(3, 2, DateTime(2026, 5, 28)),
        _slot(4, 2, DateTime(2026, 5, 29)),
        _slot(5, 2, DateTime(2026, 5, 30)),
      ],
    };

    final scored = ranker.rank(
      tasks: [taskA, taskB],
      subjectsById: subjects,
      slotsByTaskId: slots,
      now: now,
    );

    expect(scored.first.taskId, 1);
    expect(scored.firstWhere((s) => s.taskId == 1).daysAvailable, 1);
    expect(scored.firstWhere((s) => s.taskId == 2).daysAvailable, 3);
    expect(
      scored.firstWhere((s) => s.taskId == 1).score,
      greaterThan(scored.firstWhere((s) => s.taskId == 2).score),
    );
  });

  test('isForToday es falso si el único slot de hoy ya pasó', () {
    final task = _task(id: 1, dueDate: DateTime(2026, 5, 30));
    final slots = {
      1: [
        AvailabilitySlot(
          id: 1,
          taskId: 1,
          date: DateTime(2026, 5, 26),
          startMinutes: 8 * 60,
          endMinutes: 9 * 60, // terminó antes de las 10:00
        ),
      ],
    };

    final scored = ranker.rank(
      tasks: [task],
      subjectsById: subjects,
      slotsByTaskId: slots,
      now: now,
    );

    expect(scored.single.isForToday, isFalse);
  });
}

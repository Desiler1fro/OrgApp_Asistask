import 'package:flutter_test/flutter_test.dart';
import 'package:org_app_pau/domain/entities/availability_slot.dart';
import 'package:org_app_pau/domain/entities/task.dart';
import 'package:org_app_pau/domain/prediction/scheduler.dart';

Task _task({
  required int id,
  required int estimatedMinutes,
  int workedMinutes = 0,
  DateTime? dueDate,
}) {
  return Task(
    id: id,
    name: 'Task $id',
    subjectId: 1,
    dueDate: dueDate ?? DateTime(2026, 5, 30),
    difficulty: 3,
    estimatedMinutes: estimatedMinutes,
    createdAt: DateTime(2026, 5, 26),
    workedMinutes: workedMinutes,
  );
}

AvailabilitySlot _slot({
  required int id,
  required int taskId,
  required DateTime date,
  required int startMinutes,
  required int endMinutes,
}) {
  return AvailabilitySlot(
    id: id,
    taskId: taskId,
    date: date,
    startMinutes: startMinutes,
    endMinutes: endMinutes,
  );
}

void main() {
  const scheduler = Scheduler();
  final now = DateTime(2026, 5, 26, 10, 0); // hoy 10:00

  group('Scheduler — contención entre tareas', () {
    test('dos tareas con la misma ventana no se solapan', () {
      final taskA = _task(id: 1, estimatedMinutes: 120);
      final taskB = _task(id: 2, estimatedMinutes: 120);
      final day = DateTime(2026, 5, 27);
      final slots = {
        1: [
          _slot(
            id: 1,
            taskId: 1,
            date: day,
            startMinutes: 14 * 60,
            endMinutes: 18 * 60,
          ),
        ],
        2: [
          _slot(
            id: 2,
            taskId: 2,
            date: day,
            startMinutes: 14 * 60,
            endMinutes: 18 * 60,
          ),
        ],
      };

      final result = scheduler.schedule(
        tasksInPriorityOrder: [taskA, taskB],
        slotsByTaskId: slots,
        now: now,
      );

      final a = result[1]!;
      final b = result[2]!;

      // La tarea de mayor prioridad toma el inicio de la ventana.
      expect(a.blocks.single.startMinutes, 14 * 60);
      expect(a.blocks.single.endMinutes, 16 * 60);
      // La segunda toma lo que queda libre, sin solaparse.
      expect(b.blocks.single.startMinutes, 16 * 60);
      expect(b.blocks.single.endMinutes, 18 * 60);
      expect(a.isComplete, isTrue);
      expect(b.isComplete, isTrue);
    });

    test('la segunda tarea queda incompleta si la primera consume todo', () {
      final taskA = _task(id: 1, estimatedMinutes: 120);
      final taskB = _task(id: 2, estimatedMinutes: 60);
      final day = DateTime(2026, 5, 27);
      final slots = {
        1: [
          _slot(
            id: 1,
            taskId: 1,
            date: day,
            startMinutes: 14 * 60,
            endMinutes: 16 * 60,
          ),
        ],
        2: [
          _slot(
            id: 2,
            taskId: 2,
            date: day,
            startMinutes: 14 * 60,
            endMinutes: 16 * 60,
          ),
        ],
      };

      final result = scheduler.schedule(
        tasksInPriorityOrder: [taskA, taskB],
        slotsByTaskId: slots,
        now: now,
      );

      expect(result[1]!.isComplete, isTrue);
      expect(result[2]!.blocks, isEmpty);
      expect(result[2]!.isComplete, isFalse);
      expect(result[2]!.remainingMinutes, 60);
    });
  });

  group('Scheduler — corte temporal de hoy', () {
    test('un slot de hoy se recorta a la hora actual redondeada', () {
      final later = DateTime(2026, 5, 26, 10, 15); // → redondea a 10:30
      final task = _task(id: 1, estimatedMinutes: 60);
      final slots = {
        1: [
          _slot(
            id: 1,
            taskId: 1,
            date: DateTime(2026, 5, 26),
            startMinutes: 9 * 60,
            endMinutes: 12 * 60,
          ),
        ],
      };

      final result = scheduler.schedule(
        tasksInPriorityOrder: [task],
        slotsByTaskId: slots,
        now: later,
      );

      final block = result[1]!.blocks.single;
      expect(block.startMinutes, 10 * 60 + 30); // 10:30
      expect(block.endMinutes, 11 * 60 + 30); // 11:30
    });
  });

  group('Scheduler — días pasados y redistribución', () {
    test('ignora slots de días pasados y replanifica a futuro', () {
      final task = _task(id: 1, estimatedMinutes: 120);
      final slots = {
        1: [
          _slot(
            id: 1,
            taskId: 1,
            date: DateTime(2026, 5, 25), // ayer
            startMinutes: 14 * 60,
            endMinutes: 18 * 60,
          ),
          _slot(
            id: 2,
            taskId: 1,
            date: DateTime(2026, 5, 27), // mañana
            startMinutes: 14 * 60,
            endMinutes: 18 * 60,
          ),
        ],
      };

      final result = scheduler.schedule(
        tasksInPriorityOrder: [task],
        slotsByTaskId: slots,
        now: now,
      );

      final blocks = result[1]!.blocks;
      expect(blocks, hasLength(1));
      expect(blocks.single.date, DateTime(2026, 5, 27));
      expect(blocks.single.startMinutes, 14 * 60);
      expect(blocks.single.endMinutes, 16 * 60);
      expect(result[1]!.isComplete, isTrue);
    });

    test('si solo hay días pasados, queda totalmente incompleta', () {
      final task = _task(id: 1, estimatedMinutes: 120);
      final slots = {
        1: [
          _slot(
            id: 1,
            taskId: 1,
            date: DateTime(2026, 5, 24),
            startMinutes: 14 * 60,
            endMinutes: 18 * 60,
          ),
        ],
      };

      final result = scheduler.schedule(
        tasksInPriorityOrder: [task],
        slotsByTaskId: slots,
        now: now,
      );

      expect(result[1]!.blocks, isEmpty);
      expect(result[1]!.isComplete, isFalse);
      expect(result[1]!.remainingMinutes, 120);
    });
  });

  group('Scheduler — capacidad insuficiente', () {
    test('marca incompleto cuando el tiempo futuro no alcanza', () {
      final task = _task(id: 1, estimatedMinutes: 300);
      final slots = {
        1: [
          _slot(
            id: 1,
            taskId: 1,
            date: DateTime(2026, 5, 27),
            startMinutes: 14 * 60,
            endMinutes: 15 * 60, // solo 60 min
          ),
        ],
      };

      final result = scheduler.schedule(
        tasksInPriorityOrder: [task],
        slotsByTaskId: slots,
        now: now,
      );

      expect(result[1]!.scheduledMinutes, 60);
      expect(result[1]!.remainingMinutes, 240);
      expect(result[1]!.isComplete, isFalse);
    });
  });

  group('Scheduler — progreso parcial (workedMinutes)', () {
    test('solo planifica el tiempo restante', () {
      final task = _task(id: 1, estimatedMinutes: 120, workedMinutes: 60);
      final slots = {
        1: [
          _slot(
            id: 1,
            taskId: 1,
            date: DateTime(2026, 5, 27),
            startMinutes: 14 * 60,
            endMinutes: 18 * 60,
          ),
        ],
      };

      final result = scheduler.schedule(
        tasksInPriorityOrder: [task],
        slotsByTaskId: slots,
        now: now,
      );

      final s = result[1]!;
      expect(s.blocks.single.startMinutes, 14 * 60);
      expect(s.blocks.single.endMinutes, 15 * 60); // solo 60 min restantes
      expect(s.scheduledMinutes, 60);
      expect(s.remainingMinutes, 0);
      expect(s.isComplete, isTrue);
    });

    test('worked >= estimado no genera bloques y queda completa', () {
      final task = _task(id: 1, estimatedMinutes: 120, workedMinutes: 120);
      final slots = {
        1: [
          _slot(
            id: 1,
            taskId: 1,
            date: DateTime(2026, 5, 27),
            startMinutes: 14 * 60,
            endMinutes: 18 * 60,
          ),
        ],
      };

      final result = scheduler.schedule(
        tasksInPriorityOrder: [task],
        slotsByTaskId: slots,
        now: now,
      );

      expect(result[1]!.blocks, isEmpty);
      expect(result[1]!.scheduledMinutes, 0);
      expect(result[1]!.remainingMinutes, 0);
      expect(result[1]!.isComplete, isTrue);
    });

    test('avance parcial sigue incompleto si el resto no alcanza', () {
      final task = _task(id: 1, estimatedMinutes: 300, workedMinutes: 60);
      final slots = {
        1: [
          _slot(
            id: 1,
            taskId: 1,
            date: DateTime(2026, 5, 27),
            startMinutes: 14 * 60,
            endMinutes: 15 * 60, // 60 min libres
          ),
        ],
      };

      final result = scheduler.schedule(
        tasksInPriorityOrder: [task],
        slotsByTaskId: slots,
        now: now,
      );

      final s = result[1]!;
      expect(s.scheduledMinutes, 60);
      // 300 - 60 trabajados - 60 planificados = 180
      expect(s.remainingMinutes, 180);
      expect(s.isComplete, isFalse);
    });
  });

  group('Scheduler — tope de tareas por día', () {
    final day = DateTime(2026, 5, 27);

    Map<int, List<AvailabilitySlot>> sameWindowFor(List<int> ids) {
      return {
        for (final id in ids)
          id: [
            _slot(
              id: id,
              taskId: id,
              date: day,
              startMinutes: 14 * 60,
              endMinutes: 18 * 60,
            ),
          ],
      };
    }

    test('no excede el tope y respeta la prioridad', () {
      final taskA = _task(id: 1, estimatedMinutes: 120);
      final taskB = _task(id: 2, estimatedMinutes: 120);

      final result = scheduler.schedule(
        tasksInPriorityOrder: [taskA, taskB],
        slotsByTaskId: sameWindowFor([1, 2]),
        now: now,
        maxTasksByDay: {day: 1},
      );

      // Solo la de mayor prioridad obtiene el día.
      expect(result[1]!.blocks, isNotEmpty);
      expect(result[2]!.blocks, isEmpty);
      expect(result[2]!.isComplete, isFalse);
    });

    test('completar una tarea libera el cupo del día', () {
      // Simula que la tarea A fue completada y ya no llega al Scheduler.
      final taskB = _task(id: 2, estimatedMinutes: 120);

      final result = scheduler.schedule(
        tasksInPriorityOrder: [taskB],
        slotsByTaskId: sameWindowFor([2]),
        now: now,
        maxTasksByDay: {day: 1},
      );

      expect(result[2]!.blocks, isNotEmpty);
      expect(result[2]!.isComplete, isTrue);
    });

    test('la misma tarea puede usar varios bloques del día sin gastar cupo',
        () {
      final task = _task(id: 1, estimatedMinutes: 120);
      final slots = {
        1: [
          _slot(
            id: 1,
            taskId: 1,
            date: day,
            startMinutes: 14 * 60,
            endMinutes: 15 * 60,
          ),
          _slot(
            id: 2,
            taskId: 1,
            date: day,
            startMinutes: 16 * 60,
            endMinutes: 17 * 60,
          ),
        ],
      };

      final result = scheduler.schedule(
        tasksInPriorityOrder: [task],
        slotsByTaskId: slots,
        now: now,
        maxTasksByDay: {day: 1},
      );

      expect(result[1]!.blocks, hasLength(2));
      expect(result[1]!.scheduledMinutes, 120);
      expect(result[1]!.isComplete, isTrue);
    });
  });

  group('Scheduler — combinación progreso + tope', () {
    test('respeta tope y planifica solo el restante', () {
      final day = DateTime(2026, 5, 27);
      final taskA = _task(id: 1, estimatedMinutes: 120, workedMinutes: 60);
      final taskB = _task(id: 2, estimatedMinutes: 120);
      final slots = {
        1: [
          _slot(
            id: 1,
            taskId: 1,
            date: day,
            startMinutes: 14 * 60,
            endMinutes: 18 * 60,
          ),
        ],
        2: [
          _slot(
            id: 2,
            taskId: 2,
            date: day,
            startMinutes: 14 * 60,
            endMinutes: 18 * 60,
          ),
        ],
      };

      final result = scheduler.schedule(
        tasksInPriorityOrder: [taskA, taskB],
        slotsByTaskId: slots,
        now: now,
        maxTasksByDay: {day: 1},
      );

      // A: solo 60 restantes, ocupa el único cupo del día.
      expect(result[1]!.scheduledMinutes, 60);
      expect(result[1]!.isComplete, isTrue);
      // B: bloqueada por el tope.
      expect(result[2]!.blocks, isEmpty);
      expect(result[2]!.isComplete, isFalse);
    });
  });
}

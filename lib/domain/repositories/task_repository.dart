import '../entities/availability_slot.dart';
import '../entities/task.dart';

abstract class TaskRepository {
  Stream<List<Task>> watchAll();
  Stream<List<AvailabilitySlot>> watchAllSlots();
  Future<List<AvailabilitySlot>> slotsForTask(int taskId);
  Future<int> create(TaskInput task, List<AvailabilitySlotInput> slots);

  /// Actualiza dificultad, tiempo estimado, tiempo trabajado y reemplaza
  /// los slots de la tarea. La operación es transaccional.
  Future<void> updateFields({
    required int taskId,
    required int difficulty,
    required int estimatedMinutes,
    required int workedMinutes,
    required List<AvailabilitySlotInput> slots,
  });

  /// Registra el tiempo trabajado acumulado de una tarea.
  Future<void> updateWorkedMinutes(int taskId, int workedMinutes);

  Future<void> markCompleted(int taskId);
  Future<void> deleteById(int taskId);
}

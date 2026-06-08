import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/availability_slot.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../database/database_provider.dart';
import 'task_repository_impl.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(ref.watch(appDatabaseProvider));
});

final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).watchAll();
});

final availabilitySlotsStreamProvider =
    StreamProvider<List<AvailabilitySlot>>((ref) {
  return ref.watch(taskRepositoryProvider).watchAllSlots();
});

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/notification_preferences_repository_provider.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/notification_service_provider.dart';
import '../../../domain/entities/notification_preferences.dart';
import '../../../domain/notifications/notification_planner.dart';
import '../../../domain/notifications/notification_request.dart';
import '../../task_list/providers/ranked_tasks_provider.dart';

/// Widget invisible que vive en el árbol de la app y mantiene las
/// notificaciones locales sincronizadas con el estado actual:
/// - Escucha tareas (rankedTasksProvider) + preferencias del usuario.
/// - En cada cambio reprograma todas las notificaciones (cancela las
///   pendientes que maneja y vuelve a programar el conjunto vigente).
///
/// Devuelve `child` directamente; no aporta UI propia.
class NotificationController extends ConsumerStatefulWidget {
  const NotificationController({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationController> createState() =>
      _NotificationControllerState();
}

class _NotificationControllerState
    extends ConsumerState<NotificationController> {
  bool _reprogramming = false;
  bool _dirty = false;

  @override
  Widget build(BuildContext context) {
    // Cada vez que cambian tareas o preferencias, disparamos un
    // reprograma. listen evita ejecutar en el build inicial sin datos.
    ref.listen(rankedTasksProvider, (_, __) => _trigger());
    ref.listen(notificationPreferencesStreamProvider, (_, __) => _trigger());

    return widget.child;
  }

  void _trigger() {
    if (_reprogramming) {
      _dirty = true;
      return;
    }
    _reprogramming = true;
    _reprogram().whenComplete(() {
      _reprogramming = false;
      if (_dirty) {
        _dirty = false;
        _trigger();
      }
    });
  }

  Future<void> _reprogram() async {
    final tasksAsync = ref.read(rankedTasksProvider);
    final prefsAsync = ref.read(notificationPreferencesStreamProvider);
    final tasks = tasksAsync.valueOrNull;
    final prefs = prefsAsync.valueOrNull ?? NotificationPreferences.defaults;
    if (tasks == null) return;

    final service = ref.read(notificationServiceProvider);

    final plannerTasks = [
      for (final view in tasks)
        PlannerTask(
          id: view.task.id,
          name: view.task.name,
          dueDate: view.task.dueDate,
          isCritical: view.score.isCritical,
          blocks: [
            for (final b in view.schedule.blocks)
              PlannerBlock(
                date: b.date,
                startMinutes: b.startMinutes,
                endMinutes: b.endMinutes,
              ),
          ],
        ),
    ];

    final requests = const NotificationPlanner().plan(
      tasks: plannerTasks,
      prefs: prefs,
      now: DateTime.now(),
    );

    // Cancelamos todo lo que manejamos y reprogramamos. Es el camino más
    // simple para que el resultado sea idéntico al plan vigente; los IDs
    // por tipo + taskId hacen que `zonedSchedule` reemplace en lugar de
    // duplicar, pero queremos quitar también los que ya no aplican.
    await service.cancelAllOfType(NotificationKind.deadline);
    await service.cancelAllOfType(NotificationKind.workBlock);
    await service.cancelAllOfType(NotificationKind.critical);

    for (final req in requests) {
      switch (req.kind) {
        case NotificationRequestKind.deadline:
          if (!prefs.deadlineEnabled) break;
          await service.scheduleDeadline(
            taskId: req.taskId,
            taskName: req.taskName,
            fireAt: req.fireAt,
          );
        case NotificationRequestKind.workBlock:
          if (!prefs.workBlockEnabled) break;
          await service.scheduleWorkBlock(
            taskId: req.taskId,
            blockIndex: req.blockIndex ?? 0,
            taskName: req.taskName,
            fireAt: req.fireAt,
            hourRange: req.hourRange ?? '',
          );
        case NotificationRequestKind.critical:
          if (!prefs.criticalEnabled) break;
          await service.scheduleCritical(
            taskId: req.taskId,
            taskName: req.taskName,
            fireAt: req.fireAt,
          );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/time_format.dart';
import '../../../data/repositories/task_repository_provider.dart';
import '../../../domain/entities/task.dart';
import '../providers/ranked_tasks_provider.dart';
import '../widgets/edit_task_sheet.dart';
import '../widgets/task_list_card.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  bool _historialExpanded = false;

  @override
  Widget build(BuildContext context) {
    final rankedAsync = ref.watch(rankedTasksProvider);
    final overdueAsync = ref.watch(overdueTasksProvider);
    final completedAsync = ref.watch(completedTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.tab2Tint,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Tu plan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.tab2Accent,
                fontWeight: FontWeight.w800,
              ),
        ),
        centerTitle: false,
      ),
      body: rankedAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.tab2Accent),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No pudimos cargar tus tareas.\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.graphiteSoft),
            ),
          ),
        ),
        data: (views) {
          final overdue = overdueAsync.valueOrNull ?? const [];
          final completed = completedAsync.valueOrNull ?? const [];
          final hasActive = views.isNotEmpty;
          final hasHistorial = overdue.isNotEmpty || completed.isNotEmpty;

          if (!hasActive && !hasHistorial) {
            return const _EmptyState();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              ...views.asMap().entries.map(
                    (entry) => TaskListCard(
                      key: ValueKey('task-${entry.value.task.id}'),
                      view: entry.value,
                      rank: entry.key + 1,
                      onEdit: () => EditTaskSheet.show(
                        context,
                        task: entry.value.task,
                        slots: entry.value.slots,
                      ),
                      onDelete: () =>
                          _confirmDelete(context, ref, entry.value.task),
                      onComplete: () =>
                          _markCompleted(ref, entry.value.task),
                      onLogProgress: (minutes) =>
                          _logProgress(ref, entry.value.task, minutes),
                    ),
                  ),
              if (hasHistorial) ...[
                if (hasActive) const SizedBox(height: 8),
                _HistorialHeader(
                  count: overdue.length + completed.length,
                  expanded: _historialExpanded,
                  onTap: () =>
                      setState(() => _historialExpanded = !_historialExpanded),
                ),
                if (_historialExpanded) ...[
                  const SizedBox(height: 8),
                  ...completed.map(
                    (v) => Opacity(
                      opacity: 0.55,
                      child: _CompletedTaskCard(
                        key: ValueKey('completed-${v.task.id}'),
                        view: v,
                        onDelete: () => _confirmDelete(context, ref, v.task),
                      ),
                    ),
                  ),
                  ...overdue.map(
                    (v) => Opacity(
                      opacity: 0.55,
                      child: _OverdueTaskCard(
                        key: ValueKey('overdue-${v.task.id}'),
                        view: v,
                        onDelete: () => _confirmDelete(context, ref, v.task),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _markCompleted(WidgetRef ref, Task task) async {
    await ref.read(taskRepositoryProvider).markCompleted(task.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${task.name}" marcada como realizada.'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.tab2Accent,
        ),
      );
    }
  }

  Future<void> _logProgress(WidgetRef ref, Task task, int minutesToAdd) async {
    final prev = task.workedMinutes;
    final next = (prev + minutesToAdd).clamp(0, task.estimatedMinutes);
    if (next == prev) return;

    final repo = ref.read(taskRepositoryProvider);
    await repo.updateWorkedMinutes(task.id, next);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Avance: ${TimeFormat.duration(next)} de '
          '${TimeFormat.duration(task.estimatedMinutes)}.',
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: AppColors.tab2Accent,
        action: SnackBarAction(
          label: 'Deshacer',
          textColor: Colors.white,
          onPressed: () => repo.updateWorkedMinutes(task.id, prev),
        ),
      ),
    );

    if (next >= task.estimatedMinutes) {
      await _promptMarkCompleted(ref, task);
    }
  }

  Future<void> _promptMarkCompleted(WidgetRef ref, Task task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          '¿Marcar como realizada?',
          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                color: AppColors.graphite,
                fontWeight: FontWeight.w700,
              ),
        ),
        content: Text(
          'Completaste el tiempo estimado de "${task.name}". '
          'Puedes marcarla como realizada o seguir trabajándola.',
          style: const TextStyle(color: AppColors.graphiteSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.graphiteSoft,
            ),
            child: const Text('Aún no'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.tab2Accent,
            ),
            child: const Text(
              'Marcar realizada',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(taskRepositoryProvider).markCompleted(task.id);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Eliminar tarea',
          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                color: AppColors.graphite,
                fontWeight: FontWeight.w700,
              ),
        ),
        content: Text(
          '¿Seguro que quieres eliminar "${task.name}"? '
          'Sus bloques horarios también se borrarán.',
          style: const TextStyle(color: AppColors.graphiteSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.graphiteSoft,
            ),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.calendarDeadline,
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(taskRepositoryProvider).deleteById(task.id);
  }
}

// ── Historial header ──────────────────────────────────────────────────

class _HistorialHeader extends StatelessWidget {
  const _HistorialHeader({
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.warmGray.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.warmGray,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.history_rounded,
              size: 20,
              color: AppColors.graphiteSoft,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Historial ($count)',
                style: const TextStyle(
                  color: AppColors.graphiteSoft,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.graphiteSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Completed task card ───────────────────────────────────────────────

class _CompletedTaskCard extends StatelessWidget {
  const _CompletedTaskCard({
    required this.view,
    required this.onDelete,
    super.key,
  });

  final CompletedTaskView view;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subjectColor = Color(view.subject.colorValue);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.warmGray, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: subjectColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          view.subject.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.graphiteSoft,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const _RealizadaBadge(),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    view.task.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.graphite,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Entrega ${TimeFormat.shortDate(view.task.dueDate)}',
                    style: const TextStyle(
                      color: AppColors.graphiteSoft,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.calendarDeadline,
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Overdue task card ─────────────────────────────────────────────────

class _OverdueTaskCard extends StatelessWidget {
  const _OverdueTaskCard({
    required this.view,
    required this.onDelete,
    super.key,
  });

  final OverdueTaskView view;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subjectColor = Color(view.subject.colorValue);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.warmGray, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: subjectColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          view.subject.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.graphiteSoft,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const _VencidaBadge(),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    view.task.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.graphite,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Venció ${TimeFormat.shortDate(view.task.dueDate)}',
                    style: const TextStyle(
                      color: AppColors.calendarDeadline,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.calendarDeadline,
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }
}

class _RealizadaBadge extends StatelessWidget {
  const _RealizadaBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tab2Tint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.tab2Accent, width: 1),
      ),
      child: const Text(
        'Realizada',
        style: TextStyle(
          color: AppColors.tab2Accent,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _VencidaBadge extends StatelessWidget {
  const _VencidaBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEAEF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.calendarDeadline, width: 1),
      ),
      child: const Text(
        'Vencida',
        style: TextStyle(
          color: AppColors.calendarDeadline,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.tab2Primary.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.checklist_rounded,
                size: 40,
                color: AppColors.tab2Accent,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Aún no hay tareas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Agrega tu primera tarea desde la pestaña "Agregar". '
              'Aquí verás el orden sugerido.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.graphiteSoft,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

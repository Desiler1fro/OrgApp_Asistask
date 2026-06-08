import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/time_format.dart';
import '../../../domain/prediction/scheduler.dart';
import '../providers/ranked_tasks_provider.dart';

/// Tarjeta expandible para un ítem del listado ordenado.
class TaskListCard extends StatefulWidget {
  const TaskListCard({
    required this.view,
    required this.rank,
    required this.onEdit,
    required this.onDelete,
    required this.onComplete,
    required this.onLogProgress,
    super.key,
  });

  final RankedTaskView view;
  final int rank;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onComplete;

  /// Registra avance sumando `minutesToAdd` al tiempo trabajado.
  final ValueChanged<int> onLogProgress;

  @override
  State<TaskListCard> createState() => _TaskListCardState();
}

class _TaskListCardState extends State<TaskListCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final subjectColor = Color(view.subject.colorValue);
    final next = view.nextBlock(DateTime.now());
    final isForToday = view.score.isForToday;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isForToday
              ? AppColors.tab2Accent
              : AppColors.tab2Primary.withValues(alpha: 0.35),
          width: isForToday ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                rank: widget.rank,
                subjectName: view.subject.name,
                subjectColor: subjectColor,
                taskName: view.task.name,
                isForToday: isForToday,
                expanded: _expanded,
                onComplete: widget.onComplete,
              ),
              const SizedBox(height: 10),
              _NextBlockRow(
                block: next,
                dueDate: view.task.dueDate,
                incomplete: !view.schedule.isComplete &&
                    view.schedule.estimatedMinutes > 0,
              ),
              if (view.task.workedMinutes > 0) ...[
                const SizedBox(height: 10),
                _ProgressBar(
                  workedMinutes: view.task.workedMinutes,
                  estimatedMinutes: view.task.estimatedMinutes,
                ),
              ],
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: _ExpandedDetails(
                          view: view,
                          onEdit: widget.onEdit,
                          onDelete: widget.onDelete,
                          onLogProgress: widget.onLogProgress,
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.rank,
    required this.subjectName,
    required this.subjectColor,
    required this.taskName,
    required this.isForToday,
    required this.expanded,
    required this.onComplete,
  });

  final int rank;
  final String subjectName;
  final Color subjectColor;
  final String taskName;
  final bool isForToday;
  final bool expanded;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.tab2Tint,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.tab2Primary, width: 1.5),
          ),
          child: Text(
            '$rank',
            style: const TextStyle(
              color: AppColors.tab2Accent,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: subjectColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      subjectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.graphiteSoft,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isForToday) ...[
                    const SizedBox(width: 8),
                    const _TodayBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                taskName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onComplete,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.tab2Accent,
                size: 22,
              ),
            ),
          ),
        ),
        AnimatedRotation(
          turns: expanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.tab2Accent,
          ),
        ),
      ],
    );
  }
}

class _TodayBadge extends StatelessWidget {
  const _TodayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tab2Accent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'HOY',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _NextBlockRow extends StatelessWidget {
  const _NextBlockRow({
    required this.block,
    required this.dueDate,
    required this.incomplete,
  });

  final ScheduledBlock? block;
  final DateTime dueDate;
  final bool incomplete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _InfoChip(
          icon: Icons.schedule_rounded,
          label: block == null
              ? 'Sin horario asignado'
              : '${TimeFormat.shortDate(block!.date)} · '
                  '${TimeFormat.range(block!.startMinutes, block!.endMinutes)}',
          color: AppColors.tab2Accent,
          background: AppColors.tab2Tint,
        ),
        _InfoChip(
          icon: Icons.event_rounded,
          label: 'Entrega ${TimeFormat.shortDate(dueDate)}',
          color: AppColors.calendarDeadline,
          background: const Color(0xFFFCEAEF),
        ),
        if (incomplete)
          const _InfoChip(
            icon: Icons.warning_amber_rounded,
            label: 'No alcanza el tiempo',
            color: Color(0xFFB57A1F),
            background: Color(0xFFFBEFD6),
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedDetails extends StatelessWidget {
  const _ExpandedDetails({
    required this.view,
    required this.onEdit,
    required this.onDelete,
    required this.onLogProgress,
  });

  final RankedTaskView view;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<int> onLogProgress;

  @override
  Widget build(BuildContext context) {
    final task = view.task;
    final schedule = view.schedule;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Divider(),
        const SizedBox(height: 12),
        _DetailRow(
          label: 'Dificultad',
          value: _DifficultyDots(level: task.difficulty),
        ),
        const SizedBox(height: 8),
        _DetailRow(
          label: 'Duración',
          value: Text(
            TimeFormat.duration(task.estimatedMinutes),
            style: const TextStyle(
              color: AppColors.graphite,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _DetailRow(
          label: 'Días disponibles',
          value: Text(
            '${view.score.daysAvailable}',
            style: const TextStyle(
              color: AppColors.graphite,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Bloques asignados',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.tab2Accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
        ),
        const SizedBox(height: 6),
        if (schedule.blocks.isEmpty)
          const Text(
            'No hay bloques asignados.',
            style: TextStyle(
              color: AppColors.graphiteSoft,
            ),
          )
        else
          ...schedule.blocks.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.fiber_manual_record_rounded,
                    size: 8,
                    color: AppColors.tab2Accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${TimeFormat.shortDate(b.date)} · '
                      '${TimeFormat.range(b.startMinutes, b.endMinutes)} '
                      '(${TimeFormat.duration(b.durationMinutes)})',
                      style: const TextStyle(
                        color: AppColors.graphite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _BlockDoneButton(
                    onTap: () => onLogProgress(b.durationMinutes),
                  ),
                ],
              ),
            ),
          ),
        if (!schedule.isComplete && schedule.estimatedMinutes > 0) ...[
          const SizedBox(height: 6),
          Text(
            'Faltan ${TimeFormat.duration(schedule.remainingMinutes)} sin asignar.',
            style: const TextStyle(
              color: AppColors.calendarDeadline,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Editar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.tab2Accent,
                  side: const BorderSide(
                    color: AppColors.tab2Accent,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Eliminar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.calendarDeadline,
                  side: const BorderSide(
                    color: AppColors.calendarDeadline,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        color: AppColors.tab2Primary.withValues(alpha: 0.25),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.graphiteSoft,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(child: value),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.workedMinutes,
    required this.estimatedMinutes,
  });

  final int workedMinutes;
  final int estimatedMinutes;

  @override
  Widget build(BuildContext context) {
    final fraction = estimatedMinutes <= 0
        ? 0.0
        : (workedMinutes / estimatedMinutes).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.timelapse_rounded,
              size: 14,
              color: AppColors.tab2Accent,
            ),
            const SizedBox(width: 6),
            Text(
              'Trabajado ${TimeFormat.duration(workedMinutes)} de '
              '${TimeFormat.duration(estimatedMinutes)}',
              style: const TextStyle(
                color: AppColors.tab2Accent,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: AppColors.tab2Primary.withValues(alpha: 0.25),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.tab2Accent),
          ),
        ),
      ],
    );
  }
}

class _BlockDoneButton extends StatelessWidget {
  const _BlockDoneButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: AppColors.tab2Accent,
            ),
            SizedBox(width: 4),
            Text(
              'Hecho',
              style: TextStyle(
                color: AppColors.tab2Accent,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyDots extends StatelessWidget {
  const _DifficultyDots({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < level;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: filled ? AppColors.tab2Accent : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.tab2Accent,
                width: 1.5,
              ),
            ),
          ),
        );
      }),
    );
  }
}

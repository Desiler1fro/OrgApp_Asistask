import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/time_format.dart';
import '../../../domain/entities/subject.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/prediction/scheduler.dart';
import '../../task_list/providers/ranked_tasks_provider.dart';

enum _EventKind { work, deadline }

class _DayEvent {
  const _DayEvent({
    required this.kind,
    required this.task,
    required this.subject,
    this.block,
  });

  final _EventKind kind;
  final Task task;
  final Subject subject;
  final ScheduledBlock? block;

  bool get isWork => kind == _EventKind.work;
  bool get isDeadline => kind == _EventKind.deadline;
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = dateOnly(DateTime.now());
    _focusedDay = today;
    _selectedDay = today;
  }

  @override
  Widget build(BuildContext context) {
    final rankedAsync = ref.watch(rankedTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario')),
      body: rankedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'No se pudo cargar el calendario.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.graphiteSoft,
                ),
          ),
        ),
        data: (views) {
          final events = _buildEvents(views);
          final dayEvents = events[dateOnly(_selectedDay)] ?? const [];

          return Column(
            children: [
              _CalendarView(
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                events: events,
                onDaySelected: (selected, focused) {
                  if (isSameDay(selected, _selectedDay)) return;
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focused) => _focusedDay = focused,
              ),
              const _SectionDivider(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.04),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _EventList(
                    key: ValueKey(dateOnly(_selectedDay)),
                    day: _selectedDay,
                    events: dayEvents,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<DateTime, List<_DayEvent>> _buildEvents(List<RankedTaskView> views) {
    final map = <DateTime, List<_DayEvent>>{};
    for (final v in views) {
      for (final b in v.schedule.blocks) {
        final day = dateOnly(b.date);
        map.putIfAbsent(day, () => []).add(
              _DayEvent(
                kind: _EventKind.work,
                task: v.task,
                subject: v.subject,
                block: b,
              ),
            );
      }
      final dueDay = dateOnly(v.task.dueDate);
      map.putIfAbsent(dueDay, () => []).add(
            _DayEvent(
              kind: _EventKind.deadline,
              task: v.task,
              subject: v.subject,
            ),
          );
    }
    return map;
  }
}

// ───────────────────────────────────────────────────────────────────────
// Calendario

class _CalendarView extends StatelessWidget {
  const _CalendarView({
    required this.focusedDay,
    required this.selectedDay,
    required this.events,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final Map<DateTime, List<_DayEvent>> events;
  final OnDaySelected onDaySelected;
  final ValueChanged<DateTime> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: TableCalendar<_DayEvent>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: focusedDay,
        locale: 'es',
        startingDayOfWeek: StartingDayOfWeek.monday,
        availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
        selectedDayPredicate: (d) => isSameDay(d, selectedDay),
        eventLoader: (d) => events[dateOnly(d)] ?? const [],
        onDaySelected: onDaySelected,
        onPageChanged: onPageChanged,
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: AppColors.tab3Accent,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: AppColors.tab3Accent,
          ),
          titleTextStyle: TextStyle(
            color: AppColors.graphite,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          headerPadding: EdgeInsets.symmetric(vertical: 8),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: AppColors.graphiteSoft,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          weekendStyle: TextStyle(
            color: AppColors.graphiteSoft,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        calendarStyle: CalendarStyle(
          cellMargin: const EdgeInsets.all(4),
          todayDecoration: BoxDecoration(
            color: AppColors.tab3Tint,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.tab3Accent, width: 1.5),
          ),
          todayTextStyle: const TextStyle(
            color: AppColors.tab3Accent,
            fontWeight: FontWeight.w700,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.tab3Accent,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          defaultTextStyle: const TextStyle(
            color: AppColors.graphite,
            fontWeight: FontWeight.w500,
          ),
          weekendTextStyle: const TextStyle(
            color: AppColors.graphite,
            fontWeight: FontWeight.w500,
          ),
          outsideTextStyle: TextStyle(
            color: AppColors.graphiteSoft.withValues(alpha: 0.4),
            fontWeight: FontWeight.w400,
          ),
          markersAlignment: Alignment.bottomCenter,
          markersOffset: const PositionedOffset(bottom: 4),
        ),
        calendarBuilders: CalendarBuilders<_DayEvent>(
          markerBuilder: (context, day, dayEvents) {
            if (dayEvents.isEmpty) return const SizedBox.shrink();
            final hasWork = dayEvents.any((e) => e.isWork);
            final hasDeadline = dayEvents.any((e) => e.isDeadline);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasWork)
                  const _Marker(color: AppColors.calendarScheduled),
                if (hasWork && hasDeadline) const SizedBox(width: 3),
                if (hasDeadline)
                  const _Marker(color: AppColors.calendarDeadline),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.warmGray.withValues(alpha: 0.5),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────
// Lista de eventos del día seleccionado

class _EventList extends StatelessWidget {
  const _EventList({
    super.key,
    required this.day,
    required this.events,
  });

  final DateTime day;
  final List<_DayEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _EmptyState(day: day);
    }

    final sorted = [...events]..sort((a, b) {
        if (a.kind != b.kind) return a.isWork ? -1 : 1;
        if (a.isWork && b.isWork) {
          final aStart = a.block?.startMinutes ?? 0;
          final bStart = b.block?.startMinutes ?? 0;
          final byStart = aStart.compareTo(bStart);
          if (byStart != 0) return byStart;
        }
        return a.task.id.compareTo(b.task.id);
      });

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: sorted.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == 0) return _DayHeader(day: day, count: sorted.length);
        return _CalendarEventCard(event: sorted[i - 1]);
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 44,
              color: AppColors.graphiteSoft,
            ),
            const SizedBox(height: 10),
            Text(
              'Sin tareas para el ${TimeFormat.shortDate(day)}',
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

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.count});

  final DateTime day;
  final int count;

  @override
  Widget build(BuildContext context) {
    final label = '$count ${count == 1 ? "evento" : "eventos"}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              TimeFormat.fullDate(day),
              style: const TextStyle(
                color: AppColors.graphite,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.graphiteSoft,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({required this.event});

  final _DayEvent event;

  @override
  Widget build(BuildContext context) {
    final isWork = event.isWork;
    final accent =
        isWork ? AppColors.calendarScheduled : AppColors.calendarDeadline;
    final tint = isWork ? AppColors.tab3Tint : const Color(0xFFFCEAEF);
    final subjectColor = Color(event.subject.colorValue);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
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
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: subjectColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        event.subject.name,
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
                    _KindBadge(
                      label: isWork ? 'Trabajo' : 'Entrega',
                      background: tint,
                      foreground: accent,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.task.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),
                if (isWork && event.block != null) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 13, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        '${TimeFormat.range(event.block!.startMinutes, event.block!.endMinutes)} · '
                        '${TimeFormat.duration(event.block!.durationMinutes)}',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KindBadge extends StatelessWidget {
  const _KindBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

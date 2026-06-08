import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/time_format.dart';
import '../../../data/repositories/day_limit_repository_provider.dart';
import '../../../domain/entities/day_limit.dart';

/// Configuración del tope máximo de tareas a trabajar por fecha.
class DayLimitsScreen extends ConsumerWidget {
  const DayLimitsScreen({super.key});

  Future<void> _addLimit(
    BuildContext context,
    WidgetRef ref,
    List<DayLimit> current,
  ) async {
    final today = dateOnly(DateTime.now());
    final date = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDate: today,
      locale: const Locale('es'),
    );
    if (date == null || !context.mounted) return;
    final d = dateOnly(date);
    int initial = 2;
    for (final l in current) {
      if (dateOnly(l.date).isAtSameMomentAs(d)) {
        initial = l.maxTasks;
        break;
      }
    }
    final value = await _MaxTasksSheet.show(
      context,
      date: d,
      initialValue: initial,
    );
    if (value == null) return;
    await ref.read(dayLimitRepositoryProvider).setLimit(d, value);
  }

  Future<void> _editLimit(
    BuildContext context,
    WidgetRef ref,
    DayLimit limit,
  ) async {
    final value = await _MaxTasksSheet.show(
      context,
      date: dateOnly(limit.date),
      initialValue: limit.maxTasks,
    );
    if (value == null) return;
    await ref
        .read(dayLimitRepositoryProvider)
        .setLimit(dateOnly(limit.date), value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limitsAsync = ref.watch(dayLimitsStreamProvider);
    final limits = limitsAsync.valueOrNull ?? const <DayLimit>[];

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.graphite,
        title: const Text(
          'Tope por día',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.tab3Accent,
        foregroundColor: Colors.white,
        onPressed: () => _addLimit(context, ref, limits),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Agregar tope',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: limitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No pudimos cargar los topes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        data: (list) {
          if (list.isEmpty) return const _EmptyState();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final l = list[i];
              return _LimitTile(
                limit: l,
                onTap: () => _editLimit(context, ref, l),
                onDelete: () => ref
                    .read(dayLimitRepositoryProvider)
                    .removeLimit(dateOnly(l.date)),
              );
            },
          );
        },
      ),
    );
  }
}

class _LimitTile extends StatelessWidget {
  const _LimitTile({
    required this.limit,
    required this.onTap,
    required this.onDelete,
  });

  final DayLimit limit;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.beige,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              const Icon(
                Icons.event_rounded,
                size: 22,
                color: AppColors.tab3Accent,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TimeFormat.fullDate(limit.date),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      'Máximo ${limit.maxTasks} '
                      '${limit.maxTasks == 1 ? 'tarea' : 'tareas'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.graphiteSoft,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                iconSize: 20,
                color: AppColors.graphiteSoft,
                tooltip: 'Quitar tope',
                onPressed: onDelete,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaxTasksSheet extends StatefulWidget {
  const _MaxTasksSheet({required this.date, required this.initialValue});

  final DateTime date;
  final int initialValue;

  static Future<int?> show(
    BuildContext context, {
    required DateTime date,
    required int initialValue,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          _MaxTasksSheet(date: date, initialValue: initialValue),
    );
  }

  @override
  State<_MaxTasksSheet> createState() => _MaxTasksSheetState();
}

class _MaxTasksSheetState extends State<_MaxTasksSheet> {
  late int _value = widget.initialValue;

  static const int _min = 1;
  static const int _max = 10;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.warmGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tope para el ${TimeFormat.fullDate(widget.date)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Máximo de tareas distintas a trabajar ese día.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.graphiteSoft,
                  ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warmGray, width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _value > _min
                        ? () => setState(() => _value--)
                        : null,
                    icon: const Icon(Icons.remove_rounded),
                    color: AppColors.tab3Accent,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$_value ${_value == 1 ? 'tarea' : 'tareas'}',
                        style: const TextStyle(
                          color: AppColors.graphite,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _value < _max
                        ? () => setState(() => _value++)
                        : null,
                    icon: const Icon(Icons.add_rounded),
                    color: AppColors.tab3Accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.graphiteSoft,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_value),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.tab3Accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Guardar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Sin topes configurados.\n'
          'Agrega uno para limitar cuántas tareas trabajas en un día.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.graphiteSoft,
              ),
        ),
      ),
    );
  }
}

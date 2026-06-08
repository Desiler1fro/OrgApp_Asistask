import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../data/repositories/subject_repository_provider.dart';
import '../../../domain/entities/subject.dart';
import '../../onboarding/widgets/subject_dot.dart';
import '../widgets/add_subject_sheet.dart';
import '../widgets/change_color_sheet.dart';

class ManageSubjectsScreen extends ConsumerWidget {
  const ManageSubjectsScreen({super.key});

  static const int _defaultLiking = 3;

  Set<int> _usedColors(List<Subject> subjects) =>
      subjects.map((s) => s.colorValue).toSet();

  int _suggestColorValue(List<Subject> subjects) {
    final used = _usedColors(subjects);
    for (final c in AppColors.subjects) {
      final v = c.toARGB32();
      if (!used.contains(v)) return v;
    }
    return AppColors
        .subjects[subjects.length % AppColors.subjects.length]
        .toARGB32();
  }

  Future<void> _openAddSheet(
    BuildContext context,
    WidgetRef ref,
    List<Subject> current,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSubjectSheet(
        usedColorValues: _usedColors(current),
        suggestedColorValue: _suggestColorValue(current),
        onSubmit: (name, colorValue) async {
          final duplicate = current.any(
            (s) => s.name.toLowerCase() == name.toLowerCase(),
          );
          if (duplicate) return false;
          await ref.read(subjectRepositoryProvider).insertOne(
                SubjectInput(
                  name: name,
                  colorValue: colorValue,
                  liking: _defaultLiking,
                ),
              );
          return true;
        },
      ),
    );
  }

  Future<void> _openChangeColorSheet(
    BuildContext context,
    WidgetRef ref,
    Subject subject,
    List<Subject> current,
  ) async {
    final usedExcludingThis = current
        .where((s) => s.id != subject.id)
        .map((s) => s.colorValue)
        .toSet();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeColorSheet(
        subject: subject,
        usedColorValues: usedExcludingThis,
        onSubmit: (colorValue) {
          return ref
              .read(subjectRepositoryProvider)
              .updateColor(subject.id, colorValue);
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Subject subject,
  ) async {
    final repo = ref.read(subjectRepositoryProvider);
    final count = await repo.taskCount(subject.id);
    if (!context.mounted) return;

    if (count > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cream,
          title: const Text(
            '¿Eliminar materia?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            '"${subject.name}" tiene $count ${count == 1 ? 'tarea asociada' : 'tareas asociadas'}. '
            'Al eliminar la materia también se eliminarán esas tareas. '
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.calendarDeadline,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Eliminar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await repo.deleteById(subject.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsStreamProvider);
    final subjects = subjectsAsync.valueOrNull ?? const <Subject>[];

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.graphite,
        title: const Text(
          'Gestionar materias',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.tab1Accent,
        foregroundColor: Colors.white,
        onPressed: () => _openAddSheet(context, ref, subjects),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Agregar materia',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No pudimos cargar las materias.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final s = list[i];
              return _SubjectTile(
                subject: s,
                onTap: () => _openChangeColorSheet(context, ref, s, list),
                onDelete: () => _confirmDelete(context, ref, s),
              );
            },
          );
        },
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  const _SubjectTile({
    required this.subject,
    required this.onTap,
    required this.onDelete,
  });

  final Subject subject;
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
              SubjectDot(color: Color(subject.colorValue), size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  subject.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const Icon(
                Icons.palette_outlined,
                size: 20,
                color: AppColors.graphiteSoft,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                iconSize: 20,
                color: AppColors.graphiteSoft,
                tooltip: 'Eliminar',
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Aún no tienes materias.\nAgrega la primera con el botón de abajo.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.graphiteSoft,
              ),
        ),
      ),
    );
  }
}

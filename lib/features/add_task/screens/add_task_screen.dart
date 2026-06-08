import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../data/repositories/subject_repository_provider.dart';
import '../../../domain/entities/subject.dart';
import '../state/add_task_notifier.dart';
import '../state/add_task_state.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/pug_mascot.dart';
import '../widgets/question_inputs.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onSaved(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.tab1Accent,
        behavior: SnackBarBehavior.floating,
        content: Text(
          '¡Tarea guardada!',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      ref.read(addTaskNotifierProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AddTaskState>(addTaskNotifierProvider, (prev, next) {
      if (prev == null || next.messages.length > prev.messages.length) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());
      }
      final justSaved =
          (prev?.recentlySaved ?? false) == false && next.recentlySaved;
      if (justSaved) _onSaved(context);
    });

    final state = ref.watch(addTaskNotifierProvider);
    final subjectsAsync = ref.watch(subjectsStreamProvider);

    final screenHeight = MediaQuery.of(context).size.height;
    final pugAreaHeight = screenHeight / 3;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: state.messages.length,
                    itemBuilder: (context, i) =>
                        ChatMessageBubble(message: state.messages[i]),
                  ),
                ),
                SizedBox(
                  height: pugAreaHeight,
                  child: Center(
                    child: PugMascot(
                      mood: state.pugMood,
                      size: pugAreaHeight * 0.85,
                    ),
                  ),
                ),
                _InputArea(
                  state: state,
                  subjectsAsync: subjectsAsync,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputArea extends ConsumerWidget {
  const _InputArea({
    required this.state,
    required this.subjectsAsync,
  });

  final AddTaskState state;
  final AsyncValue<List<Subject>> subjectsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(addTaskNotifierProvider.notifier);
    final subjects = subjectsAsync.valueOrNull ?? const <Subject>[];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.92),
        border: const Border(
          top: BorderSide(color: AppColors.warmGray, width: 0.5),
        ),
      ),
      child: _buildForStep(state, subjects, notifier),
    );
  }

  Widget _buildForStep(
    AddTaskState state,
    List<Subject> subjects,
    AddTaskNotifier notifier,
  ) {
    switch (state.step) {
      case AddTaskStep.askName:
        return NameInput(onSubmit: notifier.submitName);

      case AddTaskStep.askSubject:
        if (subjects.isEmpty) {
          return const _Hint('Cargando materias…');
        }
        return SubjectPicker(
          subjects: subjects,
          onSelect: notifier.submitSubject,
        );

      case AddTaskStep.askDueDate:
        return DueDatePicker(onSubmit: notifier.submitDueDate);

      case AddTaskStep.askDifficulty:
        final subject = subjects
            .where((s) => s.id == state.subjectId)
            .cast<Subject?>()
            .firstWhere((_) => true, orElse: () => null);
        final color = subject != null
            ? Color(subject.colorValue)
            : AppColors.tab1Accent;
        return DifficultyPicker(
          color: color,
          onSubmit: notifier.submitDifficulty,
        );

      case AddTaskStep.askDuration:
        return DurationPicker(onSubmit: notifier.submitDuration);

      case AddTaskStep.askDiscardDays:
        return DiscardDaysPicker(
          days: notifier.windowDays(),
          discarded: state.discardedDates,
          onToggle: notifier.toggleDiscarded,
          onConfirm: notifier.confirmDiscardedDays,
        );

      case AddTaskStep.askSchedules:
        return TimeRangePicker(
          key: ValueKey(state.currentScheduleIndex),
          prefill: state.currentPrefill,
          minStartMinutes: state.currentMinStartMinutes,
          onSubmit: notifier.submitSchedule,
        );

      case AddTaskStep.celebrating:
        return _Hint(
          state.saving ? 'Guardando…' : '¡Todo listo!',
        );
    }
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.graphiteSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

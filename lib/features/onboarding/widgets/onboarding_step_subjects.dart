import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../state/onboarding_notifier.dart';
import 'subject_dot.dart';

class OnboardingStepSubjects extends ConsumerStatefulWidget {
  const OnboardingStepSubjects({required this.onContinue, super.key});

  final VoidCallback onContinue;

  @override
  ConsumerState<OnboardingStepSubjects> createState() =>
      _OnboardingStepSubjectsState();
}

class _OnboardingStepSubjectsState
    extends ConsumerState<OnboardingStepSubjects> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    ref.read(onboardingNotifierProvider.notifier).addSubject(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('¿Qué materias cursas?', style: textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'Agrega las materias que quieres organizar. A cada una le asignamos un color para identificarla.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.graphiteSoft,
              ),
            ),
            const SizedBox(height: 24),
            _SubjectInput(
              controller: _controller,
              focusNode: _focusNode,
              onSubmit: _submit,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: state.subjects.isEmpty
                  ? const _EmptyHint()
                  : ListView.separated(
                      itemCount: state.subjects.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final s = state.subjects[i];
                        return _SubjectRow(
                          name: s.name,
                          color: Color(s.colorValue),
                          onRemove: () => notifier.removeAt(i),
                        ).animate().fadeIn(duration: 180.ms).slideY(
                              begin: 0.1,
                              end: 0,
                              duration: 200.ms,
                              curve: Curves.easeOut,
                            );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tab1Accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: AppColors.warmGray,
                disabledForegroundColor: Colors.white,
              ),
              onPressed: notifier.canContinueFromStep1
                  ? widget.onContinue
                  : null,
              child: const Text(
                'Continuar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectInput extends StatelessWidget {
  const _SubjectInput({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tab1Tint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.tab1Primary, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(
                hintText: 'Ej. Matemática',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          IconButton(
            onPressed: onSubmit,
            icon: const Icon(Icons.add_rounded),
            color: AppColors.tab1Accent,
            tooltip: 'Agregar',
          ),
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.name,
    required this.color,
    required this.onRemove,
  });

  final String name;
  final Color color;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.beige,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SubjectDot(color: color, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          InkResponse(
            onTap: onRemove,
            radius: 20,
            child: const Icon(
              Icons.close_rounded,
              size: 20,
              color: AppColors.graphiteSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Aún no has agregado ninguna materia',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.graphiteSoft,
            ),
      ),
    );
  }
}

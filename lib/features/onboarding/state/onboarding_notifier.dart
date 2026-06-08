import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../data/repositories/subject_repository_provider.dart';
import '../../../domain/entities/subject.dart';

import 'onboarding_state.dart';

final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void addSubject(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final duplicate = state.subjects.any(
      (s) => s.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) return;

    final colorValue = _nextColorValue(state.subjects);
    state = state.copyWith(
      subjects: [
        ...state.subjects,
        SubjectInput(name: trimmed, colorValue: colorValue),
      ],
    );
  }

  void removeAt(int index) {
    if (index < 0 || index >= state.subjects.length) return;
    final next = [...state.subjects]..removeAt(index);
    state = state.copyWith(subjects: next);
  }

  void setLiking(int index, int liking) {
    if (index < 0 || index >= state.subjects.length) return;
    if (liking < 1 || liking > 5) return;
    final next = [...state.subjects];
    next[index] = next[index].copyWith(liking: liking);
    state = state.copyWith(subjects: next);
  }

  bool get canContinueFromStep1 => state.subjects.isNotEmpty;
  bool get canFinish =>
      state.subjects.isNotEmpty && state.subjects.every((s) => s.liking >= 1);

  Future<void> persist() async {
    if (!canFinish || state.saving) return;
    state = state.copyWith(saving: true);
    try {
      await ref.read(subjectRepositoryProvider).insertMany(state.subjects);
    } catch (_) {
      state = state.copyWith(saving: false);
      rethrow;
    }
  }

  // Color asignado en orden: primer color de AppColors.subjects que aún no
  // esté en uso. Si todos están usados (más materias que colores), cicla.
  int _nextColorValue(List<SubjectInput> existing) {
    final used = existing.map((s) => s.colorValue).toSet();
    for (final c in AppColors.subjects) {
      final v = c.toARGB32();
      if (!used.contains(v)) return v;
    }
    return AppColors
        .subjects[existing.length % AppColors.subjects.length]
        .toARGB32();
  }
}

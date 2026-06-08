import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/entities/subject.dart';

part 'onboarding_state.freezed.dart';

@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(<SubjectInput>[]) List<SubjectInput> subjects,
    @Default(false) bool saving,
  }) = _OnboardingState;
}

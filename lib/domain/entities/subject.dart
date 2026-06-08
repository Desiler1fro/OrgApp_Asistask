import 'package:freezed_annotation/freezed_annotation.dart';

part 'subject.freezed.dart';

@freezed
class Subject with _$Subject {
  const factory Subject({
    required int id,
    required String name,
    required int colorValue,
    required int liking,
    required DateTime createdAt,
  }) = _Subject;
}

@freezed
class SubjectInput with _$SubjectInput {
  const factory SubjectInput({
    required String name,
    required int colorValue,
    @Default(0) int liking,
  }) = _SubjectInput;
}

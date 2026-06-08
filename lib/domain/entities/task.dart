import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';

@freezed
class Task with _$Task {
  const factory Task({
    required int id,
    required String name,
    required int subjectId,
    required DateTime dueDate,
    required int difficulty,
    required int estimatedMinutes,
    required DateTime createdAt,
    @Default(false) bool isCompleted,
    @Default(0) int workedMinutes,
  }) = _Task;
}

@freezed
class TaskInput with _$TaskInput {
  const factory TaskInput({
    required String name,
    required int subjectId,
    required DateTime dueDate,
    required int difficulty,
    required int estimatedMinutes,
  }) = _TaskInput;
}

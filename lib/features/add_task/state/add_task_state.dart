import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/entities/day_schedule.dart';

part 'add_task_state.freezed.dart';

enum AddTaskStep {
  askName,
  askSubject,
  askDueDate,
  askDifficulty,
  askDuration,
  askDiscardDays,
  askSchedules,
  celebrating,
}

enum PugMood { idle, happy, celebrate }

enum ChatSender { pug, user }

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required ChatSender sender,
    required String text,
  }) = _ChatMessage;
}

@freezed
class DraftSchedule with _$DraftSchedule {
  const factory DraftSchedule({
    required DateTime date,
    required int startMinutes,
    required int endMinutes,
  }) = _DraftSchedule;
}

@freezed
class AddTaskState with _$AddTaskState {
  const factory AddTaskState({
    @Default(<ChatMessage>[]) List<ChatMessage> messages,
    @Default(AddTaskStep.askName) AddTaskStep step,
    String? name,
    int? subjectId,
    DateTime? dueDate,
    int? difficulty,
    int? estimatedMinutes,
    @Default(<DateTime>[]) List<DateTime> discardedDates,
    @Default(<DraftSchedule>[]) List<DraftSchedule> schedules,
    @Default(0) int currentScheduleIndex,
    DaySchedule? currentPrefill,
    @Default(0) int currentMinStartMinutes,
    @Default(PugMood.idle) PugMood pugMood,
    @Default(false) bool saving,
    @Default(false) bool recentlySaved,
  }) = _AddTaskState;
}

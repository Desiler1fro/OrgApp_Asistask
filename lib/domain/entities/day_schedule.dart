import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_schedule.freezed.dart';

@freezed
class DaySchedule with _$DaySchedule {
  const factory DaySchedule({
    required int dayOfWeek,
    required int startMinutes,
    required int endMinutes,
  }) = _DaySchedule;
}

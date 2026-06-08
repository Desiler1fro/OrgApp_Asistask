import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_limit.freezed.dart';

/// Tope máximo de tareas a trabajar en una fecha concreta.
@freezed
class DayLimit with _$DayLimit {
  const factory DayLimit({
    required DateTime date,
    required int maxTasks,
  }) = _DayLimit;
}

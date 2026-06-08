import 'package:freezed_annotation/freezed_annotation.dart';

part 'availability_slot.freezed.dart';

@freezed
class AvailabilitySlot with _$AvailabilitySlot {
  const factory AvailabilitySlot({
    required int id,
    required int taskId,
    required DateTime date,
    required int startMinutes,
    required int endMinutes,
  }) = _AvailabilitySlot;
}

@freezed
class AvailabilitySlotInput with _$AvailabilitySlotInput {
  const factory AvailabilitySlotInput({
    required DateTime date,
    required int startMinutes,
    required int endMinutes,
  }) = _AvailabilitySlotInput;
}

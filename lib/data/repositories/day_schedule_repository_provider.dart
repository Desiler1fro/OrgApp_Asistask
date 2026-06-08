import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/day_schedule_repository.dart';
import '../database/database_provider.dart';
import 'day_schedule_repository_impl.dart';

final dayScheduleRepositoryProvider = Provider<DayScheduleRepository>((ref) {
  return DayScheduleRepositoryImpl(ref.watch(appDatabaseProvider));
});

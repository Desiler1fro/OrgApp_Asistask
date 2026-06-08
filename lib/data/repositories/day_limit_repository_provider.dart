import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/day_limit.dart';
import '../../domain/repositories/day_limit_repository.dart';
import '../database/database_provider.dart';
import 'day_limit_repository_impl.dart';

final dayLimitRepositoryProvider = Provider<DayLimitRepository>((ref) {
  return DayLimitRepositoryImpl(ref.watch(appDatabaseProvider));
});

final dayLimitsStreamProvider = StreamProvider<List<DayLimit>>((ref) {
  return ref.watch(dayLimitRepositoryProvider).watchAll();
});

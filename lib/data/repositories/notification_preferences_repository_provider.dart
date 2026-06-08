import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import 'notification_preferences_repository_impl.dart';

/// Provider override: se inicializa en main() después de cargar
/// SharedPreferences. Si se lee antes de inicializar, lanza.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  );
});

final notificationPreferencesRepositoryProvider =
    Provider<NotificationPreferencesRepository>((ref) {
  return NotificationPreferencesRepositoryImpl(
    ref.watch(sharedPreferencesProvider),
  );
});

final notificationPreferencesStreamProvider =
    StreamProvider<NotificationPreferences>((ref) {
  return ref.watch(notificationPreferencesRepositoryProvider).watch();
});

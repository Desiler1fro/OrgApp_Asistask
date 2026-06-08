import '../entities/notification_preferences.dart';

/// Persistencia de las preferencias de notificaciones del usuario.
abstract class NotificationPreferencesRepository {
  Future<NotificationPreferences> load();
  Future<void> save(NotificationPreferences prefs);
  Stream<NotificationPreferences> watch();
}

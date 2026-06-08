import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final plugin = FlutterLocalNotificationsPlugin();
  final service = NotificationService(plugin);
  // La inicialización real (tz + plugin.initialize) ocurre en main();
  // este provider solo expone la instancia singleton.
  return service;
});

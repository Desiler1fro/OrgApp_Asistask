import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/repositories/notification_preferences_repository_provider.dart';
import 'data/services/notification_service.dart';
import 'data/services/notification_service_provider.dart';

const _kPermissionAskedKey = 'notif.permissionAsked.v1';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  final prefs = await SharedPreferences.getInstance();

  final plugin = FlutterLocalNotificationsPlugin();
  final notifService = NotificationService(plugin);
  await notifService.init();

  // Pedir permiso solo una vez (Android 13+). Si el usuario lo deniega,
  // puede volver a otorgarlo desde la pantalla Notificaciones.
  if (!(prefs.getBool(_kPermissionAskedKey) ?? false)) {
    await notifService.requestPermissions();
    await prefs.setBool(_kPermissionAskedKey, true);
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notifService),
      ],
      child: const OrgApp(),
    ),
  );
}

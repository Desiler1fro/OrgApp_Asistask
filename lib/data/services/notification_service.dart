import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Tipos de notificación soportados. Cada tipo se mapea a un canal
/// Android dedicado y a un rango propio de IDs para poder cancelarlos
/// independientemente.
enum NotificationKind { deadline, workBlock, critical }

/// Servicio wrapper sobre `flutter_local_notifications`.
///
/// Responsabilidades:
/// - Inicializar el plugin y la base de zonas horarias.
/// - Pedir permiso de notificaciones (Android 13+ POST_NOTIFICATIONS).
/// - Programar / cancelar notificaciones por tipo (deadline, bloque de
///   trabajo, urgencia crítica).
///
/// El servicio NO decide qué programar: eso lo hace el
/// `NotificationScheduler` del dominio combinando tareas + preferencias.
class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  // Particionado de IDs: cada tipo vive en un bloque de 100M. Permite
  // identificar a qué tipo pertenece un pendingNotificationRequest sin
  // mantener un mapeo externo persistido.
  static const int _deadlineBase = 100000000;
  static const int _workBlockBase = 200000000;
  static const int _criticalBase = 300000000;
  static const int _bucketSize = 100000000;

  // ────────────────────────────────────────────────────────────────
  // Inicialización
  // ────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Si por alguna razón no se puede detectar, queda en UTC. Las
      // notificaciones aún se disparan, solo que con desfase posible.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _initialized = true;
  }

  /// Pide los permisos necesarios. En Android 13+ requiere
  /// POST_NOTIFICATIONS. Devuelve `true` si quedaron concedidos.
  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await android?.requestNotificationsPermission() ?? true;
      return granted;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;
    return granted;
  }

  Future<bool> areNotificationsEnabled() async {
    if (!Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }

  // ────────────────────────────────────────────────────────────────
  // Programación
  // ────────────────────────────────────────────────────────────────

  Future<void> scheduleDeadline({
    required int taskId,
    required String taskName,
    required DateTime fireAt,
  }) async {
    await _scheduleAt(
      id: _deadlineBase + taskId,
      kind: NotificationKind.deadline,
      title: '⏰ Mañana vence: $taskName',
      body: 'Recuerda entregar tu tarea a tiempo.',
      fireAt: fireAt,
    );
  }

  Future<void> scheduleWorkBlock({
    required int taskId,
    required int blockIndex,
    required String taskName,
    required DateTime fireAt,
    required String hourRange,
  }) async {
    await _scheduleAt(
      id: _workBlockBase + (taskId * 1000) + blockIndex,
      kind: NotificationKind.workBlock,
      title: '📚 Es hora de trabajar en: $taskName',
      body: hourRange,
      fireAt: fireAt,
    );
  }

  Future<void> scheduleCritical({
    required int taskId,
    required String taskName,
    required DateTime fireAt,
  }) async {
    await _scheduleAt(
      id: _criticalBase + taskId,
      kind: NotificationKind.critical,
      title: '⚠️ $taskName vence pronto',
      body: '¡No la dejes para después!',
      fireAt: fireAt,
    );
  }

  Future<void> _scheduleAt({
    required int id,
    required NotificationKind kind,
    required String title,
    required String body,
    required DateTime fireAt,
  }) async {
    final scheduled = tz.TZDateTime.from(fireAt, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!scheduled.isAfter(now)) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _detailsFor(kind),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Cancelación
  // ────────────────────────────────────────────────────────────────

  Future<void> cancelAllOfType(NotificationKind kind) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final req in pending) {
      if (_kindOf(req.id) == kind) {
        await _plugin.cancel(req.id);
      }
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> pendingRequests() {
    return _plugin.pendingNotificationRequests();
  }

  // ────────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────────

  NotificationKind? _kindOf(int id) {
    if (id >= _deadlineBase && id < _deadlineBase + _bucketSize) {
      return NotificationKind.deadline;
    }
    if (id >= _workBlockBase && id < _workBlockBase + _bucketSize) {
      return NotificationKind.workBlock;
    }
    if (id >= _criticalBase && id < _criticalBase + _bucketSize) {
      return NotificationKind.critical;
    }
    return null;
  }

  NotificationDetails _detailsFor(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.deadline:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'asistask_deadline',
            'Deadlines',
            channelDescription: 'Aviso 24 h antes del vencimiento de una tarea.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        );
      case NotificationKind.workBlock:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'asistask_work_block',
            'Bloques de trabajo',
            channelDescription:
                'Recordatorio 15 min antes de un bloque programado.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        );
      case NotificationKind.critical:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'asistask_critical',
            'Urgencia crítica',
            channelDescription:
                'Aviso cuando una tarea queda con muy poco margen.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        );
    }
  }
}

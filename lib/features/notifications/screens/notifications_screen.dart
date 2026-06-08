import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../data/repositories/notification_preferences_repository_provider.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/notification_service_provider.dart';
import '../../../domain/entities/notification_preferences.dart';

/// Configuración de los tres tipos de notificaciones locales.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _checkingPermission = true;
  bool _systemEnabled = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final service = ref.read(notificationServiceProvider);
    final ok = await service.areNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _systemEnabled = ok;
      _checkingPermission = false;
    });
  }

  Future<void> _requestPermission() async {
    final service = ref.read(notificationServiceProvider);
    await service.requestPermissions();
    await _checkPermission();
  }

  Future<void> _update({
    bool? deadline,
    bool? workBlock,
    bool? critical,
  }) async {
    final repo = ref.read(notificationPreferencesRepositoryProvider);
    final current = await repo.load();
    final next = current.copyWith(
      deadlineEnabled: deadline,
      workBlockEnabled: workBlock,
      criticalEnabled: critical,
    );
    await repo.save(next);

    // Cancelar las pendientes del tipo que se acaba de desactivar.
    final service = ref.read(notificationServiceProvider);
    if (deadline == false) {
      await service.cancelAllOfType(NotificationKind.deadline);
    }
    if (workBlock == false) {
      await service.cancelAllOfType(NotificationKind.workBlock);
    }
    if (critical == false) {
      await service.cancelAllOfType(NotificationKind.critical);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(notificationPreferencesStreamProvider);
    final prefs =
        prefsAsync.valueOrNull ?? NotificationPreferences.defaults;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.graphite,
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (!_checkingPermission && !_systemEnabled)
            _PermissionBanner(onTap: _requestPermission),
          const SizedBox(height: 8),
          _ToggleTile(
            icon: Icons.event_busy_rounded,
            title: 'Deadline próximo',
            description:
                'Aviso 24 h antes de que venza una tarea (a las 9 de la mañana).',
            value: prefs.deadlineEnabled,
            onChanged: (v) => _update(deadline: v),
          ),
          const SizedBox(height: 8),
          _ToggleTile(
            icon: Icons.menu_book_rounded,
            title: 'Bloque de trabajo',
            description:
                'Recordatorio 15 min antes de cada bloque programado del día.',
            value: prefs.workBlockEnabled,
            onChanged: (v) => _update(workBlock: v),
          ),
          const SizedBox(height: 8),
          _ToggleTile(
            icon: Icons.warning_amber_rounded,
            title: 'Urgencia crítica',
            description:
                'Cuando una tarea queda con 2 días o menos de margen disponible.',
            value: prefs.criticalEnabled,
            onChanged: (v) => _update(critical: v),
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.beige,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: AppColors.tab3Accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.graphiteSoft,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.tab3Accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.tab1Tint,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              const Icon(
                Icons.notifications_off_rounded,
                color: AppColors.tab1Accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notificaciones desactivadas en el sistema',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.graphite,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Toca para volver a otorgar el permiso. Si está '
                      'bloqueado, habilítalo desde Ajustes del sistema.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.graphiteSoft,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

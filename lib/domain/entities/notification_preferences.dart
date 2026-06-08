/// Preferencias del sistema de notificaciones locales.
///
/// Tres toggles independientes: si uno se desactiva, las notificaciones
/// pendientes de ese tipo deben cancelarse y no se programan nuevas hasta
/// que se reactive.
class NotificationPreferences {
  const NotificationPreferences({
    this.deadlineEnabled = true,
    this.workBlockEnabled = true,
    this.criticalEnabled = true,
  });

  final bool deadlineEnabled;
  final bool workBlockEnabled;
  final bool criticalEnabled;

  static const defaults = NotificationPreferences();

  NotificationPreferences copyWith({
    bool? deadlineEnabled,
    bool? workBlockEnabled,
    bool? criticalEnabled,
  }) {
    return NotificationPreferences(
      deadlineEnabled: deadlineEnabled ?? this.deadlineEnabled,
      workBlockEnabled: workBlockEnabled ?? this.workBlockEnabled,
      criticalEnabled: criticalEnabled ?? this.criticalEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPreferences &&
          deadlineEnabled == other.deadlineEnabled &&
          workBlockEnabled == other.workBlockEnabled &&
          criticalEnabled == other.criticalEnabled;

  @override
  int get hashCode => Object.hash(
        deadlineEnabled,
        workBlockEnabled,
        criticalEnabled,
      );
}

/// Tipo de notificación que se va a programar.
enum NotificationRequestKind { deadline, workBlock, critical }

/// Una solicitud de notificación a programar. El dominio decide qué
/// crear; la capa de datos (NotificationService) la lleva al plugin.
class NotificationRequest {
  const NotificationRequest({
    required this.kind,
    required this.taskId,
    required this.taskName,
    required this.fireAt,
    this.blockIndex,
    this.hourRange,
  });

  final NotificationRequestKind kind;
  final int taskId;
  final String taskName;
  final DateTime fireAt;

  /// Solo para `NotificationRequestKind.workBlock`: índice del bloque
  /// dentro del schedule de la tarea (estabiliza el ID).
  final int? blockIndex;

  /// Solo para `workBlock`: cuerpo del mensaje con el rango horario,
  /// p.ej. "14:00–15:30".
  final String? hourRange;
}

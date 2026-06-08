/// Pesos y constantes de calibración del algoritmo de predicción.
///
/// Cada factor produce un score normalizado en 0..1. El score final es
/// la suma ponderada de los cinco factores, también en 0..1. Las tareas
/// con prioridad "hoy" (dueDate == hoy o slot asignado para hoy) se
/// ordenan SIEMPRE arriba del resto antes de comparar por score.
///
/// Los valores aquí son los únicos puntos de ajuste del algoritmo. Si se
/// quiere recalibrar, se modifican estas constantes — el resto de la
/// lógica permanece intacto.
class PredictionWeights {
  const PredictionWeights._();

  // ── Pesos del score (deben sumar 1.0) ─────────────────────────────
  static const double urgency = 0.35;
  static const double difficulty = 0.25;
  static const double duration = 0.20;
  static const double availability = 0.10;
  static const double liking = 0.10;

  // ── Anclas de normalización ───────────────────────────────────────

  /// Horizonte máximo para la urgencia. Una tarea con `maxDaysHorizon` o
  /// más días disponibles recibe urgency = 0. Con 1 día → urgency = 1.
  static const int maxDaysHorizon = 30;

  /// Duración estimada considerada "máxima" para la normalización. Una
  /// tarea con `>= maxDurationMinutes` recibe duration = 1.0.
  /// 10 h ≈ trabajo intenso prolongado.
  static const int maxDurationMinutes = 600;

  /// Disponibilidad horaria diaria considerada "amplia". Si el promedio
  /// por día activo es >= este valor, availability = 0 (sin urgencia
  /// horaria). 12 h ≈ día casi completamente libre.
  static const int maxDailyAvailabilityMinutes = 12 * 60;

  /// Duración mínima de una tarea (paso de 30 min, coincide con la
  /// granularidad del onboarding). Define el piso de la normalización
  /// de duration.
  static const int minDurationMinutes = 30;

  /// Días disponibles a partir de los cuales una tarea se considera
  /// "crítica" y se ancla al tope del listado (por encima del ranking
  /// por score), justo después de las tareas para hoy. Garantiza que las
  /// tareas con muy poco margen siempre suban, sin importar que otros
  /// factores las desplacen.
  static const int criticalDaysThreshold = 2;
}

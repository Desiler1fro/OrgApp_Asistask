import '../prediction_weights.dart';

/// Score de disponibilidad horaria en 0..1. MENOS tiempo disponible →
/// score MAYOR (las tareas con poco margen horario suben).
///
/// Recibe el promedio de minutos disponibles por día activo (suma de
/// minutos de slots / número de días con slot). Si una tarea no tiene
/// slots asignados, se considera disponibilidad nula → score 1.0.
double availabilityScore({required int averageDailyAvailableMinutes}) {
  if (averageDailyAvailableMinutes <= 0) return 1.0;
  const ceil = PredictionWeights.maxDailyAvailabilityMinutes;
  if (averageDailyAvailableMinutes >= ceil) return 0.0;
  return 1.0 - (averageDailyAvailableMinutes / ceil);
}

import '../prediction_weights.dart';

/// Score de urgencia en 0..1. Menos días disponibles → score mayor.
///
/// `daysAvailable` es la cantidad de días no descartados entre hoy y la
/// fecha de entrega (inclusive). Si la tarea tiene 1 día disponible, el
/// score es 1.0. Si tiene `maxDaysHorizon` o más, es 0.
double urgencyScore({required int daysAvailable}) {
  if (daysAvailable <= 1) return 1.0;
  const horizon = PredictionWeights.maxDaysHorizon;
  if (daysAvailable >= horizon) return 0.0;
  return 1.0 - ((daysAvailable - 1) / (horizon - 1));
}

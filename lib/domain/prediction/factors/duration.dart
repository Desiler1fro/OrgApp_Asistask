import '../prediction_weights.dart';

/// Score de duración estimada en 0..1. Tareas más largas → score mayor.
///
/// Se interpola linealmente entre `minDurationMinutes` (=0) y
/// `maxDurationMinutes` (=1). Por encima del techo se satura en 1.
double durationScore(int estimatedMinutes) {
  const floor = PredictionWeights.minDurationMinutes;
  const ceil = PredictionWeights.maxDurationMinutes;
  if (estimatedMinutes <= floor) return 0.0;
  if (estimatedMinutes >= ceil) return 1.0;
  return (estimatedMinutes - floor) / (ceil - floor);
}

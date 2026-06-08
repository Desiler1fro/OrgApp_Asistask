/// Barrel de los cinco factores normalizados que alimentan al Ranker.
///
/// Cada factor produce un valor en 0..1. El Ranker los combina con los
/// pesos definidos en `prediction_weights.dart`. Mantener cada cálculo
/// en su propio archivo permite testearlos por separado y reajustar la
/// fórmula sin tocar el Ranker.
library;

export 'availability.dart';
export 'difficulty.dart';
export 'duration.dart';
export 'liking.dart';
export 'urgency.dart';

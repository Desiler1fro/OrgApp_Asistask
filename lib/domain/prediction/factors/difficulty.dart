/// Score de dificultad en 0..1 a partir de la escala 1..5 declarada por
/// el usuario. Más difícil → score mayor (se ataca primero).
double difficultyScore(int difficulty) {
  final clamped = difficulty.clamp(1, 5);
  return (clamped - 1) / 4.0;
}

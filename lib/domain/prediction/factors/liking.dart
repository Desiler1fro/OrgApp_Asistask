/// Score de gusto por la materia en 0..1 a partir de la escala 1..5.
/// Más gusto → score mayor (las favoritas se priorizan como incentivo).
double likingScore(int liking) {
  final clamped = liking.clamp(1, 5);
  return (clamped - 1) / 4.0;
}

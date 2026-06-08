import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // ── Neutros (UI base) ─────────────────────────────────────────────
  static const Color cream = Color(0xFFFAF6EE);
  static const Color beige = Color(0xFFF1E7D3);
  static const Color warmGray = Color(0xFFDDD4C5);
  static const Color graphite = Color(0xFF3A3530);
  static const Color graphiteSoft = Color(0xFF6E6862);

  // ── Pestaña 1 · Agregar tarea (rosa) ──────────────────────────────
  static const Color tab1Primary = Color(0xFFF7C6D4);
  static const Color tab1Accent = Color(0xFFE89BAE);
  static const Color tab1Tint = Color(0xFFFCEAEF);

  // ── Pestaña 2 · Listado ordenado (sage) ───────────────────────────
  static const Color tab2Primary = Color(0xFFA8B89E);
  static const Color tab2Accent = Color(0xFF7C8B6E);
  static const Color tab2Tint = Color(0xFFECEFE3);

  // ── Pestaña 3 · Calendario (azul) ─────────────────────────────────
  static const Color tab3Primary = Color(0xFFB5D2E5);
  static const Color tab3Accent = Color(0xFF7BAACB);
  static const Color tab3Tint = Color(0xFFEAF1F7);

  // ── Funcionales del calendario ────────────────────────────────────
  // Compartido a propósito con tab3Accent: el día programado debe leerse
  // como "del mismo lenguaje" que la pestaña de calendario.
  static const Color calendarScheduled = tab3Accent;
  static const Color calendarDeadline = Color(0xFFD77AA1);

  // ── Materias ──────────────────────────────────────────────────────
  // No incluye rosa/sage/azul de pestañas ni el fucsia de entrega:
  // esos colores tienen rol semántico fijo en el resto de la UI.
  static const List<Color> subjects = [
    Color(0xFFBFDBC1), // menta
    Color(0xFFF5B58A), // melón
    Color(0xFFF3DC9A), // amarillo mantequilla
    Color(0xFFC7B8DC), // lavanda
    Color(0xFF9FCFD0), // turquesa
    Color(0xFFE8A695), // coral
    Color(0xFFD8B8DC), // lila polvo
    Color(0xFFFFD6A5), // durazno
    Color(0xFFB5EAD7), // verde agua
    Color(0xFFFFDAC1), // salmón suave
    Color(0xFFD4E8C2), // lima pastel
    Color(0xFFC9E4F5), // celeste
  ];
}

// Barrel file de las interfaces de repositorios.
//
// Aquí se declaran las interfaces abstractas (TaskRepository,
// SubjectRepository, etc.). Las implementaciones concretas viven en
// lib/data/repositories/ y dependen de Drift.
//
// Esta separación permite testear el algoritmo de predicción
// inyectando repositorios falsos sin tocar la base de datos real.

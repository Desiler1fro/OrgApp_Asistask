// Barrel file de las entidades de dominio.
//
// Las entidades concretas (Task, Subject, AvailabilitySlot) se definirán
// con Freezed cuando se implementen las features que las consumen.
//
// Convención:
// - Inmutables, sin dependencias de Flutter ni de Drift.
// - Solo describen el modelo conceptual del dominio.
// - La capa data/ mapea entre estas entidades y las tablas de Drift.

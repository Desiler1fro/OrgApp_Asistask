# CLAUDE.md — orgApp_Pau

## Visión del proyecto

App móvil organizadora de tareas escolares con **predicción inteligente del orden de ejecución**. No es un to-do list simple: el sistema decide y sugiere el orden óptimo en que el usuario debe realizar sus tareas, basándose en múltiples factores ponderados, y distribuye cada tarea en bloques horarios reales según la disponibilidad del usuario.

---

## Stack tecnológico

| Capa | Elección | Razón |
|---|---|---|
| Framework | **Flutter** (Dart) | Decisión del proyecto |
| Estado | **Riverpod 2.x** (providers manuales) | `riverpod_generator` removido — conflicto irresolvible entre `analyzer_plugin 0.12` y `analyzer 7.x` requerido por Freezed 2.x |
| Persistencia | **Drift (SQLite)** local | Datos relacionales (Subject→Task→Slot), queries reactivas vía Streams, type-safe, sin necesidad de backend remoto |
| Routing | **go_router** | Oficial Flutter, deep-linking, integra con Riverpod |
| Modelos | **Freezed** + `json_serializable` | Inmutables, `copyWith`, igualdad estructural |
| Calendario UI | **table_calendar** | Estándar de la comunidad para vistas mensuales |
| Animaciones | **flutter_animate** | API declarativa, ideal para microinteracciones |
| Tipografía | **google_fonts** — **Manrope** | Redondeada, amigable, confirmada |

---

## Factores de predicción (por tarea)

| Prioridad | Factor | Lógica |
|---|---|---|
| 1 (mayor) | **Urgencia** (fecha de entrega) | Se calcula sobre los días disponibles entre hoy y el deadline. A menor número de días disponibles → mayor prioridad. |
| 2 | **Dificultad** | Escala 1–5. A mayor dificultad → mayor prioridad. Las tareas difíciles se atacan primero. |
| 3 | **Tiempo estimado** | En incrementos de 30 min. A mayor tiempo requerido → mayor prioridad. Las tareas largas necesitan más días. |
| 4 | **Disponibilidad horaria** | Franjas declaradas por día (ej. "14:00–19:30"). A menor tiempo disponible total → mayor prioridad. |
| 5 (menor) | **Gusto por la materia** | Escala 1–5 (onboarding). A mayor gusto → mayor prioridad. Las favoritas van primero como incentivo. |

**Caso especial — tarea para hoy:** si la fecha de entrega es hoy, o el usuario marca como disponible el día actual, la tarea recibe prioridad inmediata al tope del orden y se acomoda en las horas restantes del día.

**Pesos:** La fórmula exacta de ponderación y normalización la define Claude al implementar `domain/prediction/`. Los pesos deben ser **constantes configurables** (no hardcodeadas en la lógica) para poder ajustar sin tocar la UI.

### Descarte de días

Al crear una tarea, el sistema muestra todos los días entre hoy y el deadline. El usuario puede **descartar** cualquiera de esos días — los días descartados no reciben horas de trabajo ni participan en la distribución de la tarea. Solo los días no descartados entran en la planificación.

### Memoria de disponibilidad horaria

El sistema recuerda el horario declarado para cada día específico (ej. "lunes 14:00–19:30"). Si una tarea posterior incluye ese mismo día, el horario se **pre-rellena automáticamente**. El usuario puede modificarlo para esa tarea en particular, pero no tiene que ingresarlo desde cero. Esta memoria se construye progresivamente conforme se agregan tareas — no en el onboarding.

---

## Estructura de la app (3 pestañas)

### 1. Agregar tarea
Flujo secuencial:
1. Nombre, materia, fecha de entrega, dificultad (1–5), tiempo estimado (pasos de 30 min).
2. Una vez ingresada la fecha de entrega, el sistema muestra los días entre hoy y el deadline. El usuario puede **descartar** días en los que no trabajará.
3. Para cada día no descartado, el sistema muestra el horario pre-rellenado (si ya fue declarado antes) o pide ingresarlo. El usuario puede modificarlo para esta tarea.

La disponibilidad es por tarea. No hay base semanal global — la memoria se acumula uso a uso.

### 2. Listado ordenado
- Tareas en el orden sugerido por el sistema
- Cada ítem expandible: materia, rango horario asignado, día máximo
- Editar parámetros recomputa el orden en tiempo real (Riverpod reactiva el `Provider` que recalcula el ranking)

### 3. Calendario visual
- Días con tarea programada → **azul** (`AppColors.calendarScheduled = tab3Accent`)
- Días de entrega → **fucsia** (`AppColors.calendarDeadline`)
- Un día puede tener ambos marcadores (dos dots)
- Tap en día → lista de eventos del día (bloques de trabajo + entregas)

---

## Configuración inicial (onboarding)

- Registrar materias que cursa
- Gusto por cada materia (1–5)

No hay configuración de disponibilidad horaria en el onboarding. La memoria de horarios por día se construye progresivamente conforme el usuario agrega tareas.

---

## Estructura de carpetas

```
orgApp_Pau/
├── lib/
│   ├── main.dart                    # Entry point + ProviderScope
│   ├── app/
│   │   ├── app.dart                 # MaterialApp.router root
│   │   ├── theme/                   # Tema, colores, tipografía
│   │   └── router/                  # go_router config
│   ├── core/                        # Utilidades sin lógica de negocio
│   │   ├── extensions/
│   │   ├── utils/
│   │   └── widgets/                 # Componentes UI reusables
│   ├── data/                        # Capa de datos (implementación)
│   │   ├── database/
│   │   │   ├── app_database.dart
│   │   │   ├── tables/              # Drift tables
│   │   │   └── daos/                # Data Access Objects
│   │   └── repositories/            # Implementaciones concretas
│   ├── domain/                      # Lógica pura, sin Flutter ni Drift
│   │   ├── entities/                # Task, Subject, AvailabilitySlot (Freezed)
│   │   ├── repositories/            # Interfaces abstractas
│   │   └── prediction/              # 🧠 Algoritmo de predicción
│   │       ├── factors/             # Cálculo por factor
│   │       ├── scheduler.dart       # Distribuye en bloques horarios
│   │       └── ranker.dart          # Calcula orden final
│   ├── features/                    # Pantallas y flujos
│   │   ├── shell/                   # Bottom navigation scaffold + menú ⋮
│   │   ├── onboarding/
│   │   ├── add_task/                # Pestaña 1
│   │   ├── manage_subjects/         # Gestión de materias (ruta /manage-subjects)
│   │   ├── task_list/               # Pestaña 2
│   │   └── calendar/                # Pestaña 3
│   └── l10n/                        # i18n (español)
├── test/
│   ├── domain/prediction/           # Tests del algoritmo (críticos)
│   ├── data/
│   └── features/
├── assets/{icons,images}/
├── pubspec.yaml
├── analysis_options.yaml
└── CLAUDE.md
```

### Decisiones clave de arquitectura

1. **`domain/` no depende de Flutter ni Drift** → algoritmo testeable en Dart puro
2. **`data/` implementa interfaces de `domain/repositories/`** → permite mockear DB en tests
3. **Feature-first dentro de `features/`** → cada pantalla es autónoma en UI/providers
4. **Cosas compartidas (algoritmo, modelos, DB) viven fuera de `features/`** → evita acoplamiento entre pestañas

---

## Convenciones

- **Idioma del código**: inglés (variables, funciones, comentarios)
- **Idioma de la UI**: español latino mexicano estándar, tuteo, sin voseo ni regionalismos ajenos al español mexicano
- **Commits**: en español, descriptivos del cambio funcional
- **Modelos inmutables con Freezed** — nunca mutar campos directamente
- **Archivos generados (`.g.dart`, `.freezed.dart`)** ignorados en git y excluidos del analyzer
- **No hardcodear pesos del algoritmo** — deben ser configurables (constantes o provider) para ajustar sin tocar UI
- **La lógica de predicción vive en `lib/domain/prediction/`** — separada estrictamente de la UI
- **Single quotes** en strings Dart; **trailing commas** obligatorias

### Comandos típicos

```bash
flutter pub get                          # Instalar deps
dart run build_runner build              # Generar Freezed + Drift (no Riverpod codegen)
dart run build_runner watch              # Modo watch durante desarrollo
flutter test                             # Correr todos los tests
flutter test test/domain/prediction/     # Solo tests del algoritmo
flutter analyze                          # Analizador estático
flutter run                              # Build + deploy al dispositivo conectado
```

> **Nota entorno WSL2:** JDK nativo Linux requerido. Configurado en `~/.local/java/jdk-21.0.11+10` vía `flutter config --jdk-dir`. El JBR de Android Studio (Windows) no funciona desde WSL porque los paths Linux no son válidos para la JVM Windows.

---

## Estado actual del proyecto (2026-06-07)

### Implementado y verificado en dispositivo físico ✅
- **Sistema de diseño completo** (`lib/app/theme/`): paleta, tipografía Manrope, ThemeData Material 3. `AppColors.subjects` tiene 12 colores pastel sin duplicados.
- **Entidades** con Freezed: `Subject`, `Task` (con `isCompleted`, `workedMinutes`), `AvailabilitySlot`, `DaySchedule`, `DayLimit`
- **Tablas Drift v5** `subjects`, `tasks`, `availability_slots`, `day_schedules`, `day_limits` + DAOs; migraciones v2→v3 (isCompleted), v3→v4 (workedMinutes), v4→v5 (day_limits)
- **Repositorios** Subject, Task (`create`, `updateFields`, `updateWorkedMinutes`, `markCompleted`, `deleteById`), DaySchedule, DayLimit (watchAll, setLimit, removeLimit)
- **Onboarding completo** (2 pasos: registrar materias con color auto-asignado + asignar gusto 1–5), gate en router
- **Pestaña 1 — Agregar tarea**: chatbot estilo conversacional con mascota pug PNG
  - 7 preguntas secuenciales (nombre, materia, deadline, dificultad, duración, días a descartar, horario por día)
  - Dificultad: círculos con número (1–5) visible dentro; seleccionado = blanco sobre color, sin seleccionar = número en graphiteSoft
  - Hora de fin del selector: libre (sin redondeo a 30 min); hora de inicio sigue redondeándose
  - Memoria de disponibilidad horaria por dayOfWeek: prefill dinámico desde la **moda de tareas activas** (no completadas, no vencidas); si no hay, cae al respaldo en tabla `day_schedules` (política last-wins)
  - Si el día a configurar es hoy: inicio mínimo = hora actual redondeada al siguiente bloque de 30 min; si quedan < 30 min el día se descarta automáticamente con aviso del pug
  - Pug PNG (`pug_idle.png`, `pug_happy.png`, `pug_celebrate.png`) con fondo transparente; fondo PNG (`background.png`) con `BoxFit.cover`
  - Distribución visual: pug fijo en tercio inferior (altura dinámica `screenHeight / 3`), mensajes scrollean en los dos tercios superiores
  - Estado happy al confirmar cada respuesta: 1.5 s → idle automático; celebrate solo al guardar
  - Persistencia transaccional + snackbar + reset automático
- **Gestión de materias** (`features/manage_subjects/`, ruta `/manage-subjects`): accesible desde menú ⋮ en MainShell
  - Agregar, cambiar color (bottom sheet), eliminar (diálogo si tiene tareas, FK cascade)
- **Pestaña 2 — Listado ordenado** (`features/task_list/`): completa
  - **Algoritmo de predicción** en `lib/domain/prediction/`:
    - `prediction_weights.dart`: pesos configurables (urgencia 35%, dificultad 25%, tiempo 20%, disponibilidad 10%, gusto 10%) + anclas de normalización
    - 5 factores normalizados 0–1 en `factors/` (urgency, difficulty, duration, availability, liking)
    - `Ranker`: ordena por **isForToday → isCritical (≤2 días disponibles) → score desc → dueDate asc → id asc**; cuenta solo días presentes/futuros. `criticalDaysThreshold = 2` en `prediction_weights.dart`
    - `Scheduler`: asignación global con pool compartido (`reservations = Map<DateTime, List<_Interval>>`); procesa tareas en orden del Ranker; sin solapamientos entre tareas; recorta día actual a hora presente; respeta `workedMinutes` (planifica solo el restante); respeta `maxTasksByDay` (tope por fecha)
    - `TaskSchedule.isComplete=false` → chip ámbar "No alcanza el tiempo" en tarjeta colapsada
  - Tareas activas: tarjetas expandibles con badge de rango, color de materia, chip de próximo bloque y chip de entrega; detalle expandido con dificultad (dots con número), duración, días disponibles, lista de bloques, botones Editar / Eliminar / Realizada
  - **Botón "Realizada"**: marca `isCompleted=true`; la tarea pasa al historial con badge verde "Realizada" (distinto de badge fucsia "Vencida")
  - **Progreso parcial**: check "Hecho" por bloque suma su duración a `workedMinutes` (acumulado persistido, check visual recalculado); barra de progreso "Trabajado X / Y"; al alcanzar el estimado prompt "¿Marcar realizada?" con undo snackbar
  - **Editar tarea** (`EditTaskSheet`): dificultad (1–5), duración (±30 min), `workedMinutes` editable (stepper ±30, clamp 0–estimado); pickers de hora inicio/fin por slot. Transaccional, reemplaza slots.
  - **Eliminar tarea**: diálogo confirmación, FK cascade limpia slots. Reactivo automático.
  - **Historial de tareas completadas**: sección colapsada al final, badge verde "Realizada". Solo eliminar.
  - **Historial de tareas vencidas**: sección colapsada al final, badge fucsia "Vencida", opacidad 0.55. Solo eliminar. Las vencidas NO entran al Ranker.
  - Providers reactivos: `rankedTasksProvider` + `completedTasksProvider` + `overdueTasksProvider`
- **Tope de tareas por día** (`features/day_limits/`, ruta `/day-limits`, menú ⋮ "Tope por día"):
  - Lista de topes por fecha, agregar/editar (stepper 1–10, default 2), eliminar
  - ⚠️ Implementado y compilado — pendiente validación visual en dispositivo físico
- **Pestaña 3 — Calendario** (`features/calendar/screens/calendar_screen.dart`): completa ✅
  - `TableCalendar` mensual, locale `es`, semana inicia lunes
  - Markers: dot azul (`calendarScheduled`) = bloques de trabajo; dot fucsia (`calendarDeadline`) = fecha de entrega; coexisten si aplica
  - Día seleccionado (default: hoy) → lista de eventos debajo con `AnimatedSwitcher` (fade + slide 220 ms)
  - Tarjetas de evento: strip lateral de color del tipo, dot de materia, badge "Trabajo"/"Entrega", rango horario si es bloque
  - Datos de `rankedTasksProvider` (sin provider nuevo); tareas completadas y vencidas no aparecen
- **Shell**: PageView + `_KeepAlive` (AutomaticKeepAliveClientMixin) + swipe horizontal entre pestañas sincronizado con BottomNavigationBar; menú ⋮ overlay (gestionar materias, tope por día)
- **Localización ES** inicializada en main.dart
- **Tests**: `test/domain/prediction/` con 16 tests en verde (Scheduler: 13, Ranker: 3)
- **Ícono y nombre de app**: `assets/images/app_icon.png` generado con `flutter_launcher_icons` (fondo adaptativo rosa `#F7C6D4`, `remove_alpha_ios: true`); nombre **AsisTask** en Android y iOS
- **Repositorio GitHub**: público en `https://github.com/Desiler1fro/OrgApp_Asistask`
- **Build Android exitoso**: `flutter analyze` sin issues, probado en dispositivo físico

### Pendientes

1. **Validar `/day-limits` en dispositivo físico** — flujo completo: agregar, editar, eliminar tope.
2. **Ajustes de uso real** — posibles correcciones visuales o de lógica que surjan de la experiencia en dispositivo.

---

## Decisiones pendientes

- [ ] **Estrategia de notificaciones/recordatorios**
- [ ] **Manejo de tareas recurrentes** (si aplica)
- [ ] **Sync multi-dispositivo** — postergada; si se requiere, sumar Supabase sobre la base local sin reescribir el modelo

### Ya decidido (no volver a abrir sin razón fuerte)

- ✅ Stack: Flutter
- ✅ Estado: Riverpod 2.x (providers manuales — sin codegen)
- ✅ Persistencia: Drift local (sin backend remoto en v1)
- ✅ Routing: go_router
- ✅ Modelos: Freezed
- ✅ Estructura: feature-first con capas domain/data
- ✅ Tipografía: Manrope (google_fonts)
- ✅ Sistema de diseño visual: paleta completa implementada en `app_colors.dart`
- ✅ Algoritmo de predicción: 5 factores con orden de prioridad definido (urgencia > dificultad > tiempo estimado > disponibilidad > gusto). Fórmula exacta la define Claude al implementar; pesos como constantes configurables.
- ✅ Descarte de días: el usuario puede descartar días al crear una tarea; los descartados no participan en la planificación.
- ✅ Memoria de disponibilidad horaria: el sistema pre-rellena horarios ya conocidos por día; se construye progresivamente, no en onboarding.

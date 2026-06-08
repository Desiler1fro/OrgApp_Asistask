# AsisTask

Organizador de tareas escolares con prediccion inteligente del orden de ejecucion.

## Que es AsisTask

AsisTask es una aplicacion movil disenada para estudiantes que necesitan gestionar multiples tareas y entregas sin invertir tiempo en planificar manualmente que hacer primero. En lugar de mostrar una lista generica ordenada por fecha, la app analiza cada tarea segun varios factores y decide automaticamente el orden optimo en que conviene trabajarlas. Ademas, distribuye cada tarea en bloques horarios concretos dentro de la disponibilidad que el usuario declara para cada dia.

El resultado es un plan de trabajo actualizado en tiempo real: cada vez que el usuario agrega, edita o completa una tarea, el sistema recalcula el orden y la distribucion horaria sin que el estudiante tenga que hacer nada.

## Pestanas principales

### Agregar tarea

Flujo conversacional guiado por una mascota pug. El usuario responde siete preguntas secuenciales: nombre de la tarea, materia, fecha de entrega, nivel de dificultad (1-5), tiempo estimado en bloques de 30 minutos, dias que no podra trabajar en ella y horario disponible por cada dia activo. Los horarios se pre-rellenan automaticamente a partir de lo que el usuario ha declarado antes para ese dia de la semana, de modo que no hay que ingresar los mismos datos repetidamente.

### Listado ordenado

Muestra las tareas activas en el orden que el sistema recomienda trabajarlas. Cada tarjeta indica la materia, el proximo bloque de trabajo asignado y la fecha de entrega. Al expandirla se ven todos los bloques planificados, el progreso parcial registrado y las opciones para editar o marcar como realizada. Las tareas completadas y las vencidas aparecen en secciones separadas al final de la lista.

El progreso parcial es acumulativo: marcar un bloque como hecho suma su duracion al tiempo trabajado, y la pantalla refleja cuanto queda pendiente. Si el tiempo disponible no alcanza para completar una tarea antes del vencimiento, la tarjeta lo indica con un aviso visible.

### Calendario

Vista mensual con marcadores de colores: azul para los dias con bloques de trabajo programados y fucsia para las fechas de entrega. Al seleccionar un dia aparece la lista de eventos correspondientes con el rango horario de cada bloque y el nombre de la tarea. Las tareas completadas y vencidas no aparecen en el calendario.

## Sistema de prediccion

El orden del listado lo determina un algoritmo de dos etapas: el Ranker calcula la prioridad de cada tarea y el Scheduler asigna los bloques horarios respetando esa prioridad sin que dos tareas se solapen en el mismo momento del dia.

### Factores del Ranker

El Ranker aplica primero reglas de tier y luego un score ponderado:

1. **Tareas para hoy**: si la fecha de entrega es hoy o hay un bloque disponible en el dia, la tarea siempre aparece al tope.
2. **Tareas criticas**: si quedan dos dias disponibles o menos, la tarea sube al segundo tier independientemente de su score.
3. **Score ponderado**: dentro de cada tier, las tareas se ordenan por una puntuacion calculada a partir de cinco factores normalizados en escala 0-1.

Los cinco factores y sus pesos:

| Factor | Peso | Logica |
|---|---|---|
| Urgencia (dias disponibles) | 35% | Menos dias hasta el vencimiento, mayor prioridad |
| Dificultad (1-5) | 25% | Tareas mas dificiles van primero para dejar margen de correccion |
| Tiempo estimado | 20% | Las tareas largas necesitan comenzarse antes |
| Disponibilidad horaria | 10% | Cuando el tiempo libre diario es reducido, la urgencia aumenta |
| Gusto por la materia (1-5) | 10% | Las materias favoritas van primero como incentivo |

Los pesos son constantes configurables, separadas de la logica del algoritmo.

### Scheduler

Una vez establecido el orden, el Scheduler distribuye cada tarea en bloques horarios dentro de los intervalos que el usuario declaro para cada dia. Usa un pool compartido por dia para evitar solapamientos entre tareas: la de mayor prioridad reserva primero y las siguientes ocupan el tiempo restante. El dia actual se recorta a la hora presente para no planificar en el pasado. El tiempo ya trabajado se descuenta del estimado antes de distribuir los bloques.

## Stack tecnologico

| Capa | Tecnologia |
|---|---|
| Framework | Flutter (Dart) |
| Gestion de estado | Riverpod 2.x (providers manuales) |
| Persistencia local | Drift (SQLite) |
| Routing | go_router |
| Modelos inmutables | Freezed |
| Calendario UI | table_calendar |
| Animaciones | flutter_animate |
| Tipografia | Google Fonts - Manrope |
| Notificaciones locales | flutter_local_notifications |
| Preferencias | shared_preferences |

## Estructura del proyecto

```
lib/
  app/
    theme/           Paleta de colores, tipografia y ThemeData
    router/          Configuracion de go_router y guardas de navegacion
  core/
    utils/           Utilidades sin logica de negocio (formatos de hora y fecha)
    widgets/         Componentes UI reutilizables
  data/
    database/        Tablas Drift, DAOs y migraciones
    repositories/    Implementaciones concretas de los repositorios
    services/        Servicios de infraestructura (notificaciones)
  domain/
    entities/        Modelos inmutables con Freezed (Task, Subject, etc.)
    repositories/    Interfaces abstractas de repositorios
    notifications/   Logica pura de planificacion de notificaciones
    prediction/      Algoritmo de prediccion: Ranker y Scheduler
  features/
    add_task/        Flujo de creacion de tareas
    calendar/        Pestaña calendario
    day_limits/      Configuracion del tope de tareas por dia
    manage_subjects/ Gestion de materias y preferencias
    notifications/   Pantalla de configuracion de notificaciones
    onboarding/      Registro inicial de materias
    shell/           Scaffold principal con navegacion entre pestanas
    task_list/       Pestaña listado ordenado
  l10n/              Localizacion en espanol
```

La capa `domain/` no depende de Flutter ni de Drift, lo que permite probar el algoritmo de prediccion en Dart puro. Las implementaciones concretas viven en `data/` e implementan las interfaces de `domain/repositories/`.

## Configuracion inicial

Al abrir la app por primera vez, el usuario registra sus materias y asigna a cada una un nivel de gusto del 1 al 5. Eso es todo lo que se requiere antes de poder agregar tareas. Los horarios de trabajo se aprenden progresivamente: cada vez que el usuario ingresa una disponibilidad para un dia de la semana, el sistema la recuerda y la sugiere la proxima vez que aparezca ese dia en una tarea nueva.

## Notificaciones

La app programa tres tipos de notificaciones locales: aviso 24 horas antes del vencimiento de una tarea, recordatorio 15 minutos antes de cada bloque de trabajo programado, y alerta cuando una tarea entra al tier critico con dos dias o menos de margen. Cada tipo se puede activar o desactivar de forma independiente desde el menu principal.

## Requisitos

- Flutter 3.24 o superior
- Dart 3.5 o superior
- Dispositivo o emulador Android (minSdk 21) o iOS

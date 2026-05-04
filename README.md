<div align="center">

# Myndex

**Tu biblioteca personal. Películas, series, juegos y libros — todo en un sitio.**

[![CI](https://github.com/KanjoLOOP/Myndex/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/KanjoLOOP/Myndex/actions/workflows/flutter_ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Licencia](https://img.shields.io/badge/Licencia-MIT-green)
![Plataforma](https://img.shields.io/badge/Plataforma-Android-3DDC84?logo=android&logoColor=white)

</div>

---

## El origen

Myndex nació de una libreta.

Mi pareja llevaba años apuntando a mano cada película que quería ver, cada libro que le recomendaban, cada serie que tenía pendiente. Páginas y páginas llenas de títulos, estados y valoraciones escritas a boli. La libreta se perdía, las notas se borraban, nunca sabía qué había visto ya y qué no.

Esta app es la versión digital de esa libreta — pero sin límites, sin letra ilegible y con búsqueda instantánea.

---

## ¿Qué es Myndex?

Una app móvil **offline-first** para gestionar tu consumo de contenido personal: películas, series, videojuegos, libros y anime. Sin cuentas, sin servidores, sin suscripciones. Todo queda en tu dispositivo.

Las APIs externas (TMDB, RAWG, Open Library) se usan de forma opcional para rellenar automáticamente portadas, años y metadatos al añadir un título.

---

## Funcionalidades

| Función | Descripción |
|---|---|
| Añadir contenido | Manualmente o buscando en TMDB / RAWG / Open Library |
| Estados | Pendiente · En progreso · Completado · Abandonado |
| Smart Backlog | Cola de prioridad basada en puntuación y estado |
| Recomendaciones | Motor local que sugiere títulos según tu biblioteca |
| Timeline | Vista cronológica del contenido completado |
| Baúl | Organiza títulos en colecciones personalizadas |
| Estadísticas | Gráficas y métricas de tu biblioteca |
| Valoraciones | Puntuación 0–10 con gráfico radar |
| Progreso | Tiempo estimado restante por título |
| Filtros | Por tipo, estado, puntuación y más |
| Backup | Exportar / importar en JSON |
| Offline-first | Funciona sin internet; las APIs son enriquecimiento opcional |

---

## Arquitectura

Clean Architecture + MVVM con estructura modular por feature.

```
lib/
├── core/
│   ├── database/        # Drift (SQLite)
│   ├── network/         # Cliente HTTP con Dio
│   ├── router/          # Navegación con go_router
│   ├── security/        # Gestión de API keys, sanitización de inputs
│   ├── theme/           # Material 3, colores y estilos
│   └── widgets/         # Componentes UI compartidos
└── features/
    ├── content/         # CRUD principal (data · domain · presentation)
    ├── home/            # Biblioteca con filtros avanzados
    ├── search/          # Búsqueda local y externa
    ├── vault/           # Colecciones (Baúl)
    ├── stats/           # Gráficas y métricas
    ├── timeline/        # Vista cronológica
    ├── smart_backlog/   # Cola de pendientes por prioridad
    ├── backup/          # Export / import
    └── settings/        # Preferencias
```

**Stack técnico:**

| Capa | Librería |
|---|---|
| Estado | Flutter Riverpod 2.x |
| Base de datos local | Drift (SQLite) |
| Navegación | go_router |
| HTTP | Dio |
| Gráficas | fl_chart |
| UI | Material 3 |
| Generación de código | Freezed + json_serializable + riverpod_generator |

---

## Instalación

### Requisitos

- Flutter SDK >= 3.3.0
- Dart SDK >= 3.3.0
- Android SDK

### Pasos

```bash
# 1. Clonar
git clone https://github.com/KanjoLOOP/Myndex.git
cd Myndex

# 2. Instalar dependencias
flutter pub get

# 3. Generar código (Drift + Riverpod + Freezed)
dart run build_runner build --delete-conflicting-outputs

# 4. Ejecutar sin API keys (solo funciones locales)
flutter run

# 5. Ejecutar con API keys (activa búsqueda externa)
flutter run \
  --dart-define=TMDB_API_KEY=tu_clave_tmdb \
  --dart-define=RAWG_API_KEY=tu_clave_rawg
```

> Las API keys se inyectan en tiempo de compilación con `--dart-define` y nunca se almacenan en el código fuente. Ver `.env.example` como referencia.

### Build APK release

```bash
flutter build apk --release \
  --dart-define=TMDB_API_KEY=tu_clave_tmdb \
  --dart-define=RAWG_API_KEY=tu_clave_rawg
```

---

## APIs utilizadas

| API | Para | Clave necesaria | Plan gratuito |
|---|---|---|---|
| [TMDB](https://www.themoviedb.org/settings/api) | Películas y series | Sí | Sí |
| [RAWG](https://rawg.io/apidocs) | Videojuegos | Sí | Sí (20k req/mes) |
| [Open Library](https://openlibrary.org/developers) | Libros | No | Siempre gratuito |

---

## Seguridad

- Las API keys nunca aparecen en el código fuente ni en el historial de git
- Todo el tráfico de red es HTTPS (forzado en tiempo de ejecución)
- Los inputs del usuario se sanitizan antes de escrituras en BD y consultas a APIs
- Ningún dato del usuario se envía a servidores externos más allá de las búsquedas de metadatos

---

## Roadmap

- [x] Integración con TMDB (películas y series)
- [x] Integración con RAWG (videojuegos)
- [x] Integración con Open Library (libros)
- [x] Estadísticas y gráficas de biblioteca
- [x] Smart Backlog con ranking de prioridad
- [x] Vista Timeline
- [x] Colecciones personalizadas (Baúl)
- [x] Motor de recomendaciones
- [ ] Widget de pantalla de inicio (Android)
- [ ] Notificaciones y recordatorios
- [ ] Color de acento personalizable
- [ ] Publicación en Google Play Store

---

## Ramas

| Rama | Propósito |
|---|---|
| `main` | Producción estable |
| `develop` | Integración de features |
| `feature/*` | Nuevas funcionalidades |
| `fix/*` | Corrección de bugs |
| `release/*` | Preparación de versiones |

---

## Licencia

MIT © [KanjoLOOP](https://github.com/KanjoLOOP)

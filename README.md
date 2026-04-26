<div align="center">
  <h1>📚 Myndex</h1>
  <p><strong>Tu biblioteca personal. Todo en un sitio.</strong></p>

  ![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
  ![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
  ![License](https://img.shields.io/badge/License-MIT-green)
  ![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)
</div>

---

## ✨ El origen

Myndex nació de una libreta.

Mi pareja llevaba años apuntando a mano cada película que quería ver, cada libro que le recomendaban, cada serie que tenía pendiente. Páginas y páginas llenas de títulos, estados y valoraciones escritas a boli. La libreta se perdía, las notas se borraban, nunca sabía qué había visto ya y qué no.

Esta app es la versión digital de esa libreta — pero sin límites, sin letra ilegible y con búsqueda instantánea.

---

## 🎯 ¿Qué es Myndex?

Una app móvil **100% offline-first** para gestionar tu consumo de contenido personal: películas, series, videojuegos, libros, anime y más. Sin cuentas, sin servidores, sin suscripciones. Todo queda en tu dispositivo.

---

## 🚀 Funcionalidades

- **Añadir contenido** manualmente o buscando en TMDB / RAWG / Open Library
- **Estados**: Pendiente · En progreso · Completado · Abandonado
- **Puntuación** de 0 a 10
- **Notas personales** por título
- **Filtros** por tipo, estado y puntuación
- **Export / Import JSON** para backup y migración entre dispositivos
- **Offline-first**: funciona sin internet (la búsqueda de APIs es opcional)

---

## 🏗️ Arquitectura

```
Clean Architecture + MVVM
├── core/           # Utilidades, temas, base de datos, router
└── features/
    ├── content/    # CRUD principal
    │   ├── data/       # Datasources (Drift + TMDB), models, repository impl
    │   ├── domain/     # Entities, repository abstract, usecases
    │   └── presentation/ # Pages, providers (Riverpod), widgets
    ├── search/     # Búsqueda local y API
    ├── home/       # Vista principal con filtros
    └── settings/   # Export / Import
```

**Stack:**
| Capa | Librería |
|---|---|
| Estado | Flutter Riverpod 2.x |
| Base de datos local | Drift (SQLite) |
| Navegación | go_router |
| HTTP | Dio |
| UI | Material 3 |

---

## ⚙️ Instalación y ejecución

### Requisitos

- Flutter SDK ≥ 3.3.0
- Dart SDK ≥ 3.3.0
- Android SDK / Xcode (según plataforma objetivo)

### Pasos

```bash
# 1. Clona el repositorio
git clone https://github.com/KanjoLOOP/Myndex.git
cd Myndex

# 2. Instala dependencias
flutter pub get

# 3. Genera código (Drift + Riverpod + Freezed)
dart run build_runner build --delete-conflicting-outputs

# 4. (Opcional) Configura las API keys
cp .env.example .env
# Edita .env con tus claves de TMDB y RAWG

# 5. Ejecuta
flutter run
```

> Las API keys se inyectan en tiempo de compilación con `--dart-define`:
> ```bash
> flutter run --dart-define=TMDB_API_KEY=tu_clave --dart-define=RAWG_API_KEY=tu_clave
> ```

---

## 🌿 Ramas

| Rama | Propósito |
|---|---|
| `main` | Producción estable |
| `develop` | Integración de features |
| `feature/*` | Nuevas funcionalidades |
| `fix/*` | Corrección de bugs |
| `release/*` | Preparación de versiones |

---

## 🗺️ Roadmap

- [ ] Integración con RAWG (videojuegos)
- [ ] Integración con Open Library (libros)
- [ ] Widget de pantalla de inicio (Android)
- [ ] Estadísticas y gráficas de consumo
- [ ] Tema personalizable (colores)
- [ ] Recordatorios y notificaciones

---

## 🔒 Proyecto privado

Este es un proyecto personal, no está abierto a contribuciones externas.

---

## 📄 Licencia

MIT © [KanjoLOOP](https://github.com/KanjoLOOP)

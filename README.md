<div align="center">

# Myndex

**Personal content library — movies, series, games, books, all in one place.**

[![CI](https://github.com/KanjoLOOP/Myndex/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/KanjoLOOP/Myndex/actions/workflows/flutter_ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)

</div>

---

## Overview

Myndex is an **offline-first** Android app for tracking personal content consumption: movies, series, video games, books, and anime. No accounts, no servers, no subscriptions — everything lives on your device.

External APIs (TMDB, RAWG, Open Library) are used optionally to auto-fill covers, release years, and metadata when adding new titles.

---

## Features

| Feature | Description |
|---|---|
| Add content | Manually or via API search (TMDB / RAWG / Open Library) |
| Status tracking | Pending · In Progress · Completed · Dropped |
| Smart Backlog | AI-ranked priority queue based on score + status |
| Recommendations | Local engine suggests related titles from your library |
| Timeline | Chronological view of completed content |
| Vault | Organize titles into custom collections |
| Stats | Charts and metrics on your library |
| Ratings | 0–10 score with radar chart breakdown |
| Progress tracking | Estimated time remaining per title |
| Filters | By type, status, score, and more |
| Backup | Export / import as JSON |
| Offline-first | Works without internet; APIs are optional enrichment |

---

## Architecture

Clean Architecture + MVVM with feature-based module structure.

```
lib/
├── core/
│   ├── database/        # Drift (SQLite) setup
│   ├── network/         # Dio HTTP client factory
│   ├── router/          # go_router configuration
│   ├── security/        # API key manager, input sanitizer
│   ├── theme/           # Material 3 theme, colors, text styles
│   └── widgets/         # Shared UI components
└── features/
    ├── content/         # Core CRUD (data · domain · presentation)
    ├── home/            # Library view with advanced filters
    ├── search/          # Local + external search
    ├── vault/           # Collections
    ├── stats/           # Charts and library metrics
    ├── timeline/        # Chronological activity view
    ├── smart_backlog/   # Priority-ranked pending content
    ├── backup/          # Export / import
    └── settings/        # App preferences
```

**Tech stack:**

| Layer | Library |
|---|---|
| State management | Flutter Riverpod 2.x |
| Local database | Drift (SQLite) |
| Navigation | go_router |
| HTTP | Dio |
| Charts | fl_chart |
| UI | Material 3 |
| Code generation | Freezed + json_serializable + riverpod_generator |

---

## Getting Started

### Prerequisites

- Flutter SDK >= 3.3.0
- Dart SDK >= 3.3.0
- Android SDK (for device/emulator)

### Setup

```bash
# 1. Clone
git clone https://github.com/KanjoLOOP/Myndex.git
cd Myndex

# 2. Install dependencies
flutter pub get

# 3. Generate code (Drift + Riverpod + Freezed)
dart run build_runner build --delete-conflicting-outputs

# 4. Run (without API keys — local features only)
flutter run

# 5. Run with API keys (enables external search)
flutter run \
  --dart-define=TMDB_API_KEY=your_tmdb_key \
  --dart-define=RAWG_API_KEY=your_rawg_key
```

> API keys are injected at compile time via `--dart-define` and are never stored in source code. See `.env.example` for reference. Open Library requires no key.

### Build release APK

```bash
flutter build apk --release \
  --dart-define=TMDB_API_KEY=your_tmdb_key \
  --dart-define=RAWG_API_KEY=your_rawg_key
```

---

## API Keys

| API | Used for | Key required | Free tier |
|---|---|---|---|
| [TMDB](https://www.themoviedb.org/settings/api) | Movies & Series metadata | Yes | Yes |
| [RAWG](https://rawg.io/apidocs) | Video game metadata | Yes | Yes (20k req/month) |
| [Open Library](https://openlibrary.org/developers) | Book metadata | No | Always free |

---

## Security

- API keys never appear in source code or git history
- All network traffic is HTTPS-only (enforced at runtime)
- User input is sanitized before database writes and API queries
- No user data is sent to any external server beyond metadata lookups

---

## Roadmap

- [x] TMDB integration (movies & series)
- [x] RAWG integration (games)
- [x] Open Library integration (books)
- [x] Library stats and charts
- [x] Smart Backlog with priority ranking
- [x] Timeline view
- [x] Custom collections (Vault)
- [x] Recommendations engine
- [ ] Home screen widget (Android)
- [ ] Push notifications / reminders
- [ ] Customizable accent color
- [ ] Google Play Store release

---

## Branch Strategy

| Branch | Purpose |
|---|---|
| `main` | Stable, production-ready |
| `develop` | Integration of features |
| `feature/*` | New features |
| `fix/*` | Bug fixes |
| `release/*` | Release preparation |

---

## License

MIT © [KanjoLOOP](https://github.com/KanjoLOOP)

# Changelog

All notable changes to Myndex are documented here.  
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Planned
- Home screen widget (Android)
- Push notifications / reminders
- Customizable accent color
- Google Play Store release

---

## [1.0.0] — 2025-05

### Added
- Core CRUD for movies, series, games, books, and anime
- Offline-first local database via Drift (SQLite)
- External search: TMDB (movies/series), RAWG (games), Open Library (books)
- Smart Backlog: priority-ranked pending content queue
- Local recommendation engine based on library history
- Timeline: chronological view of completed content
- Vault: custom collections for organizing titles
- Library stats with fl_chart charts and metrics
- Radar chart rating breakdown per title
- Progress tracking with estimated time remaining
- Advanced filters: type, status, score range
- Export / import library as JSON backup
- Material 3 UI with dark mode and neon gradient theme
- API key management via `--dart-define` (never in source)
- Input sanitization and HTTPS-only networking
- Full test suite (unit + widget)
- GitHub Actions CI: analyze + test on every push

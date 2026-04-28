/// Constantes globales de la aplicación.
///
/// Aquí van únicamente valores no sensibles: URLs públicas, nombres
/// de fichero, etc. Las claves de API viven en
/// `core/security/api_key_manager.dart` y se inyectan en build time.
library;

class AppConstants {
  // Identidad de la app
  static const String appName = 'Myndex';

  // Base de datos local (Drift)
  static const String dbName = 'myndex';
  static const int dbVersion = 4;

  // TMDB (The Movie Database) — películas y series
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  // RAWG — videojuegos
  static const String rawgBaseUrl = 'https://api.rawg.io/api';

  // Open Library — libros (sin API key)
  static const String openLibraryBaseUrl = 'https://openlibrary.org';
  static const String openLibraryCoverBaseUrl = 'https://covers.openlibrary.org';

  // Export / import
  static const String exportFileName = 'myndex_backup.json';
  static const int exportSchemaVersion = 1;

  // Timeouts de red (ms)
  static const int httpConnectTimeoutMs = 10000;
  static const int httpReceiveTimeoutMs = 15000;

  // Límite máximo del fichero JSON a importar (bytes). 10 MB.
  static const int maxImportFileSizeBytes = 10 * 1024 * 1024;
}

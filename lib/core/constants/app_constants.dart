class AppConstants {
  static const String appName = 'Myndex';
  static const String dbName = 'myndex.db';
  static const int dbVersion = 1;

  // TMDB
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  static const String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');

  // RAWG
  static const String rawgBaseUrl = 'https://api.rawg.io/api';
  static const String rawgApiKey = String.fromEnvironment('RAWG_API_KEY');

  // Open Library
  static const String openLibraryBaseUrl = 'https://openlibrary.org';

  // Export
  static const String exportFileName = 'myndex_backup.json';
}

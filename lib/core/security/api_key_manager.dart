/// Gestor centralizado de claves de APIs externas.
///
/// Las claves se inyectan en tiempo de compilación con `--dart-define`
/// (o desde el `.env` cargado por el script de build) y NUNCA deben
/// ir hardcodeadas en el código fuente ni subirse al repositorio.
///
/// Ejemplo de ejecución:
/// ```bash
/// flutter run --dart-define=TMDB_API_KEY=xxx --dart-define=RAWG_API_KEY=yyy
/// ```
///
/// Este gestor expone helpers para saber si una key está disponible
/// antes de intentar llamar a su API, evitando peticiones que
/// terminarían en 401/403 y permitiendo a la UI degradar con elegancia.
library;

class ApiKeyManager {
  // Tomadas en tiempo de compilación. Si no se pasan, quedan vacías
  // y la app sigue funcionando solo con la base de datos local.
  static const String _tmdbKey =
      String.fromEnvironment('TMDB_API_KEY', defaultValue: '');
  static const String _rawgKey =
      String.fromEnvironment('RAWG_API_KEY', defaultValue: '');

  /// Devuelve la clave de TMDB o lanza si no está configurada.
  /// Llama a [hasTmdb] antes para no romper la UX.
  static String get tmdbKey {
    if (_tmdbKey.isEmpty) {
      throw StateError(
        'TMDB_API_KEY no está configurada. '
        'Lanza la app con --dart-define=TMDB_API_KEY=...',
      );
    }
    return _tmdbKey;
  }

  /// Devuelve la clave de RAWG o lanza si no está configurada.
  static String get rawgKey {
    if (_rawgKey.isEmpty) {
      throw StateError(
        'RAWG_API_KEY no está configurada. '
        'Lanza la app con --dart-define=RAWG_API_KEY=...',
      );
    }
    return _rawgKey;
  }

  /// `true` si TMDB está configurada (movies/series).
  static bool get hasTmdb => _tmdbKey.isNotEmpty;

  /// `true` si RAWG está configurada (videojuegos).
  static bool get hasRawg => _rawgKey.isNotEmpty;

  /// Open Library no requiere API key.
  static bool get hasOpenLibrary => true;
}

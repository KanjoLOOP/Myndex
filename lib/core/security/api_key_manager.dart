library;

class ApiKeyManager {
  static const String _tmdbKey =
      String.fromEnvironment('TMDB_API_KEY', defaultValue: '');
  static const String _rawgKey =
      String.fromEnvironment('RAWG_API_KEY', defaultValue: '');

  static String get tmdbKey {
    if (_tmdbKey.isEmpty) throw StateError('TMDB_API_KEY no configurada.');
    return _tmdbKey;
  }

  static String get rawgKey {
    if (_rawgKey.isEmpty) throw StateError('RAWG_API_KEY no configurada.');
    return _rawgKey;
  }

  static bool get hasTmdb => _tmdbKey.isNotEmpty;
  static bool get hasRawg => _rawgKey.isNotEmpty;
  static bool get hasOpenLibrary => true;
}

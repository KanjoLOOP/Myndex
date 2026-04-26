import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/security/api_key_manager.dart';
import '../../../../core/security/input_sanitizer.dart';

/// Datasource de TMDB (películas y series).
///
/// Notas de seguridad y robustez:
/// - La API key se lee de [ApiKeyManager] (build-time), nunca embebida
///   en el código fuente.
/// - El `query` del usuario se sanea antes de enviarse para evitar
///   peticiones absurdas o gigantes.
/// - Cualquier error de red se convierte en [NetworkFailure] con un
///   mensaje genérico apto para mostrar al usuario.
/// - Los resultados crudos se devuelven como `List<Map<String, dynamic>>`
///   y la conversión a entidades se hace en la capa superior. Esto
///   facilita testear el datasource sin tocar la lógica de negocio.
class TmdbDatasource {
  final Dio _dio;

  TmdbDatasource(this._dio);

  /// Busca películas por título.
  Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    return _search('/search/movie', query);
  }

  /// Busca series por título.
  Future<List<Map<String, dynamic>>> searchSeries(String query) async {
    return _search('/search/tv', query);
  }

  /// Operación común a ambos endpoints.
  Future<List<Map<String, dynamic>>> _search(
    String path,
    String rawQuery,
  ) async {
    if (!ApiKeyManager.hasTmdb) {
      throw const NetworkFailure(
        'TMDB no está configurado en esta build.',
      );
    }
    // No usamos sanitizeSearchQuery aquí porque eso escapa LIKE de
    // SQL; aquí solo recortamos espacios y limitamos longitud.
    final query = rawQuery.trim();
    if (query.isEmpty) return const [];
    if (query.length > InputSanitizer.maxQueryLength) {
      throw const NetworkFailure('Consulta demasiado larga');
    }

    try {
      final response = await _dio.get(
        path,
        queryParameters: {
          'api_key': ApiKeyManager.tmdbKey,
          'query': query,
          'language': 'es-ES',
          'include_adult': 'false', // filtro por defecto
        },
      );
      final results = response.data['results'];
      if (results is! List) return const [];
      return results
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException catch (_) {
      // Convertimos a Failure: la UI llama a SafeErrorMessage para el
      // texto definitivo. No re-emitimos detalles del DioException.
      throw const NetworkFailure('No se pudo contactar con TMDB.');
    }
  }

  /// Devuelve la URL completa de una imagen TMDB, o cadena vacía.
  String imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return '${AppConstants.tmdbImageBaseUrl}$path';
  }
}

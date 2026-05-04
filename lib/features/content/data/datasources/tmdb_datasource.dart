import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/security/api_key_manager.dart';
import '../../../../core/security/input_sanitizer.dart';

class TmdbDatasource {
  final Dio _dio;

  TmdbDatasource(this._dio);

  Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    return _search('/search/movie', query);
  }

  Future<List<Map<String, dynamic>>> searchSeries(String query) async {
    return _search('/search/tv', query);
  }

  Future<List<Map<String, dynamic>>> _search(
    String path,
    String rawQuery,
  ) async {
    if (!ApiKeyManager.hasTmdb) {
      throw const NetworkFailure('TMDB no está configurado en esta build.');
    }
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
          'include_adult': 'false',
        },
      );
      final results = response.data['results'];
      if (results is! List) return const [];
      return results
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException catch (_) {
      throw const NetworkFailure('No se pudo contactar con TMDB.');
    }
  }

  String imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return '${AppConstants.tmdbImageBaseUrl}$path';
  }
}

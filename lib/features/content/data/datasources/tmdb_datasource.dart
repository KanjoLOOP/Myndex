import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';

class TmdbDatasource {
  final Dio _dio;

  TmdbDatasource(this._dio);

  Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    final response = await _dio.get(
      '${AppConstants.tmdbBaseUrl}/search/movie',
      queryParameters: {
        'api_key': AppConstants.tmdbApiKey,
        'query': query,
        'language': 'es-ES',
      },
    );
    final results = response.data['results'] as List<dynamic>;
    return results.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> searchSeries(String query) async {
    final response = await _dio.get(
      '${AppConstants.tmdbBaseUrl}/search/tv',
      queryParameters: {
        'api_key': AppConstants.tmdbApiKey,
        'query': query,
        'language': 'es-ES',
      },
    );
    final results = response.data['results'] as List<dynamic>;
    return results.cast<Map<String, dynamic>>();
  }

  String imageUrl(String? path) =>
      path != null ? '${AppConstants.tmdbImageBaseUrl}$path' : '';
}

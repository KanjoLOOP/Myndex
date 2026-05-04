import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/security/api_key_manager.dart';
import '../../../../core/security/input_sanitizer.dart';

class RawgDatasource {
  final Dio _dio;

  RawgDatasource(this._dio);

  Future<List<Map<String, dynamic>>> searchGames(String query) async {
    if (!ApiKeyManager.hasRawg) {
      throw const NetworkFailure('RAWG no está configurado en esta build.');
    }
    final q = query.trim();
    if (q.isEmpty) return const [];
    if (q.length > InputSanitizer.maxQueryLength) {
      throw const NetworkFailure('Consulta demasiado larga');
    }

    try {
      final response = await _dio.get(
        '/games',
        queryParameters: {
          'key': ApiKeyManager.rawgKey,
          'search': q,
          'page_size': 20,
        },
      );
      final results = response.data['results'];
      if (results is! List) return const [];
      return results
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException catch (_) {
      throw const NetworkFailure('No se pudo contactar con RAWG.');
    }
  }

  String? imageUrl(Map<String, dynamic> raw) {
    final url = raw['background_image'];
    if (url is! String) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return url;
  }
}

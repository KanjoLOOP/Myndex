import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/security/input_sanitizer.dart';

/// Datasource de Open Library (libros).
///
/// Open Library no requiere API key. Sus endpoints relevantes:
/// - `GET /search.json?q=...` → lista de obras.
/// - Cover por OLID/ISBN: `https://covers.openlibrary.org/b/<key>/<id>-L.jpg`.
class OpenLibraryDatasource {
  final Dio _dio;

  OpenLibraryDatasource(this._dio);

  /// Busca libros por título o autor.
  Future<List<Map<String, dynamic>>> searchBooks(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    if (q.length > InputSanitizer.maxQueryLength) {
      throw const NetworkFailure('Consulta demasiado larga');
    }

    try {
      final response = await _dio.get(
        '/search.json',
        queryParameters: {
          'q': q,
          'limit': 20,
          'fields': 'key,title,author_name,first_publish_year,cover_i,isbn',
        },
      );
      final docs = response.data['docs'];
      if (docs is! List) return const [];
      return docs
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException catch (_) {
      throw const NetworkFailure('No se pudo contactar con Open Library.');
    }
  }

  /// Devuelve la URL de la portada usando el cover_i de Open Library.
  /// Tamaños: S, M, L. Usamos L para detalle, M para listas.
  String? coverUrlFromCoverId(int? coverId, {String size = 'M'}) {
    if (coverId == null) return null;
    return '${AppConstants.openLibraryCoverBaseUrl}/b/id/$coverId-$size.jpg';
  }
}

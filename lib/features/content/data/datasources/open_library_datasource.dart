import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/security/input_sanitizer.dart';

class OpenLibraryDatasource {
  final Dio _dio;

  OpenLibraryDatasource(this._dio);

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

  String? coverUrlFromCoverId(int? coverId, {String size = 'M'}) {
    if (coverId == null) return null;
    return '${AppConstants.openLibraryCoverBaseUrl}/b/id/$coverId-$size.jpg';
  }
}

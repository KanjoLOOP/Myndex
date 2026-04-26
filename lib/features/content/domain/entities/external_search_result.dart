import '../../../../core/constants/content_types.dart';

/// Resultado normalizado de cualquiera de las APIs externas.
///
/// Las APIs (TMDB, RAWG, Open Library) devuelven cada una su propio
/// shape. Esta entidad las unifica para que la UI pueda renderizarlas
/// con un único widget.
class ExternalSearchResult {
  final String externalId;
  final String source; // 'tmdb' | 'rawg' | 'openlibrary'
  final ContentType type;
  final String title;
  final String? imageUrl;
  final String? subtitle; // p. ej. autor del libro o año

  const ExternalSearchResult({
    required this.externalId,
    required this.source,
    required this.type,
    required this.title,
    this.imageUrl,
    this.subtitle,
  });
}

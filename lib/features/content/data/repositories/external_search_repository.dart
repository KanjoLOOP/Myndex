import '../../../../core/constants/content_types.dart';
import '../../domain/entities/external_search_result.dart';
import '../datasources/open_library_datasource.dart';
import '../datasources/rawg_datasource.dart';
import '../datasources/tmdb_datasource.dart';

/// Repositorio que unifica las búsquedas en TMDB, RAWG y Open Library.
///
/// La UI solo conoce este punto de entrada y un [ContentType]; el
/// repositorio decide a qué proveedor preguntar.
///
/// Caché: mantenemos un mapa LRU sencillo en memoria para que cuando
/// el usuario reformule la misma búsqueda no peguemos otra vez al
/// servidor. La caché se vacía al cerrar la app (es solo memoria).
/// Esto cumple el requisito "cachear resultados localmente" del brief
/// y a la vez evita persistir datos de terceros sin necesidad.
class ExternalSearchRepository {
  final TmdbDatasource _tmdb;
  final RawgDatasource _rawg;
  final OpenLibraryDatasource _openLibrary;

  // Caché LRU minimalista (key = "type:query").
  static const int _cacheCapacity = 32;
  final _cache = <String, List<ExternalSearchResult>>{};

  ExternalSearchRepository({
    required TmdbDatasource tmdb,
    required RawgDatasource rawg,
    required OpenLibraryDatasource openLibrary,
  })  : _tmdb = tmdb,
        _rawg = rawg,
        _openLibrary = openLibrary;

  /// Busca contenido externo del [type] indicado.
  /// Devuelve lista vacía si el tipo no tiene proveedor configurado.
  Future<List<ExternalSearchResult>> search({
    required ContentType type,
    required String query,
  }) async {
    final key = '${type.name}:${query.trim().toLowerCase()}';
    final cached = _cache[key];
    if (cached != null) {
      // Refrescamos el orden de inserción para LRU.
      _cache.remove(key);
      _cache[key] = cached;
      return cached;
    }

    final results = switch (type) {
      ContentType.movie  => await _searchMovies(query),
      ContentType.series => await _searchSeries(query),
      ContentType.game   => await _searchGames(query),
      ContentType.book   => await _searchBooks(query),
      // Anime y podcast usan TMDB y libre respectivamente; quedan
      // como TODO. Devolvemos vacío para no llamar a APIs no aptas.
      _ => <ExternalSearchResult>[],
    };

    _putInCache(key, results);
    return results;
  }

  void _putInCache(String key, List<ExternalSearchResult> value) {
    if (_cache.length >= _cacheCapacity) {
      _cache.remove(_cache.keys.first); // expulsa el más antiguo
    }
    _cache[key] = value;
  }

  // ── Adaptadores por proveedor ────────────────────────────────────

  Future<List<ExternalSearchResult>> _searchMovies(String q) async {
    final raw = await _tmdb.searchMovies(q);
    return raw.map((r) {
      return ExternalSearchResult(
        externalId: '${r['id']}',
        source: 'tmdb',
        type: ContentType.movie,
        title: (r['title'] as String?) ?? (r['original_title'] as String? ?? ''),
        imageUrl: _tmdb.imageUrl(r['poster_path'] as String?),
        subtitle: r['release_date'] as String?,
      );
    }).where((r) => r.title.isNotEmpty).toList();
  }

  Future<List<ExternalSearchResult>> _searchSeries(String q) async {
    final raw = await _tmdb.searchSeries(q);
    return raw.map((r) {
      return ExternalSearchResult(
        externalId: '${r['id']}',
        source: 'tmdb',
        type: ContentType.series,
        title: (r['name'] as String?) ?? (r['original_name'] as String? ?? ''),
        imageUrl: _tmdb.imageUrl(r['poster_path'] as String?),
        subtitle: r['first_air_date'] as String?,
      );
    }).where((r) => r.title.isNotEmpty).toList();
  }

  Future<List<ExternalSearchResult>> _searchGames(String q) async {
    final raw = await _rawg.searchGames(q);
    return raw.map((r) {
      return ExternalSearchResult(
        externalId: '${r['id']}',
        source: 'rawg',
        type: ContentType.game,
        title: (r['name'] as String?) ?? '',
        imageUrl: _rawg.imageUrl(r),
        subtitle: r['released'] as String?,
      );
    }).where((r) => r.title.isNotEmpty).toList();
  }

  Future<List<ExternalSearchResult>> _searchBooks(String q) async {
    final raw = await _openLibrary.searchBooks(q);
    return raw.map((r) {
      final authors = (r['author_name'] as List?)?.cast<String>().take(2).join(', ');
      final coverId = r['cover_i'];
      return ExternalSearchResult(
        externalId: (r['key'] as String?) ?? '',
        source: 'openlibrary',
        type: ContentType.book,
        title: (r['title'] as String?) ?? '',
        imageUrl: _openLibrary.coverUrlFromCoverId(
          coverId is int ? coverId : null,
        ),
        subtitle: authors,
      );
    }).where((r) => r.title.isNotEmpty).toList();
  }
}

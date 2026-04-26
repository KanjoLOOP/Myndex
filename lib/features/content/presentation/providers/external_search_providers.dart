import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/content_types.dart';
import '../../../../core/network/http_client.dart';
import '../../data/datasources/open_library_datasource.dart';
import '../../data/datasources/rawg_datasource.dart';
import '../../data/datasources/tmdb_datasource.dart';
import '../../data/repositories/external_search_repository.dart';
import '../../domain/entities/external_search_result.dart';

/// Providers para la búsqueda externa (TMDB / RAWG / Open Library).
///
/// Cada API recibe su propio cliente Dio para que un fallo o un
/// rate-limit en uno no afecte al resto. La caché LRU vive en el
/// repositorio y se mantiene mientras la app esté en memoria.

final _tmdbDioProvider = Provider((ref) {
  return HttpClientFactory.forBaseUrl(AppConstants.tmdbBaseUrl);
});

final _rawgDioProvider = Provider((ref) {
  return HttpClientFactory.forBaseUrl(AppConstants.rawgBaseUrl);
});

final _openLibraryDioProvider = Provider((ref) {
  return HttpClientFactory.forBaseUrl(AppConstants.openLibraryBaseUrl);
});

final tmdbDatasourceProvider = Provider<TmdbDatasource>(
  (ref) => TmdbDatasource(ref.watch(_tmdbDioProvider)),
);

final rawgDatasourceProvider = Provider<RawgDatasource>(
  (ref) => RawgDatasource(ref.watch(_rawgDioProvider)),
);

final openLibraryDatasourceProvider = Provider<OpenLibraryDatasource>(
  (ref) => OpenLibraryDatasource(ref.watch(_openLibraryDioProvider)),
);

final externalSearchRepositoryProvider = Provider<ExternalSearchRepository>(
  (ref) => ExternalSearchRepository(
    tmdb: ref.watch(tmdbDatasourceProvider),
    rawg: ref.watch(rawgDatasourceProvider),
    openLibrary: ref.watch(openLibraryDatasourceProvider),
  ),
);

/// Búsqueda externa parametrizada por tipo + query.
///
/// La UI hace `ref.watch(externalSearchProvider((type: ..., query: ...)))`
/// y obtiene un [AsyncValue] listo para `.when(...)`.
typedef ExternalSearchArgs = ({ContentType type, String query});

final externalSearchProvider = FutureProvider.family<
    List<ExternalSearchResult>, ExternalSearchArgs>((ref, args) async {
  if (args.query.trim().isEmpty) return const [];
  final repo = ref.watch(externalSearchRepositoryProvider);
  return repo.search(type: args.type, query: args.query);
});

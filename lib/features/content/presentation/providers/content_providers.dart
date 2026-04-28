import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/content_types.dart';
import '../../../../core/database/app_database.dart' show databaseProvider;
import '../../data/datasources/content_local_datasource.dart';
import '../../data/repositories/content_repository_impl.dart';
import '../../domain/entities/content_item.dart';
import '../../domain/recommender/local_recommender.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/usecases/delete_content_item.dart';
import '../../domain/usecases/get_content_list.dart';
import '../../domain/usecases/save_content_item.dart';

// ─── Infraestructura ──────────────────────────────────────────────

/// Datasource local. Depende del [databaseProvider] que se inyecta
/// en `main.dart`. En tests se sobrescribe con una DB en memoria.
final contentLocalDatasourceProvider = Provider<ContentLocalDatasource>(
  (ref) => ContentLocalDatasource(ref.watch(databaseProvider)),
);

/// Repositorio de contenido (única implementación: ContentRepositoryImpl).
final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepositoryImpl(ref.watch(contentLocalDatasourceProvider)),
);

// ─── Estado de filtros ────────────────────────────────────────────

/// Estado inmutable de filtros aplicado a la lista principal.
///
/// Se gestiona con un [StateProvider] simple porque solo cambia desde
/// la propia pantalla de Library. Si en el futuro hubiera que
/// persistirlo o compartirlo entre pantallas, migrar a
/// [StateNotifierProvider].
class FilterState {
  final ContentType? type;
  final ContentStatus? status;
  final double? minScore;

  const FilterState({this.type, this.status, this.minScore});

  /// Devuelve una copia con valores sustituidos. Los flags `clearXxx`
  /// permiten poner el campo a null explícitamente, lo cual no es
  /// posible con `?? this.x` cuando se quiere "limpiar" un filtro.
  FilterState copyWith({
    ContentType? type,
    ContentStatus? status,
    double? minScore,
    bool clearType = false,
    bool clearStatus = false,
    bool clearScore = false,
  }) =>
      FilterState(
        type: clearType ? null : (type ?? this.type),
        status: clearStatus ? null : (status ?? this.status),
        minScore: clearScore ? null : (minScore ?? this.minScore),
      );
}

final filterStateProvider =
    StateProvider<FilterState>((_) => const FilterState());

// ─── Lista principal ──────────────────────────────────────────────

/// Lista de contenido filtrada. Se invalida (`ref.invalidate(...)`)
/// tras cualquier mutación (alta, edición, borrado, import).
final contentListProvider = FutureProvider<List<ContentItem>>((ref) {
  final repo = ref.watch(contentRepositoryProvider);
  final filter = ref.watch(filterStateProvider);
  return GetContentList(repo).call(
    filterType: filter.type,
    filterStatus: filter.status,
    minScore: filter.minScore,
  );
});

/// Items marcados como favoritos. Usado por el Baúl › Favoritos.
final favoriteItemsProvider = FutureProvider<List<ContentItem>>((ref) {
  final repo = ref.watch(contentRepositoryProvider);
  return repo.getAll(filterFavorite: true);
});

// ─── Item individual ──────────────────────────────────────────────

/// Provider parametrizado por id para la pantalla de detalle/edición.
final contentItemProvider =
    FutureProvider.family<ContentItem?, int>((ref, id) {
  final repo = ref.watch(contentRepositoryProvider);
  return repo.getById(id);
});

// ─── Acciones ─────────────────────────────────────────────────────

final saveContentProvider = Provider<SaveContentItem>(
  (ref) => SaveContentItem(ref.watch(contentRepositoryProvider)),
);

final deleteContentProvider = Provider<DeleteContentItem>(
  (ref) => DeleteContentItem(ref.watch(contentRepositoryProvider)),
);

/// Alterna el estado favorito de un item y refresca las listas afectadas.
final toggleFavoriteProvider =
    Provider<Future<void> Function(ContentItem)>((ref) {
  final repo = ref.watch(contentRepositoryProvider);
  return (item) async {
    final updated = item.copyWith(
      isFavorite: !item.isFavorite,
      updatedAt: DateTime.now(),
    );
    await repo.update(updated);
    ref.invalidate(contentListProvider);
    ref.invalidate(contentItemProvider(item.id!));
    ref.invalidate(favoriteItemsProvider); // refresh vault favorites tab
  };
});

/// Incrementa el progreso en 1 unidad.
/// Si llega al total, marca automáticamente como [ContentStatus.completed].
final incrementProgressProvider =
    Provider<Future<void> Function(ContentItem)>((ref) {
  final repo = ref.watch(contentRepositoryProvider);
  return (item) async {
    final next = (item.progressUnits ?? 0) + 1;
    final total = item.totalUnits;
    final completed = total != null && next >= total;
    final updated = item.copyWith(
      progressUnits: next,
      status: completed ? ContentStatus.completed : ContentStatus.inProgress,
      completedAt: completed ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
    await repo.update(updated);
    ref.invalidate(contentListProvider);
    ref.invalidate(contentItemProvider(item.id!));
  };
});

/// Recomendaciones locales basadas en similitud coseno para un [ContentItem].
/// Devuelve hasta 5 ítems del backlog más similares al objetivo.
final recommendationsProvider =
    FutureProvider.family<List<ContentItem>, int>((ref, targetId) async {
  final repo = ref.watch(contentRepositoryProvider);
  final target = await repo.getById(targetId);
  if (target == null) return [];
  final library = await GetContentList(repo).call();
  return LocalRecommender.recommend(target: target, library: library);
});

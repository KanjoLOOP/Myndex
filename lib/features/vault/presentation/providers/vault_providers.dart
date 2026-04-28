import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/content_types.dart';
import '../../../../core/database/app_database.dart' show databaseProvider;
import '../../../content/domain/entities/content_item.dart';
import '../../../content/presentation/providers/content_providers.dart';
import '../../data/datasources/collection_local_datasource.dart';
import '../../domain/entities/collection.dart';

// Re-export so existing imports of favoriteItemsProvider from vault_providers still work.
export '../../../content/presentation/providers/content_providers.dart'
    show favoriteItemsProvider;

// ─── Datasource ────────────────────────────────────────────────────

final collectionDatasourceProvider = Provider<CollectionLocalDatasource>(
  (ref) => CollectionLocalDatasource(ref.watch(databaseProvider)),
);

// ─── Listas ────────────────────────────────────────────────────────

/// Todos los items completados (tab Historial).
final completedItemsProvider = FutureProvider<List<ContentItem>>((ref) {
  final repo = ref.watch(contentRepositoryProvider);
  return repo.getAll(filterStatus: ContentStatus.completed);
});

// favoriteItemsProvider is defined in content_providers.dart and re-exported above.
// This avoids a duplicate and ensures toggleFavoriteProvider can invalidate it.

/// Todas las colecciones con su conteo de items.
final collectionsProvider = FutureProvider<List<Collection>>((ref) {
  return ref.watch(collectionDatasourceProvider).getAll();
});

/// Items dentro de una colección específica.
final collectionItemsProvider =
    FutureProvider.family<List<ContentItem>, int>((ref, collectionId) {
  return ref.watch(collectionDatasourceProvider).getItems(collectionId);
});

/// IDs de colecciones que contienen un item dado.
final collectionIdsForItemProvider =
    FutureProvider.family<Set<int>, int>((ref, contentItemId) {
  return ref
      .watch(collectionDatasourceProvider)
      .getCollectionIdsForItem(contentItemId);
});

// ─── Acciones colecciones ──────────────────────────────────────────

final createCollectionProvider =
    Provider<Future<Collection> Function(String)>((ref) {
  final ds = ref.watch(collectionDatasourceProvider);
  return (name) async {
    final col = await ds.create(name);
    ref.invalidate(collectionsProvider);
    return col;
  };
});

final deleteCollectionProvider =
    Provider<Future<void> Function(int)>((ref) {
  final ds = ref.watch(collectionDatasourceProvider);
  return (id) async {
    await ds.delete(id);
    ref.invalidate(collectionsProvider);
    ref.invalidate(collectionItemsProvider(id));
  };
});

final toggleItemInCollectionProvider =
    Provider<Future<void> Function(int collectionId, int contentItemId, bool add)>(
        (ref) {
  final ds = ref.watch(collectionDatasourceProvider);
  return (collectionId, contentItemId, add) async {
    if (add) {
      await ds.addItem(collectionId, contentItemId);
    } else {
      await ds.removeItem(collectionId, contentItemId);
    }
    ref.invalidate(collectionIdsForItemProvider(contentItemId));
    ref.invalidate(collectionItemsProvider(collectionId));
    ref.invalidate(collectionsProvider);
  };
});

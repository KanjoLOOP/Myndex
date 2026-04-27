import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' hide Collection, ContentItem;
import '../../../../core/database/app_database.dart' as db show Collection;
import '../../../../features/content/data/models/content_item_model.dart';
import '../../../../features/content/domain/entities/content_item.dart';
import '../../domain/entities/collection.dart';

class CollectionLocalDatasource {
  final AppDatabase _db;

  CollectionLocalDatasource(this._db);

  // ─── Colecciones ───────────────────────────────────────────────────

  /// Todas las colecciones con su número de items.
  Future<List<Collection>> getAll() async {
    final rows = await (_db.select(_db.collections)
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .get();

    final counts = <int, int>{};
    for (final row in rows) {
      final count = await (_db.select(_db.collectionItems)
            ..where((ci) => ci.collectionId.equals(row.id)))
          .get()
          .then((list) => list.length);
      counts[row.id] = count;
    }

    return rows.map((r) => _rowToCollection(r, counts[r.id] ?? 0)).toList();
  }

  Future<Collection> create(String name) async {
    final id = await _db.into(_db.collections).insert(
          CollectionsCompanion.insert(name: name),
        );
    return Collection(id: id, name: name, createdAt: DateTime.now());
  }

  Future<void> rename(int id, String name) async {
    await (_db.update(_db.collections)..where((c) => c.id.equals(id)))
        .write(CollectionsCompanion(name: Value(name)));
  }

  Future<void> delete(int id) async {
    // Borra junction rows primero para no dejar huérfanos
    await (_db.delete(_db.collectionItems)
          ..where((ci) => ci.collectionId.equals(id)))
        .go();
    await (_db.delete(_db.collections)..where((c) => c.id.equals(id))).go();
  }

  // ─── Membresía ─────────────────────────────────────────────────────

  /// Items de contenido que pertenecen a una colección.
  Future<List<ContentItem>> getItems(int collectionId) async {
    final junctionRows = await (_db.select(_db.collectionItems)
          ..where((ci) => ci.collectionId.equals(collectionId)))
        .get();

    if (junctionRows.isEmpty) return const [];

    final ids = junctionRows.map((j) => j.contentItemId).toList();
    final contentRows = await (_db.select(_db.contentItems)
          ..where((t) => t.id.isIn(ids))
          ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
        .get();

    return contentRows.map((r) => r.toDomain()).toList();
  }

  /// IDs de las colecciones que contienen un item.
  Future<Set<int>> getCollectionIdsForItem(int contentItemId) async {
    final rows = await (_db.select(_db.collectionItems)
          ..where((ci) => ci.contentItemId.equals(contentItemId)))
        .get();
    return rows.map((r) => r.collectionId).toSet();
  }

  Future<void> addItem(int collectionId, int contentItemId) async {
    await _db.into(_db.collectionItems).insertOnConflictUpdate(
          CollectionItemsCompanion.insert(
            collectionId: collectionId,
            contentItemId: contentItemId,
          ),
        );
  }

  Future<void> removeItem(int collectionId, int contentItemId) async {
    await (_db.delete(_db.collectionItems)
          ..where((ci) =>
              ci.collectionId.equals(collectionId) &
              ci.contentItemId.equals(contentItemId)))
        .go();
  }

  /// Elimina todas las referencias a un item (cuando se borra el contenido).
  Future<void> removeItemFromAllCollections(int contentItemId) async {
    await (_db.delete(_db.collectionItems)
          ..where((ci) => ci.contentItemId.equals(contentItemId)))
        .go();
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  Collection _rowToCollection(db.Collection row, int count) => Collection(
        id: row.id,
        name: row.name,
        createdAt: row.createdAt,
        itemCount: count,
      );
}

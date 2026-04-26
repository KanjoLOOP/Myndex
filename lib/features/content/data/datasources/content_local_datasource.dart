import 'package:drift/drift.dart';
import '../../../../core/constants/content_types.dart';
import '../../../../core/database/app_database.dart';
import '../models/content_item_model.dart';
import '../../domain/entities/content_item.dart';

class ContentLocalDatasource {
  final AppDatabase _db;
  ContentLocalDatasource(this._db);

  Future<List<ContentItem>> getAll({
    ContentType? filterType,
    ContentStatus? filterStatus,
    double? minScore,
  }) async {
    var query = _db.select(_db.contentItems);
    query.where((t) {
      Expression<bool> expr = const Constant(true);
      if (filterType != null) expr = expr & t.type.equals(filterType.name);
      if (filterStatus != null) expr = expr & t.status.equals(filterStatus.name);
      if (minScore != null) expr = expr & t.score.isBiggerOrEqualValue(minScore);
      return expr;
    });
    query.orderBy([(t) => OrderingTerm.desc(t.addedAt)]);
    final rows = await query.get();
    return rows.map((r) => r.toDomain()).toList();
  }

  Future<ContentItem?> getById(int id) async {
    final row = await (_db.select(_db.contentItems)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  Future<ContentItem> insert(ContentItem item) async {
    final id = await _db.into(_db.contentItems).insert(item.toCompanion());
    return item.copyWith(id: id);
  }

  Future<ContentItem> update(ContentItem item) async {
    await (_db.update(_db.contentItems)..where((t) => t.id.equals(item.id!)))
        .write(item.toCompanion());
    return item;
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.contentItems)..where((t) => t.id.equals(id))).go();
  }

  Future<List<ContentItem>> search(String query) async {
    final rows = await (_db.select(_db.contentItems)
          ..where((t) => t.title.like('%$query%')))
        .get();
    return rows.map((r) => r.toDomain()).toList();
  }

  Future<List<ContentItem>> getAll$() async {
    final rows = await _db.select(_db.contentItems).get();
    return rows.map((r) => r.toDomain()).toList();
  }
}

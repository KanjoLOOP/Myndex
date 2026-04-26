import '../../domain/entities/content_item.dart';
import '../../domain/repositories/content_repository.dart';
import '../../../../core/constants/content_types.dart';
import '../datasources/content_local_datasource.dart';

class ContentRepositoryImpl implements ContentRepository {
  final ContentLocalDatasource _local;
  ContentRepositoryImpl(this._local);

  @override
  Future<List<ContentItem>> getAll({
    ContentType? filterType,
    ContentStatus? filterStatus,
    double? minScore,
  }) =>
      _local.getAll(
        filterType: filterType,
        filterStatus: filterStatus,
        minScore: minScore,
      );

  @override
  Future<ContentItem?> getById(int id) => _local.getById(id);

  @override
  Future<ContentItem> create(ContentItem item) => _local.insert(item);

  @override
  Future<ContentItem> update(ContentItem item) => _local.update(item);

  @override
  Future<void> delete(int id) => _local.delete(id);

  @override
  Future<List<ContentItem>> search(String query) => _local.search(query);

  @override
  Future<List<Map<String, dynamic>>> exportAll() async {
    final items = await _local.getAll$();
    return items.map((e) => e.toJson()).toList();
  }

  @override
  Future<int> importAll(
    List<Map<String, dynamic>> data, {
    bool skipDuplicates = true,
  }) async {
    int imported = 0;
    for (final json in data) {
      final item = ContentItem.fromJson(json);
      // Skip id so Drift generates a new one; keep title for duplicate check
      if (skipDuplicates) {
        final existing = await _local.search(item.title);
        if (existing.any((e) => e.title == item.title && e.type == item.type)) {
          continue;
        }
      }
      await _local.insert(item.copyWith(id: null));
      imported++;
    }
    return imported;
  }
}

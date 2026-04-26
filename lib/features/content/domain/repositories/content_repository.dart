import '../entities/content_item.dart';
import '../../../../core/constants/content_types.dart';

abstract class ContentRepository {
  Future<List<ContentItem>> getAll({
    ContentType? filterType,
    ContentStatus? filterStatus,
    double? minScore,
  });

  Future<ContentItem?> getById(int id);

  Future<ContentItem> create(ContentItem item);

  Future<ContentItem> update(ContentItem item);

  Future<void> delete(int id);

  Future<List<ContentItem>> search(String query);

  Future<List<Map<String, dynamic>>> exportAll();

  Future<int> importAll(List<Map<String, dynamic>> data, {bool skipDuplicates = true});
}

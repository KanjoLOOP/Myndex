import '../entities/content_item.dart';
import '../repositories/content_repository.dart';

/// Use case: guardar (crear o actualizar) un item.
///
/// Decide entre create/update mirando si el item trae id. Permite a
/// la UI olvidarse de esa distinción.
class SaveContentItem {
  final ContentRepository repository;
  const SaveContentItem(this.repository);

  Future<ContentItem> call(ContentItem item) {
    return item.id == null
        ? repository.create(item)
        : repository.update(item);
  }
}

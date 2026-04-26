import '../entities/content_item.dart';
import '../repositories/content_repository.dart';

class SaveContentItem {
  final ContentRepository repository;
  const SaveContentItem(this.repository);

  Future<ContentItem> call(ContentItem item) {
    return item.id == null
        ? repository.create(item)
        : repository.update(item);
  }
}

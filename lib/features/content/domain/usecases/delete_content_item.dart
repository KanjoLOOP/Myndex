import '../repositories/content_repository.dart';

class DeleteContentItem {
  final ContentRepository repository;
  const DeleteContentItem(this.repository);

  Future<void> call(int id) => repository.delete(id);
}

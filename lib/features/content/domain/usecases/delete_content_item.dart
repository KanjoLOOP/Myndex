import '../repositories/content_repository.dart';

/// Use case: borrar un item por id.
class DeleteContentItem {
  final ContentRepository repository;
  const DeleteContentItem(this.repository);

  Future<void> call(int id) => repository.delete(id);
}

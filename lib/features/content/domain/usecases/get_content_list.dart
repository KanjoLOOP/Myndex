import '../entities/content_item.dart';
import '../repositories/content_repository.dart';
import '../../../../core/constants/content_types.dart';

class GetContentList {
  final ContentRepository repository;
  const GetContentList(this.repository);

  Future<List<ContentItem>> call({
    ContentType? filterType,
    ContentStatus? filterStatus,
    double? minScore,
  }) {
    return repository.getAll(
      filterType: filterType,
      filterStatus: filterStatus,
      minScore: minScore,
    );
  }
}

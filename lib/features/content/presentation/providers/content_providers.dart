import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/content_types.dart';
import '../../../../core/database/app_database.dart';
import '../../data/datasources/content_local_datasource.dart';
import '../../data/repositories/content_repository_impl.dart';
import '../../domain/entities/content_item.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/usecases/delete_content_item.dart';
import '../../domain/usecases/get_content_list.dart';
import '../../domain/usecases/save_content_item.dart';

// --- Infra providers ---

final contentLocalDatasourceProvider = Provider<ContentLocalDatasource>(
  (ref) => ContentLocalDatasource(ref.watch(databaseProvider)),
);

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepositoryImpl(ref.watch(contentLocalDatasourceProvider)),
);

// --- Filter state ---

class FilterState {
  final ContentType? type;
  final ContentStatus? status;
  final double? minScore;
  const FilterState({this.type, this.status, this.minScore});

  FilterState copyWith({
    ContentType? type,
    ContentStatus? status,
    double? minScore,
    bool clearType = false,
    bool clearStatus = false,
    bool clearScore = false,
  }) =>
      FilterState(
        type: clearType ? null : (type ?? this.type),
        status: clearStatus ? null : (status ?? this.status),
        minScore: clearScore ? null : (minScore ?? this.minScore),
      );
}

final filterStateProvider =
    StateProvider<FilterState>((_) => const FilterState());

// --- Content list ---

final contentListProvider = FutureProvider<List<ContentItem>>((ref) {
  final repo = ref.watch(contentRepositoryProvider);
  final filter = ref.watch(filterStateProvider);
  return GetContentList(repo).call(
    filterType: filter.type,
    filterStatus: filter.status,
    minScore: filter.minScore,
  );
});

// --- Single item ---

final contentItemProvider =
    FutureProvider.family<ContentItem?, int>((ref, id) {
  final repo = ref.watch(contentRepositoryProvider);
  return repo.getById(id);
});

// --- Actions ---

final saveContentProvider = Provider<SaveContentItem>(
  (ref) => SaveContentItem(ref.watch(contentRepositoryProvider)),
);

final deleteContentProvider = Provider<DeleteContentItem>(
  (ref) => DeleteContentItem(ref.watch(contentRepositoryProvider)),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/presentation/providers/content_providers.dart';
import '../../domain/library_stats.dart';

/// Estadísticas calculadas sobre la lista completa (sin filtros).
/// Se refresca automáticamente cuando cambia contentListProvider.
final libraryStatsProvider = FutureProvider<LibraryStats>((ref) async {
  final repo = ref.watch(contentRepositoryProvider);
  final items = await repo.getAll();
  return LibraryStats.compute(items);
});

final activityLogProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(contentRepositoryProvider);
  return repo.getActivityLog();
});

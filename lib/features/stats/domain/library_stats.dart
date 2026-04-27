import '../../../core/constants/content_types.dart';
import '../../content/domain/entities/content_item.dart';

/// Estadísticas calculadas a partir de la biblioteca completa del usuario.
/// Inmutable; se recalcula cada vez que cambia la lista de contenido.
class LibraryStats {
  final int total;
  final int favorites;
  final double? averageScore; // null si ningún item tiene score

  final Map<ContentType, int> byType;
  final Map<ContentStatus, int> byStatus;

  /// Score medio por tipo (null si no hay items con score en ese tipo).
  final Map<ContentType, double?> averageScoreByType;

  /// Top 5 items por puntuación (descendente). Solo items con score != null.
  final List<ContentItem> topRated;

  const LibraryStats({
    required this.total,
    required this.favorites,
    required this.averageScore,
    required this.byType,
    required this.byStatus,
    required this.averageScoreByType,
    required this.topRated,
  });

  factory LibraryStats.empty() => LibraryStats(
        total: 0,
        favorites: 0,
        averageScore: null,
        byType: {},
        byStatus: {},
        averageScoreByType: {},
        topRated: [],
      );

  factory LibraryStats.compute(List<ContentItem> items) {
    if (items.isEmpty) return LibraryStats.empty();

    final byType = <ContentType, int>{};
    final byStatus = <ContentStatus, int>{};
    final scoresByType = <ContentType, List<double>>{};
    final allScores = <double>[];
    int favorites = 0;

    for (final item in items) {
      byType[item.type] = (byType[item.type] ?? 0) + 1;
      byStatus[item.status] = (byStatus[item.status] ?? 0) + 1;
      if (item.isFavorite) favorites++;
      if (item.score != null) {
        allScores.add(item.score!);
        scoresByType.putIfAbsent(item.type, () => []).add(item.score!);
      }
    }

    final averageScore = allScores.isEmpty
        ? null
        : allScores.reduce((a, b) => a + b) / allScores.length;

    final averageScoreByType = <ContentType, double?>{
      for (final t in ContentType.values)
        t: scoresByType.containsKey(t)
            ? scoresByType[t]!.reduce((a, b) => a + b) /
                scoresByType[t]!.length
            : null,
    };

    final topRated = [...items.where((i) => i.score != null)]
      ..sort((a, b) => b.score!.compareTo(a.score!));

    return LibraryStats(
      total: items.length,
      favorites: favorites,
      averageScore: averageScore,
      byType: byType,
      byStatus: byStatus,
      averageScoreByType: averageScoreByType,
      topRated: topRated.take(5).toList(),
    );
  }

  int get completed => byStatus[ContentStatus.completed] ?? 0;
  int get inProgress => byStatus[ContentStatus.inProgress] ?? 0;
  int get pending => byStatus[ContentStatus.pending] ?? 0;
  int get dropped => byStatus[ContentStatus.dropped] ?? 0;

  double get completionRate =>
      total == 0 ? 0 : completed / total;
}

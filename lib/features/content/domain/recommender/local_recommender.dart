import '../../../../core/constants/content_types.dart';
import '../entities/content_item.dart';

/// Local content recommender based on cosine similarity.
///
/// Algorithm:
/// 1. Build a feature vector for each item using genre, type, score
///    and rating dimensions.
/// 2. Compare the target item against every other completed/rated item.
/// 3. Return the top-N candidates from the pending backlog ordered by
///    similarity descending.
class LocalRecommender {
  /// Returns up to [limit] items from [candidates] ranked by similarity
  /// to [target]. Items already completed/dropped are excluded.
  static List<ContentItem> recommend({
    required ContentItem target,
    required List<ContentItem> library,
    int limit = 5,
  }) {
    final targetVec = _featureVector(target);
    if (targetVec.isEmpty) return [];

    final candidates = library.where((item) {
      if (item.id == target.id) return false;
      if (item.status == ContentStatus.completed ||
          item.status == ContentStatus.dropped) return false;
      return true;
    }).toList();

    final scored = candidates
        .map((item) {
          final vec = _featureVector(item);
          final sim = _cosineSimilarity(targetVec, vec);
          return (item: item, score: sim);
        })
        .where((r) => r.score > 0)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.take(limit).map((r) => r.item).toList();
  }

  /// Builds a normalized feature vector from a [ContentItem].
  ///
  /// Dimensions:
  /// - Index 0-6: one-hot encoding of ContentType
  /// - Index 7: normalized score (0–1)
  /// - Index 8-N: rating dimensions if available
  static List<double> _featureVector(ContentItem item) {
    final typeValues = ContentType.values;
    final typeVec =
        List<double>.generate(typeValues.length, (i) => typeValues[i] == item.type ? 1.0 : 0.0);

    final scoreVec = [(item.score ?? 0.0) / 10.0];

    // Flatten ratingDimensions values in sorted key order
    final dimVec = <double>[];
    if (item.ratingDimensions != null && item.ratingDimensions!.isNotEmpty) {
      final sorted = item.ratingDimensions!.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final e in sorted) {
        dimVec.add(((e.value as num).toDouble()) / 10.0);
      }
    }

    return [...typeVec, ...scoreVec, ...dimVec];
  }

  static double _cosineSimilarity(List<double> a, List<double> b) {
    final len = a.length < b.length ? a.length : b.length;
    if (len == 0) return 0;

    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < len; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0;
    return dot / (normA.isNaN || normB.isNaN ? 1 : (normA * normB <= 0 ? 1 : (normA * normB)));
  }
}

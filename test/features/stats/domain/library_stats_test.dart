import 'package:flutter_test/flutter_test.dart';
import 'package:myndex/core/constants/content_types.dart';
import 'package:myndex/features/content/domain/entities/content_item.dart';
import 'package:myndex/features/stats/domain/library_stats.dart';

ContentItem _item({
  int id = 1,
  String title = 'Item',
  ContentType type = ContentType.movie,
  ContentStatus status = ContentStatus.pending,
  double? score,
  bool isFavorite = false,
}) =>
    ContentItem(
      id: id,
      title: title,
      type: type,
      status: status,
      score: score,
      isFavorite: isFavorite,
      addedAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

void main() {
  group('LibraryStats.empty', () {
    test('total is 0', () {
      expect(LibraryStats.empty().total, 0);
    });

    test('averageScore is null', () {
      expect(LibraryStats.empty().averageScore, isNull);
    });

    test('topRated is empty', () {
      expect(LibraryStats.empty().topRated, isEmpty);
    });
  });

  group('LibraryStats.compute — totals', () {
    test('total counts all items', () {
      final stats = LibraryStats.compute([
        _item(id: 1),
        _item(id: 2),
        _item(id: 3),
      ]);
      expect(stats.total, 3);
    });

    test('returns empty when list is empty', () {
      final stats = LibraryStats.compute([]);
      expect(stats.total, 0);
      expect(stats.byType, isEmpty);
    });

    test('counts favorites correctly', () {
      final stats = LibraryStats.compute([
        _item(id: 1, isFavorite: true),
        _item(id: 2, isFavorite: true),
        _item(id: 3),
      ]);
      expect(stats.favorites, 2);
    });
  });

  group('LibraryStats.compute — byType', () {
    test('groups items by type', () {
      final stats = LibraryStats.compute([
        _item(id: 1, type: ContentType.movie),
        _item(id: 2, type: ContentType.movie),
        _item(id: 3, type: ContentType.book),
      ]);
      expect(stats.byType[ContentType.movie], 2);
      expect(stats.byType[ContentType.book], 1);
      expect(stats.byType[ContentType.game], isNull);
    });
  });

  group('LibraryStats.compute — byStatus', () {
    test('groups items by status', () {
      final stats = LibraryStats.compute([
        _item(id: 1, status: ContentStatus.completed),
        _item(id: 2, status: ContentStatus.completed),
        _item(id: 3, status: ContentStatus.inProgress),
        _item(id: 4, status: ContentStatus.dropped),
      ]);
      expect(stats.byStatus[ContentStatus.completed], 2);
      expect(stats.byStatus[ContentStatus.inProgress], 1);
      expect(stats.byStatus[ContentStatus.dropped], 1);
      expect(stats.byStatus[ContentStatus.pending], isNull);
    });

    test('completed getter returns 0 when no completed items', () {
      final stats = LibraryStats.compute([_item()]);
      expect(stats.completed, 0);
    });

    test('completionRate is correct', () {
      final stats = LibraryStats.compute([
        _item(id: 1, status: ContentStatus.completed),
        _item(id: 2, status: ContentStatus.completed),
        _item(id: 3),
        _item(id: 4),
      ]);
      expect(stats.completionRate, closeTo(0.5, 0.001));
    });

    test('completionRate is 0 when total is 0', () {
      expect(LibraryStats.empty().completionRate, 0.0);
    });
  });

  group('LibraryStats.compute — averageScore', () {
    test('null when no items have scores', () {
      final stats = LibraryStats.compute([_item(), _item(id: 2)]);
      expect(stats.averageScore, isNull);
    });

    test('correct average of multiple scores', () {
      final stats = LibraryStats.compute([
        _item(id: 1, score: 8.0),
        _item(id: 2, score: 6.0),
        _item(id: 3, score: 10.0),
      ]);
      expect(stats.averageScore, closeTo(8.0, 0.001));
    });

    test('ignores items without score', () {
      final stats = LibraryStats.compute([
        _item(id: 1, score: 8.0),
        _item(id: 2), // no score
      ]);
      expect(stats.averageScore, closeTo(8.0, 0.001));
    });
  });

  group('LibraryStats.compute — topRated', () {
    test('sorted descending by score', () {
      final stats = LibraryStats.compute([
        _item(id: 1, title: 'Low', score: 4.0),
        _item(id: 2, title: 'High', score: 10.0),
        _item(id: 3, title: 'Mid', score: 7.0),
      ]);
      expect(stats.topRated.first.title, 'High');
      expect(stats.topRated.last.title, 'Low');
    });

    test('max 5 items in topRated', () {
      final items = List.generate(
          10,
          (i) => _item(id: i, title: 'Item $i', score: i.toDouble() + 1));
      final stats = LibraryStats.compute(items);
      expect(stats.topRated.length, 5);
    });

    test('excludes items without score', () {
      final stats = LibraryStats.compute([
        _item(id: 1, title: 'Scored', score: 8.0),
        _item(id: 2, title: 'Unscored'), // no score
      ]);
      expect(stats.topRated.length, 1);
      expect(stats.topRated.first.title, 'Scored');
    });

    test('empty when no scored items', () {
      final stats = LibraryStats.compute([_item(), _item(id: 2)]);
      expect(stats.topRated, isEmpty);
    });
  });
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myndex/core/constants/content_types.dart';
import 'package:myndex/core/database/app_database.dart' hide ContentItem;
import 'package:myndex/features/content/data/datasources/content_local_datasource.dart';
import 'package:myndex/features/content/domain/entities/content_item.dart';

AppDatabase _openTestDb() =>
    AppDatabase.forTesting(NativeDatabase.memory());

ContentItem _item({
  int? id,
  String title = 'Test Movie',
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
  late AppDatabase db;
  late ContentLocalDatasource ds;

  setUp(() {
    db = _openTestDb();
    ds = ContentLocalDatasource(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('insert / getById', () {
    test('insert returns item with assigned id', () async {
      final inserted = await ds.insert(_item());
      expect(inserted.id, isNotNull);
      expect(inserted.id, greaterThan(0));
    });

    test('getById retrieves inserted item', () async {
      final inserted = await ds.insert(_item(title: 'Inception'));
      final found = await ds.getById(inserted.id!);
      expect(found, isNotNull);
      expect(found!.title, 'Inception');
    });

    test('getById returns null for non-existent id', () async {
      final found = await ds.getById(9999);
      expect(found, isNull);
    });

    test('isFavorite persisted correctly', () async {
      final inserted = await ds.insert(_item(isFavorite: true));
      final found = await ds.getById(inserted.id!);
      expect(found!.isFavorite, isTrue);
    });
  });

  group('update', () {
    test('update modifies fields', () async {
      final inserted = await ds.insert(_item());
      final updated = await ds.update(
          inserted.copyWith(title: 'Updated', status: ContentStatus.completed));
      final found = await ds.getById(updated.id!);
      expect(found!.title, 'Updated');
      expect(found.status, ContentStatus.completed);
    });

    test('update preserves addedAt', () async {
      final original = await ds.insert(_item());
      final updated = await ds.update(original.copyWith(
          title: 'Changed',
          updatedAt: DateTime(2025, 6, 1),
          addedAt: DateTime(2099, 1, 1))); // attempt to modify addedAt via update companion
      final found = await ds.getById(updated.id!);
      // The toUpdateCompanion does NOT include addedAt, so SQLite keeps original
      expect(found!.addedAt, DateTime(2024, 1, 1));
    });

    test('update throws StateError when item has no id', () async {
      expect(
        () => ds.update(_item()), // no id
        throwsStateError,
      );
    });

    test('update isFavorite toggle persists', () async {
      final inserted = await ds.insert(_item(isFavorite: false));
      await ds.update(inserted.copyWith(isFavorite: true));
      final found = await ds.getById(inserted.id!);
      expect(found!.isFavorite, isTrue);
    });
  });

  group('delete', () {
    test('delete removes item', () async {
      final inserted = await ds.insert(_item());
      await ds.delete(inserted.id!);
      final found = await ds.getById(inserted.id!);
      expect(found, isNull);
    });

    test('delete non-existent id does not throw', () async {
      await expectLater(ds.delete(9999), completes);
    });
  });

  group('getAll — filters', () {
    setUp(() async {
      await ds.insert(_item(id: null, title: 'Movie 1', type: ContentType.movie, status: ContentStatus.pending));
      await ds.insert(_item(id: null, title: 'Movie 2', type: ContentType.movie, status: ContentStatus.completed, score: 8.0));
      await ds.insert(_item(id: null, title: 'Book 1', type: ContentType.book, status: ContentStatus.inProgress));
      await ds.insert(_item(id: null, title: 'Game 1', type: ContentType.game, status: ContentStatus.completed, score: 6.0, isFavorite: true));
    });

    test('no filters returns all items', () async {
      final all = await ds.getAll();
      expect(all.length, 4);
    });

    test('filterType filters by content type', () async {
      final movies = await ds.getAll(filterType: ContentType.movie);
      expect(movies.length, 2);
      expect(movies.every((i) => i.type == ContentType.movie), isTrue);
    });

    test('filterStatus filters by status', () async {
      final completed = await ds.getAll(filterStatus: ContentStatus.completed);
      expect(completed.length, 2);
    });

    test('minScore filters by minimum score', () async {
      final highScore = await ds.getAll(minScore: 7.0);
      expect(highScore.length, 1);
      expect(highScore.first.title, 'Movie 2');
    });

    test('filterFavorite returns only favorites', () async {
      final favs = await ds.getAll(filterFavorite: true);
      expect(favs.length, 1);
      expect(favs.first.title, 'Game 1');
    });

    test('combined filters: type + status', () async {
      final result = await ds.getAll(
          filterType: ContentType.movie, filterStatus: ContentStatus.completed);
      expect(result.length, 1);
      expect(result.first.title, 'Movie 2');
    });
  });

  group('search', () {
    setUp(() async {
      await ds.insert(_item(title: 'Inception'));
      await ds.insert(_item(title: 'Interstellar'));
      await ds.insert(_item(title: 'The Dark Knight'));
    });

    test('finds items matching title substring', () async {
      final results = await ds.search('inter');
      expect(results.length, 1);
      expect(results.first.title, 'Interstellar');
    });

    test('case-insensitive search', () async {
      final results = await ds.search('INCEPTION');
      expect(results.length, 1);
    });

    test('returns empty for no match', () async {
      final results = await ds.search('xyznotfound');
      expect(results, isEmpty);
    });

    test('empty query returns empty list (not all items)', () async {
      final results = await ds.search('');
      expect(results, isEmpty);
    });

    test('LIKE wildcard in query does not cause full scan exploit', () async {
      // FTS5 special chars (%, *, etc.) are stripped by the sanitizer,
      // leaving an empty query that returns no results.
      final results = await ds.search('%');
      // Should return empty – stripped to '' which early-exits
      expect(results, isEmpty);
    });
  });

  group('existsByTitleAndType', () {
    test('returns true when item exists', () async {
      await ds.insert(_item(title: 'Dune', type: ContentType.book));
      final exists = await ds.existsByTitleAndType('Dune', ContentType.book);
      expect(exists, isTrue);
    });

    test('returns false for different type same title', () async {
      await ds.insert(_item(title: 'Dune', type: ContentType.book));
      final exists = await ds.existsByTitleAndType('Dune', ContentType.movie);
      expect(exists, isFalse);
    });

    test('returns false when no match', () async {
      final exists =
          await ds.existsByTitleAndType('Nonexistent', ContentType.game);
      expect(exists, isFalse);
    });
  });

  group('insertBatch', () {
    test('inserts multiple items atomically', () async {
      final items = [
        _item(title: 'A'),
        _item(title: 'B'),
        _item(title: 'C'),
      ];
      final count = await ds.insertBatch(items);
      expect(count, 3);
      final all = await ds.getAll();
      expect(all.length, 3);
    });

    test('returns 0 for empty list', () async {
      final count = await ds.insertBatch([]);
      expect(count, 0);
    });
  });
}

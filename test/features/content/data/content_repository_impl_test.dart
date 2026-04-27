import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myndex/core/constants/content_types.dart';
import 'package:myndex/core/database/app_database.dart' hide ContentItem;
import 'package:myndex/features/content/data/datasources/content_local_datasource.dart';
import 'package:myndex/features/content/data/repositories/content_repository_impl.dart';
import 'package:myndex/features/content/domain/entities/content_item.dart';

ContentRepositoryImpl _makeRepo() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  return ContentRepositoryImpl(ContentLocalDatasource(db));
}

ContentItem _unsaved({
  String title = 'Test',
  ContentType type = ContentType.movie,
  ContentStatus status = ContentStatus.pending,
  double? score,
  String? imageUrl,
  String? notes,
}) =>
    ContentItem(
      title: title,
      type: type,
      status: status,
      score: score,
      imageUrl: imageUrl,
      notes: notes,
      addedAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

void main() {
  group('ContentRepositoryImpl.create — sanitization', () {
    test('trims whitespace from title', () async {
      final repo = _makeRepo();
      final saved = await repo.create(_unsaved(title: '  Inception  '));
      expect(saved.title, 'Inception');
    });

    test('collapses multiple spaces in title', () async {
      final repo = _makeRepo();
      final saved = await repo.create(_unsaved(title: 'Hello   World'));
      expect(saved.title, 'Hello World');
    });

    test('rejects javascript: imageUrl', () async {
      final repo = _makeRepo();
      final saved = await repo.create(
          _unsaved(imageUrl: 'javascript:alert(1)'));
      expect(saved.imageUrl, isNull);
    });

    test('rejects file:// imageUrl', () async {
      final repo = _makeRepo();
      final saved =
          await repo.create(_unsaved(imageUrl: 'file:///etc/passwd'));
      expect(saved.imageUrl, isNull);
    });

    test('accepts https imageUrl', () async {
      final repo = _makeRepo();
      const url = 'https://image.tmdb.org/t/p/w500/abc.jpg';
      final saved = await repo.create(_unsaved(imageUrl: url));
      expect(saved.imageUrl, url);
    });

    test('score 0 stored as null', () async {
      final repo = _makeRepo();
      final saved = await repo.create(_unsaved(score: 0));
      expect(saved.score, isNull);
    });

    test('score above 10 clamped to 10', () async {
      final repo = _makeRepo();
      final saved = await repo.create(_unsaved(score: 15));
      expect(saved.score, 10.0);
    });

    test('empty notes stored as null', () async {
      final repo = _makeRepo();
      final saved = await repo.create(_unsaved(notes: '   '));
      expect(saved.notes, isNull);
    });

    test('assigns id after create', () async {
      final repo = _makeRepo();
      final saved = await repo.create(_unsaved());
      expect(saved.id, isNotNull);
    });
  });

  group('ContentRepositoryImpl.update — addedAt invariant', () {
    test('preserves original addedAt even if caller sends different date', () async {
      final repo = _makeRepo();
      final original = await repo.create(_unsaved());
      final originalAddedAt = original.addedAt;

      // Attempt to change addedAt during update
      final tampered = original.copyWith(
        title: 'Changed',
        addedAt: DateTime(2099, 12, 31),
        updatedAt: DateTime(2024, 6, 1),
      );
      await repo.update(tampered);

      final found = await repo.getById(original.id!);
      expect(found!.addedAt, originalAddedAt);
    });

    test('update sanitizes title', () async {
      final repo = _makeRepo();
      final created = await repo.create(_unsaved(title: 'Original'));
      await repo.update(
          created.copyWith(title: '  Updated Title  ', updatedAt: DateTime.now()));
      final found = await repo.getById(created.id!);
      expect(found!.title, 'Updated Title');
    });

    test('update sanitizes imageUrl', () async {
      final repo = _makeRepo();
      final created = await repo.create(_unsaved());
      await repo.update(created.copyWith(
          imageUrl: 'javascript:xss', updatedAt: DateTime.now()));
      final found = await repo.getById(created.id!);
      expect(found!.imageUrl, isNull);
    });

    test('throws StateError when item has no id', () async {
      final repo = _makeRepo();
      expect(
        () => repo.update(_unsaved()),
        throwsStateError,
      );
    });
  });

  group('ContentRepositoryImpl.delete', () {
    test('removes item from repository', () async {
      final repo = _makeRepo();
      final created = await repo.create(_unsaved());
      await repo.delete(created.id!);
      final found = await repo.getById(created.id!);
      expect(found, isNull);
    });
  });

  group('ContentRepositoryImpl.getAll — filtering', () {
    late ContentRepositoryImpl repo;

    setUp(() async {
      repo = _makeRepo();
      await repo.create(_unsaved(
          title: 'Pending Movie', type: ContentType.movie,
          status: ContentStatus.pending));
      await repo.create(_unsaved(
          title: 'Completed Movie', type: ContentType.movie,
          status: ContentStatus.completed, score: 9.0));
      await repo.create(_unsaved(
          title: 'Book', type: ContentType.book,
          status: ContentStatus.inProgress));
    });

    test('getAll no filters returns all', () async {
      final all = await repo.getAll();
      expect(all.length, 3);
    });

    test('filterType narrows results', () async {
      final movies = await repo.getAll(filterType: ContentType.movie);
      expect(movies.length, 2);
    });

    test('filterStatus narrows results', () async {
      final completed =
          await repo.getAll(filterStatus: ContentStatus.completed);
      expect(completed.length, 1);
      expect(completed.first.title, 'Completed Movie');
    });

    test('minScore filter works', () async {
      final high = await repo.getAll(minScore: 8.0);
      expect(high.length, 1);
      expect(high.first.score, 9.0);
    });
  });

  group('ContentRepositoryImpl.importAll', () {
    test('skips duplicate title+type by default', () async {
      final repo = _makeRepo();
      await repo.create(_unsaved(title: 'Dune', type: ContentType.book));

      final json = [
        ContentItem(
          title: 'Dune',
          type: ContentType.book,
          status: ContentStatus.pending,
          addedAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ).toJson(),
        ContentItem(
          title: 'Dune Part Two',
          type: ContentType.movie,
          status: ContentStatus.pending,
          addedAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ).toJson(),
      ];

      final inserted = await repo.importAll(json, skipDuplicates: true);
      expect(inserted, 1); // only Dune Part Two

      final all = await repo.getAll();
      expect(all.length, 2);
    });

    test('skipDuplicates false inserts all', () async {
      final repo = _makeRepo();
      await repo.create(_unsaved(title: 'Dune', type: ContentType.book));

      final json = [
        ContentItem(
          title: 'Dune',
          type: ContentType.book,
          status: ContentStatus.pending,
          addedAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ).toJson(),
      ];

      final inserted = await repo.importAll(json, skipDuplicates: false);
      expect(inserted, 1);
      final all = await repo.getAll();
      expect(all.length, 2);
    });

    test('skips malformed JSON entries without aborting batch', () async {
      final repo = _makeRepo();
      final json = [
        {'title': '', 'type': 'movie'}, // bad: empty title
        ContentItem(
          title: 'Valid Item',
          type: ContentType.game,
          status: ContentStatus.pending,
          addedAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ).toJson(),
      ];

      final inserted = await repo.importAll(json);
      expect(inserted, 1);
    });
  });
}

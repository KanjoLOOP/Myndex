import 'package:flutter_test/flutter_test.dart';
import 'package:myndex/core/constants/content_types.dart';
import 'package:myndex/features/content/domain/entities/content_item.dart';

ContentItem _base() => ContentItem(
      id: 1,
      title: 'Test Movie',
      type: ContentType.movie,
      status: ContentStatus.pending,
      addedAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

void main() {
  group('ContentItem defaults', () {
    test('isFavorite defaults to false', () {
      expect(_base().isFavorite, isFalse);
    });

    test('score defaults to null', () {
      expect(_base().score, isNull);
    });

    test('genre defaults to null', () {
      expect(_base().genre, isNull);
    });
  });

  group('ContentItem.copyWith', () {
    test('returns new instance with updated fields', () {
      final updated = _base().copyWith(title: 'New Title');
      expect(updated.title, 'New Title');
      expect(updated.id, 1); // unchanged
    });

    test('clearScore sets score to null', () {
      final item = _base().copyWith(score: 8.0);
      final cleared = item.copyWith(clearScore: true);
      expect(cleared.score, isNull);
    });

    test('clearNotes sets notes to null', () {
      final item = _base().copyWith(notes: 'Some notes');
      final cleared = item.copyWith(clearNotes: true);
      expect(cleared.notes, isNull);
    });

    test('clearGenre sets genre to null', () {
      final item = _base().copyWith(genre: 'Action');
      final cleared = item.copyWith(clearGenre: true);
      expect(cleared.genre, isNull);
    });

    test('clearImageUrl sets imageUrl to null', () {
      final item = _base().copyWith(imageUrl: 'https://example.com/img.jpg');
      final cleared = item.copyWith(clearImageUrl: true);
      expect(cleared.imageUrl, isNull);
    });

    test('clearExternalId sets externalId to null', () {
      final item = _base().copyWith(externalId: '123');
      final cleared = item.copyWith(clearExternalId: true);
      expect(cleared.externalId, isNull);
    });

    test('copyWith isFavorite toggles correctly', () {
      final fav = _base().copyWith(isFavorite: true);
      expect(fav.isFavorite, isTrue);
      final unfav = fav.copyWith(isFavorite: false);
      expect(unfav.isFavorite, isFalse);
    });

    test('addedAt preserved when not specified', () {
      final original = _base();
      final copy = original.copyWith(title: 'Different');
      expect(copy.addedAt, original.addedAt);
    });
  });

  group('ContentItem.toJson / fromJson round-trip', () {
    test('serializes and deserializes all fields', () {
      final item = ContentItem(
        id: 42,
        title: 'Inception',
        type: ContentType.movie,
        status: ContentStatus.completed,
        score: 9.0,
        genre: 'Sci-Fi',
        notes: 'Mind-bending',
        imageUrl: 'https://img.example.com/poster.jpg',
        externalId: 'tmdb-27205',
        externalSource: 'tmdb',
        isFavorite: true,
        addedAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 20),
      );

      final json = item.toJson();
      final restored = ContentItem.fromJson(json);

      expect(restored.title, item.title);
      expect(restored.type, item.type);
      expect(restored.status, item.status);
      expect(restored.score, item.score);
      expect(restored.genre, item.genre);
      expect(restored.notes, item.notes);
      expect(restored.imageUrl, item.imageUrl);
      expect(restored.externalId, item.externalId);
      expect(restored.externalSource, item.externalSource);
      expect(restored.isFavorite, item.isFavorite);
    });

    test('fromJson ignores id (import safety)', () {
      final json = _base().toJson();
      final restored = ContentItem.fromJson(json);
      // import always sets id to null to avoid collisions
      expect(restored.id, isNull);
    });

    test('fromJson defaults isFavorite to false when absent', () {
      final json = _base().toJson()..remove('isFavorite');
      final restored = ContentItem.fromJson(json);
      expect(restored.isFavorite, isFalse);
    });

    test('fromJson throws FormatException on missing title', () {
      final json = _base().toJson()..remove('title');
      expect(() => ContentItem.fromJson(json), throwsFormatException);
    });

    test('fromJson throws FormatException on empty title', () {
      final badJson = _base().toJson();
      badJson['title'] = '   ';
      expect(() => ContentItem.fromJson(badJson), throwsFormatException);
    });

    test('fromJson throws FormatException on unknown type', () {
      final json = _base().toJson();
      json['type'] = 'unknownType';
      expect(() => ContentItem.fromJson(json), throwsFormatException);
    });

    test('fromJson throws FormatException on unknown status', () {
      final json = _base().toJson();
      json['status'] = 'unknownStatus';
      expect(() => ContentItem.fromJson(json), throwsFormatException);
    });

    test('fromJson throws FormatException on bad addedAt date', () {
      final json = _base().toJson();
      json['addedAt'] = 'not-a-date';
      expect(() => ContentItem.fromJson(json), throwsFormatException);
    });

    test('fromJson handles null optional fields', () {
      final json = _base().toJson();
      json['score'] = null;
      json['genre'] = null;
      json['notes'] = null;
      json['imageUrl'] = null;
      final restored = ContentItem.fromJson(json);
      expect(restored.score, isNull);
      expect(restored.genre, isNull);
      expect(restored.notes, isNull);
      expect(restored.imageUrl, isNull);
    });
  });
}

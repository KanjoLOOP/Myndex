import 'package:flutter_test/flutter_test.dart';
import 'package:myndex/core/constants/content_types.dart';
import 'package:myndex/features/content/presentation/providers/content_providers.dart';

void main() {
  group('FilterState defaults', () {
    test('all fields are null by default', () {
      const state = FilterState();
      expect(state.type, isNull);
      expect(state.status, isNull);
      expect(state.minScore, isNull);
    });
  });

  group('FilterState.copyWith — set values', () {
    test('set type', () {
      const s = FilterState();
      final updated = s.copyWith(type: ContentType.movie);
      expect(updated.type, ContentType.movie);
      expect(updated.status, isNull);
    });

    test('set status', () {
      const s = FilterState();
      final updated = s.copyWith(status: ContentStatus.completed);
      expect(updated.status, ContentStatus.completed);
    });

    test('set minScore', () {
      const s = FilterState();
      final updated = s.copyWith(minScore: 6.0);
      expect(updated.minScore, 6.0);
    });

    test('preserves other fields when setting one', () {
      final s = const FilterState().copyWith(
          type: ContentType.book, status: ContentStatus.inProgress);
      final updated = s.copyWith(minScore: 4.0);
      expect(updated.type, ContentType.book);
      expect(updated.status, ContentStatus.inProgress);
      expect(updated.minScore, 4.0);
    });
  });

  group('FilterState.copyWith — clear flags', () {
    test('clearType sets type to null', () {
      final s = const FilterState().copyWith(type: ContentType.game);
      final cleared = s.copyWith(clearType: true);
      expect(cleared.type, isNull);
    });

    test('clearStatus sets status to null', () {
      final s =
          const FilterState().copyWith(status: ContentStatus.dropped);
      final cleared = s.copyWith(clearStatus: true);
      expect(cleared.status, isNull);
    });

    test('clearScore sets minScore to null', () {
      final s = const FilterState().copyWith(minScore: 8.0);
      final cleared = s.copyWith(clearScore: true);
      expect(cleared.minScore, isNull);
    });

    test('clear flag wins over simultaneous value', () {
      // If someone passes both type: X and clearType: true, clear wins
      final s = const FilterState().copyWith(type: ContentType.anime);
      final cleared = s.copyWith(type: ContentType.movie, clearType: true);
      expect(cleared.type, isNull);
    });
  });
}

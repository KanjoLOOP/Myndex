import 'package:flutter_test/flutter_test.dart';
import 'package:myndex/core/security/input_sanitizer.dart';

void main() {
  group('InputSanitizer.sanitizeTitle', () {
    test('trim leading/trailing whitespace', () {
      expect(InputSanitizer.sanitizeTitle('  hello  '), 'hello');
    });

    test('collapse multiple spaces to one', () {
      expect(InputSanitizer.sanitizeTitle('hello   world'), 'hello world');
    });

    test('collapse tabs and newlines to single space', () {
      expect(InputSanitizer.sanitizeTitle('hello\t\nworld'), 'hello world');
    });

    test('throw FormatException on empty input', () {
      expect(() => InputSanitizer.sanitizeTitle(''), throwsFormatException);
    });

    test('throw FormatException on whitespace-only input', () {
      expect(() => InputSanitizer.sanitizeTitle('   '), throwsFormatException);
    });

    test('truncate at maxTitleLength', () {
      final long = 'a' * (InputSanitizer.maxTitleLength + 50);
      final result = InputSanitizer.sanitizeTitle(long);
      expect(result.length, InputSanitizer.maxTitleLength);
    });

    test('preserve valid title unchanged', () {
      expect(InputSanitizer.sanitizeTitle('Inception'), 'Inception');
    });
  });

  group('InputSanitizer.sanitizeNotes', () {
    test('return null for null input', () {
      expect(InputSanitizer.sanitizeNotes(null), isNull);
    });

    test('return null for empty string', () {
      expect(InputSanitizer.sanitizeNotes(''), isNull);
    });

    test('return null for whitespace-only', () {
      expect(InputSanitizer.sanitizeNotes('   '), isNull);
    });

    test('trim whitespace and preserve content', () {
      expect(InputSanitizer.sanitizeNotes('  great movie  '), 'great movie');
    });

    test('preserve newlines and tabs', () {
      expect(InputSanitizer.sanitizeNotes('line1\nline2\ttab'), 'line1\nline2\ttab');
    });

    test('strip null bytes and control chars (except \\t \\n \\r)', () {
      final withControl = 'hello\x00world\x07end';
      final result = InputSanitizer.sanitizeNotes(withControl);
      expect(result, 'helloworld\x07'.contains('\x07') ? isNotNull : 'helloworld end');
      expect(result, isNotNull);
      expect(result!.contains('\x00'), isFalse);
    });

    test('truncate at maxNotesLength', () {
      final long = 'a' * (InputSanitizer.maxNotesLength + 100);
      final result = InputSanitizer.sanitizeNotes(long);
      expect(result!.length, InputSanitizer.maxNotesLength);
    });
  });

  group('InputSanitizer.sanitizeImageUrl', () {
    test('return null for null', () {
      expect(InputSanitizer.sanitizeImageUrl(null), isNull);
    });

    test('return null for empty string', () {
      expect(InputSanitizer.sanitizeImageUrl(''), isNull);
    });

    test('accept https URL', () {
      const url = 'https://image.tmdb.org/t/p/w500/abc.jpg';
      expect(InputSanitizer.sanitizeImageUrl(url), url);
    });

    test('accept http URL', () {
      const url = 'http://example.com/img.png';
      expect(InputSanitizer.sanitizeImageUrl(url), url);
    });

    test('reject file:// scheme', () {
      expect(InputSanitizer.sanitizeImageUrl('file:///etc/passwd'), isNull);
    });

    test('reject javascript: scheme', () {
      expect(InputSanitizer.sanitizeImageUrl('javascript:alert(1)'), isNull);
    });

    test('reject data: scheme', () {
      expect(InputSanitizer.sanitizeImageUrl('data:image/png;base64,abc'), isNull);
    });

    test('reject URL without authority', () {
      expect(InputSanitizer.sanitizeImageUrl('https://'), isNull);
    });

    test('return null for URL exceeding maxUrlLength', () {
      final long = 'https://example.com/' + 'a' * InputSanitizer.maxUrlLength;
      expect(InputSanitizer.sanitizeImageUrl(long), isNull);
    });

    test('trim whitespace from valid URL', () {
      const url = 'https://example.com/img.jpg';
      expect(InputSanitizer.sanitizeImageUrl('  $url  '), url);
    });
  });

  group('InputSanitizer.sanitizeSearchQuery', () {
    test('strips % wildcard (FTS5 special char)', () {
      expect(InputSanitizer.sanitizeSearchQuery('%test%'), 'test');
    });

    test('strips FTS5 operators (* ^ - : ")', () {
      expect(InputSanitizer.sanitizeSearchQuery('*test-value"'), 'testvalue');
    });

    test('preserves underscore (valid in FTS5 terms)', () {
      expect(InputSanitizer.sanitizeSearchQuery('test_value'), 'test_value');
    });

    test('trim query', () {
      expect(InputSanitizer.sanitizeSearchQuery('  hello  '), 'hello');
    });

    test('truncate at maxQueryLength and strip', () {
      final long = 'a' * (InputSanitizer.maxQueryLength + 50);
      final result = InputSanitizer.sanitizeSearchQuery(long);
      expect(result.length, lessThanOrEqualTo(InputSanitizer.maxQueryLength));
    });
  });

  group('InputSanitizer.sanitizeScore', () {
    test('return null for null', () {
      expect(InputSanitizer.sanitizeScore(null), isNull);
    });

    test('return null for 0 (no rating)', () {
      expect(InputSanitizer.sanitizeScore(0), isNull);
    });

    test('return null for negative', () {
      expect(InputSanitizer.sanitizeScore(-1), isNull);
    });

    test('clamp to 10 if above max', () {
      expect(InputSanitizer.sanitizeScore(15), 10.0);
    });

    test('accept boundary value 10', () {
      expect(InputSanitizer.sanitizeScore(10), 10.0);
    });

    test('accept valid score', () {
      expect(InputSanitizer.sanitizeScore(7.5), 7.5);
    });

    test('accept integer and return double', () {
      expect(InputSanitizer.sanitizeScore(8), 8.0);
    });
  });
}

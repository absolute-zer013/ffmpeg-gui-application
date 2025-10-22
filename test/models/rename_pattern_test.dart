import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/rename_pattern.dart';

void main() {
  group('RenamePattern Model', () {
    test('RenamePattern creation with all fields', () {
      final pattern = RenamePattern(
        name: 'TV Show',
        pattern: '{name} - S{season:2}E{episode:2}',
        description: 'Format for TV shows',
        isCustom: true,
      );

      expect(pattern.name, equals('TV Show'));
      expect(pattern.pattern, equals('{name} - S{season:2}E{episode:2}'));
      expect(pattern.description, equals('Format for TV shows'));
      expect(pattern.isCustom, isTrue);
    });

    test('RenamePattern with default values', () {
      final pattern = RenamePattern(
        name: 'Simple',
        pattern: '{name}',
      );

      expect(pattern.name, equals('Simple'));
      expect(pattern.pattern, equals('{name}'));
      expect(pattern.description, isEmpty);
      expect(pattern.isCustom, isFalse);
    });

    test('RenamePattern toJson/fromJson roundtrip', () {
      final original = RenamePattern(
        name: 'Movie',
        pattern: '{name} ({year})',
        description: 'Movie format',
        isCustom: true,
      );

      final json = original.toJson();
      final decoded = RenamePattern.fromJson(json);

      expect(decoded.name, equals(original.name));
      expect(decoded.pattern, equals(original.pattern));
      expect(decoded.description, equals(original.description));
      expect(decoded.isCustom, equals(original.isCustom));
    });

    test('RenamePattern copyWith creates modified copy', () {
      final original = RenamePattern(
        name: 'Original',
        pattern: '{name}',
        description: 'Original description',
      );

      final modified = original.copyWith(
        name: 'Modified',
        pattern: '{name} - {episode}',
      );

      expect(modified.name, equals('Modified'));
      expect(modified.pattern, equals('{name} - {episode}'));
      expect(modified.description, equals(original.description));
      expect(modified.isCustom, equals(original.isCustom));
    });

    test('getPredefinedPatterns returns list of patterns', () {
      final patterns = RenamePattern.getPredefinedPatterns();

      expect(patterns, isNotEmpty);
      expect(patterns.length, greaterThanOrEqualTo(5));

      // Check some specific patterns exist
      final names = patterns.map((p) => p.name).toList();
      expect(names, contains('Original'));
      expect(names, contains('TV Show'));
      expect(names, contains('Movie'));
      expect(names, contains('Anime'));
    });

    test('predefined patterns have valid structure', () {
      final patterns = RenamePattern.getPredefinedPatterns();

      for (final pattern in patterns) {
        expect(pattern.name, isNotEmpty);
        expect(pattern.pattern, isNotEmpty);
        expect(pattern.isCustom, isFalse);
      }
    });

    test('TV Show pattern has correct format', () {
      final patterns = RenamePattern.getPredefinedPatterns();
      final tvShow = patterns.firstWhere((p) => p.name == 'TV Show');

      expect(tvShow.pattern, contains('season'));
      expect(tvShow.pattern, contains('episode'));
    });

    test('Movie pattern has correct format', () {
      final patterns = RenamePattern.getPredefinedPatterns();
      final movie = patterns.firstWhere((p) => p.name == 'Movie');

      expect(movie.pattern, contains('year'));
      expect(movie.pattern, contains('name'));
    });

    test('Anime pattern has correct format', () {
      final patterns = RenamePattern.getPredefinedPatterns();
      final anime = patterns.firstWhere((p) => p.name == 'Anime');

      expect(anime.pattern, contains('episode'));
      expect(anime.pattern, contains('name'));
    });
  });
}

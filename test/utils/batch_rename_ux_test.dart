import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/rename_pattern.dart';
import 'package:ffmpeg_filter_app/utils/rename_utils.dart';

void main() {
  group('Batch Rename UX Quick Wins', () {
    group('Presets', () {
      test('Has all required presets', () {
        final presets = RenamePattern.getPredefinedPatterns();
        
        expect(presets.length, greaterThanOrEqualTo(5));
        
        // Check for required presets
        final presetNames = presets.map((p) => p.name).toList();
        expect(presetNames, contains('TV Show'));
        expect(presetNames, contains('Movie'));
        expect(presetNames, contains('Anime'));
        expect(presetNames, contains('Indexed'));
        expect(presetNames, contains('With Date'));
      });

      test('TV Show preset has correct format', () {
        final presets = RenamePattern.getPredefinedPatterns();
        final tvShow = presets.firstWhere((p) => p.name == 'TV Show');
        
        expect(tvShow.pattern, '{name} - S{season:2}E{episode:2}');
        expect(tvShow.description, isNotEmpty);
      });

      test('Movie preset has correct format', () {
        final presets = RenamePattern.getPredefinedPatterns();
        final movie = presets.firstWhere((p) => p.name == 'Movie');
        
        expect(movie.pattern, '{name} ({year})');
        expect(movie.description, isNotEmpty);
      });

      test('Anime preset has correct format', () {
        final presets = RenamePattern.getPredefinedPatterns();
        final anime = presets.firstWhere((p) => p.name == 'Anime');
        
        expect(anime.pattern, '{name} - {episode:3}');
        expect(anime.description, isNotEmpty);
      });

      test('Indexed preset has correct format', () {
        final presets = RenamePattern.getPredefinedPatterns();
        final indexed = presets.firstWhere((p) => p.name == 'Indexed');
        
        expect(indexed.pattern, '{name} - {index:3}');
        expect(indexed.description, isNotEmpty);
      });

      test('With Date preset has correct format', () {
        final presets = RenamePattern.getPredefinedPatterns();
        final withDate = presets.firstWhere((p) => p.name == 'With Date');
        
        expect(withDate.pattern, '{name} - {date}');
        expect(withDate.description, isNotEmpty);
      });
    });

    group('Variable Hints', () {
      test('Extract variables from pattern', () {
        final pattern1 = '{name} - S{season:2}E{episode:2}';
        final vars1 = RenameUtils.extractVariables(pattern1);
        
        expect(vars1, contains('name'));
        expect(vars1, contains('season'));
        expect(vars1, contains('episode'));
      });

      test('Extract variables with padding', () {
        final pattern = '{name} - {index:3}';
        final vars = RenameUtils.extractVariables(pattern);
        
        expect(vars, contains('name'));
        expect(vars, contains('index'));
      });

      test('Extract date variable', () {
        final pattern = '{name} - {date}';
        final vars = RenameUtils.extractVariables(pattern);
        
        expect(vars, contains('name'));
        expect(vars, contains('date'));
      });

      test('Extract year variable', () {
        final pattern = '{name} ({year})';
        final vars = RenameUtils.extractVariables(pattern);
        
        expect(vars, contains('name'));
        expect(vars, contains('year'));
      });
    });

    group('Pattern Validation', () {
      test('Valid patterns return no error', () {
        final validPatterns = [
          '{name}',
          '{name} - S{season:2}E{episode:2}',
          '{name} ({year})',
          '{name} - {episode:3}',
          '{name} - {index:3}',
          '{name} - {date}',
        ];

        for (final pattern in validPatterns) {
          final error = RenameUtils.validatePattern(pattern);
          expect(error, isNull, reason: 'Pattern "$pattern" should be valid');
        }
      });

      test('Invalid patterns return error', () {
        final invalidPatterns = [
          '{unknown}', // unknown variable
          '{name', // unclosed brace
          'name}', // unmatched closing brace
          '{name} - {', // incomplete variable
        ];

        for (final pattern in invalidPatterns) {
          final error = RenameUtils.validatePattern(pattern);
          expect(error, isNotNull, reason: 'Pattern "$pattern" should be invalid');
        }
      });

      test('Empty pattern returns error', () {
        final error = RenameUtils.validatePattern('');
        expect(error, isNotNull);
      });
    });

    group('Variable Substitution', () {
      test('Substitute name variable', () {
        final pattern = '{name}';
        final result = RenameUtils.applyPattern(
          pattern: pattern,
          originalBasename: 'test.mkv',
          index: 1,
        );
        
        expect(result, 'test');
      });

      test('Substitute episode with padding', () {
        final pattern = '{name} - {episode:3}';
        final result = RenameUtils.applyPattern(
          pattern: pattern,
          originalBasename: 'test.mkv',
          index: 1,
          episode: 5,
        );
        
        expect(result, contains('005'));
      });

      test('Substitute season and episode', () {
        final pattern = 'S{season:2}E{episode:2}';
        final result = RenameUtils.applyPattern(
          pattern: pattern,
          originalBasename: 'test.mkv',
          index: 1,
          season: 1,
          episode: 5,
        );
        
        expect(result, 'S01E05');
      });

      test('Substitute year', () {
        final pattern = '{name} ({year})';
        final result = RenameUtils.applyPattern(
          pattern: pattern,
          originalBasename: 'test.mkv',
          index: 1,
          year: 2024,
        );
        
        expect(result, contains('2024'));
      });

      test('Substitute date', () {
        final pattern = '{name} - {date}';
        final result = RenameUtils.applyPattern(
          pattern: pattern,
          originalBasename: 'test.mkv',
          index: 1,
        );
        
        // Should contain a date in YYYY-MM-DD format
        expect(result, matches(RegExp(r'\d{4}-\d{2}-\d{2}')));
      });

      test('Substitute index with padding', () {
        final pattern = '{name} - {index:3}';
        final result = RenameUtils.applyPattern(
          pattern: pattern,
          originalBasename: 'test.mkv',
          index: 5,
        );
        
        expect(result, contains('005'));
      });
    });
  });
}

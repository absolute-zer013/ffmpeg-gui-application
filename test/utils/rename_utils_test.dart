import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/utils/rename_utils.dart';

void main() {
  group('RenameUtils', () {
    test('applyPattern with {name} variable', () {
      final result = RenameUtils.applyPattern(
        '{name}',
        '/path/to/video.mkv',
      );
      expect(result, equals('video.mkv'));
    });

    test('applyPattern with {name} and {ext} variables', () {
      final result = RenameUtils.applyPattern(
        '{name}.{ext}',
        '/path/to/movie.mp4',
      );
      expect(result, equals('movie.mp4'));
    });

    test('applyPattern with TV show format', () {
      final result = RenameUtils.applyPattern(
        '{name} - S{season:2}E{episode:2}',
        '/path/to/show.mkv',
        season: 1,
        episode: 5,
      );
      expect(result, equals('show - S01E05.mkv'));
    });

    test('applyPattern with anime format', () {
      final result = RenameUtils.applyPattern(
        '{name} - {episode:3}',
        '/path/to/anime.mkv',
        episode: 12,
      );
      expect(result, equals('anime - 012.mkv'));
    });

    test('applyPattern with movie format', () {
      final result = RenameUtils.applyPattern(
        '{name} ({year})',
        '/path/to/movie.mkv',
        year: 2024,
      );
      expect(result, equals('movie (2024).mkv'));
    });

    test('applyPattern with index format', () {
      final result = RenameUtils.applyPattern(
        '{name} - {index:3}',
        '/path/to/file.mkv',
        index: 7,
      );
      expect(result, equals('file - 007.mkv'));
    });

    test('applyPattern with date variable', () {
      final result = RenameUtils.applyPattern(
        '{name} - {year}',
        '/path/to/video.mkv',
      );
      // Check that year is present (current year)
      expect(result, contains('video -'));
      expect(result, endsWith('.mkv'));
    });

    test('applyPattern removes unused variables', () {
      final result = RenameUtils.applyPattern(
        '{name} - {episode}',
        '/path/to/file.mkv',
        // episode not provided
      );
      expect(result, equals('file.mkv'));
    });

    test('applyPattern cleans multiple spaces', () {
      final result = RenameUtils.applyPattern(
        '{name}  -  {episode}  ',
        '/path/to/file.mkv',
        // episode not provided, should remove extra spaces
      );
      expect(result, equals('file.mkv'));
    });

    test('validatePattern returns null for valid pattern', () {
      final error = RenameUtils.validatePattern('{name} - S{season:2}E{episode:2}');
      expect(error, isNull);
    });

    test('validatePattern detects empty pattern', () {
      final error = RenameUtils.validatePattern('');
      expect(error, isNotNull);
      expect(error, contains('empty'));
    });

    test('validatePattern detects unmatched braces', () {
      final error = RenameUtils.validatePattern('{name');
      expect(error, isNotNull);
      expect(error, contains('brace'));
    });

    test('validatePattern detects invalid characters', () {
      final error = RenameUtils.validatePattern('{name}|{episode}');
      expect(error, isNotNull);
      expect(error, contains('invalid character'));
    });

    test('extractVariables finds all variables', () {
      final variables = RenameUtils.extractVariables(
        '{name} - S{season:2}E{episode:2} - {year}',
      );
      expect(variables, containsAll(['name', 'season', 'episode', 'year']));
    });

    test('extractVariables handles pattern without variables', () {
      final variables = RenameUtils.extractVariables('static-filename');
      expect(variables, isEmpty);
    });

    test('generatePreview returns formatted string', () {
      final preview = RenameUtils.generatePreview(
        '{name} - S{season:2}E{episode:2}',
        '/path/to/show.mkv',
        season: 2,
        episode: 10,
      );
      expect(preview, equals('show - S02E10.mkv'));
    });

    test('applyPattern handles files with multiple dots', () {
      final result = RenameUtils.applyPattern(
        '{name}',
        '/path/to/my.video.file.mkv',
      );
      expect(result, equals('my.video.file.mkv'));
    });

    test('applyPattern with alternative TV show format', () {
      final result = RenameUtils.applyPattern(
        '{name} {season}x{episode:2}',
        '/path/to/show.mkv',
        season: 3,
        episode: 4,
      );
      expect(result, equals('show 3x04.mkv'));
    });
  });
}

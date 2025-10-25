import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/file_item.dart';

void main() {
  group('Search and Filter Logic', () {
    late List<FileItem> testFiles;

    setUp(() {
      testFiles = [
        FileItem(
          path: '/path/to/file1.mkv',
          name: 'Movie 1.mkv',
          audioTracks: [],
          subtitleTracks: [],
          exportStatus: '',
        ),
        FileItem(
          path: '/path/to/file2.mkv',
          name: 'Movie 2.mkv',
          audioTracks: [],
          subtitleTracks: [],
          exportStatus: 'completed',
        ),
        FileItem(
          path: '/path/to/anime.mkv',
          name: 'Anime Episode.mkv',
          audioTracks: [],
          subtitleTracks: [],
          exportStatus: 'failed',
        ),
      ];
    });

    test('Filter by name matches correctly', () {
      final query = 'movie';
      final filtered = testFiles.where((file) {
        return file.name.toLowerCase().contains(query.toLowerCase());
      }).toList();

      expect(filtered.length, 2);
      expect(filtered[0].name, 'Movie 1.mkv');
      expect(filtered[1].name, 'Movie 2.mkv');
    });

    test('Filter by path matches correctly', () {
      final query = 'anime';
      final filtered = testFiles.where((file) {
        return file.path.toLowerCase().contains(query.toLowerCase()) ||
            file.name.toLowerCase().contains(query.toLowerCase());
      }).toList();

      expect(filtered.length, 1);
      expect(filtered[0].name, 'Anime Episode.mkv');
    });

    test('Filter by status - pending', () {
      final filtered = testFiles.where((file) {
        final status =
            file.exportStatus.isEmpty ? 'pending' : file.exportStatus;
        return status == 'pending';
      }).toList();

      expect(filtered.length, 1);
      expect(filtered[0].name, 'Movie 1.mkv');
    });

    test('Filter by status - completed', () {
      final filtered = testFiles.where((file) {
        final status =
            file.exportStatus.isEmpty ? 'pending' : file.exportStatus;
        return status == 'completed';
      }).toList();

      expect(filtered.length, 1);
      expect(filtered[0].name, 'Movie 2.mkv');
    });

    test('Filter by status - failed', () {
      final filtered = testFiles.where((file) {
        final status =
            file.exportStatus.isEmpty ? 'pending' : file.exportStatus;
        return status == 'failed';
      }).toList();

      expect(filtered.length, 1);
      expect(filtered[0].name, 'Anime Episode.mkv');
    });

    test('Combined filter - name and status', () {
      final query = 'movie';
      final statusFilter = 'completed';

      final filtered = testFiles.where((file) {
        // Name filter
        final matchesName =
            file.name.toLowerCase().contains(query.toLowerCase());
        if (!matchesName) return false;

        // Status filter
        final status =
            file.exportStatus.isEmpty ? 'pending' : file.exportStatus;
        return status == statusFilter;
      }).toList();

      expect(filtered.length, 1);
      expect(filtered[0].name, 'Movie 2.mkv');
    });

    test('No matches returns empty list', () {
      final query = 'nonexistent';
      final filtered = testFiles.where((file) {
        return file.name.toLowerCase().contains(query.toLowerCase());
      }).toList();

      expect(filtered.isEmpty, true);
    });

    test('Empty query returns all files', () {
      final query = '';
      final filtered = testFiles.where((file) {
        if (query.isEmpty) return true;
        return file.name.toLowerCase().contains(query.toLowerCase());
      }).toList();

      expect(filtered.length, testFiles.length);
    });
  });
}

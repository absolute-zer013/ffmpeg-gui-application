import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ffmpeg_filter_app/services/recent_files_service.dart';
import 'package:ffmpeg_filter_app/models/recent_file.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Clear shared preferences before each test
    SharedPreferences.setMockInitialValues({});
  });

  group('RecentFilesService', () {
    test('loadRecentFiles returns empty list initially', () async {
      final files = await RecentFilesService.loadRecentFiles();
      expect(files, isEmpty);
    });

    test('addRecentFile adds file to list', () async {
      await RecentFilesService.addRecentFile('/path/to/file1.mkv');
      final files = await RecentFilesService.loadRecentFiles();

      expect(files.length, 1);
      expect(files[0].path, '/path/to/file1.mkv');
    });

    test('addRecentFile adds multiple files in order', () async {
      await RecentFilesService.addRecentFile('/path/to/file1.mkv');
      await RecentFilesService.addRecentFile('/path/to/file2.mkv');
      await RecentFilesService.addRecentFile('/path/to/file3.mkv');

      final files = await RecentFilesService.loadRecentFiles();

      expect(files.length, 3);
      expect(files[0].path, '/path/to/file3.mkv'); // Most recent first
      expect(files[1].path, '/path/to/file2.mkv');
      expect(files[2].path, '/path/to/file1.mkv');
    });

    test('addRecentFile removes duplicate and re-adds to top', () async {
      await RecentFilesService.addRecentFile('/path/to/file1.mkv');
      await RecentFilesService.addRecentFile('/path/to/file2.mkv');
      await RecentFilesService.addRecentFile('/path/to/file1.mkv'); // Duplicate

      final files = await RecentFilesService.loadRecentFiles();

      expect(files.length, 2);
      expect(files[0].path, '/path/to/file1.mkv'); // Moved to top
      expect(files[1].path, '/path/to/file2.mkv');
    });

    test('addRecentFile limits to max files', () async {
      // Add 25 files (more than max of 20)
      for (int i = 0; i < 25; i++) {
        await RecentFilesService.addRecentFile('/path/to/file$i.mkv');
      }

      final files = await RecentFilesService.loadRecentFiles();

      expect(files.length, 20); // Should be limited to 20
      expect(files[0].path, '/path/to/file24.mkv'); // Most recent
      expect(files[19].path, '/path/to/file5.mkv'); // Oldest kept
    });

    test('removeRecentFile removes specific file', () async {
      await RecentFilesService.addRecentFile('/path/to/file1.mkv');
      await RecentFilesService.addRecentFile('/path/to/file2.mkv');
      await RecentFilesService.addRecentFile('/path/to/file3.mkv');

      await RecentFilesService.removeRecentFile('/path/to/file2.mkv');

      final files = await RecentFilesService.loadRecentFiles();

      expect(files.length, 2);
      expect(files.any((f) => f.path == '/path/to/file2.mkv'), false);
    });

    test('clearRecentFiles removes all files', () async {
      await RecentFilesService.addRecentFile('/path/to/file1.mkv');
      await RecentFilesService.addRecentFile('/path/to/file2.mkv');

      await RecentFilesService.clearRecentFiles();

      final files = await RecentFilesService.loadRecentFiles();
      expect(files, isEmpty);
    });

    test('RecentFile serialization works correctly', () {
      final now = DateTime.now();
      final file = RecentFile(path: '/path/to/file.mkv', processedAt: now);

      final json = file.toJson();
      expect(json['path'], '/path/to/file.mkv');
      expect(json['processedAt'], now.toIso8601String());

      final restored = RecentFile.fromJson(json);
      expect(restored.path, file.path);
      expect(restored.processedAt.toIso8601String(),
          file.processedAt.toIso8601String());
    });
  });
}

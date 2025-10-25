import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/services/watch_folder_service.dart';
import 'package:ffmpeg_filter_app/models/watch_folder_config.dart';

void main() {
  group('WatchFolderService', () {
    late WatchFolderService service;
    List<String> detectedFiles = [];
    List<String> errors = [];

    setUp(() {
      detectedFiles = [];
      errors = [];

      service = WatchFolderService(
        onFileDetected: (filePath) => detectedFiles.add(filePath),
        onError: (error) => errors.add(error),
      );
    });

    tearDown(() async {
      await service.dispose();
    });

    test('initializes with no active watcher', () {
      expect(service.isWatching, isFalse);
      expect(service.config, isNull);
    });

    test('stopWatching clears state', () async {
      await service.stopWatching();

      expect(service.isWatching, isFalse);
      expect(service.processedFiles, isEmpty);
    });

    test('clearProcessedFiles clears the processed files set', () {
      // Manually add to processed files (would normally be done by watcher)
      // Since _processedFiles is private, we test the public interface
      service.clearProcessedFiles();
      expect(service.processedFiles, isEmpty);
    });

    test('config is stored when watching starts', () async {
      final config = WatchFolderConfig(
        folderPath: '/test/path',
        enabled: false, // Disabled to prevent actual watching
      );

      await service.startWatching(config);

      // Config should be stored even if watching is disabled
      expect(service.config, equals(config));
    });

    test('does not watch when config is disabled', () async {
      final config = WatchFolderConfig(
        folderPath: '/test/path',
        enabled: false,
      );

      await service.startWatching(config);

      expect(service.isWatching, isFalse);
    });

    // Note: Testing actual file watching requires creating temp directories
    // and files, which is complex. The core logic tests are above.
    // Integration tests should be done separately for file watching.
  });

  group('WatchFolderConfig', () {
    test('creates with required fields', () {
      final config = WatchFolderConfig(
        folderPath: '/test/path',
      );

      expect(config.folderPath, equals('/test/path'));
      expect(config.enabled, isFalse);
      expect(config.autoAdd, isTrue);
      expect(config.autoExport, isFalse);
      expect(config.recursive, isFalse);
    });

    test('copyWith creates modified copy', () {
      final config = WatchFolderConfig(
        folderPath: '/test/path',
        enabled: false,
      );

      final modified = config.copyWith(enabled: true);

      expect(modified.folderPath, equals('/test/path'));
      expect(modified.enabled, isTrue);
    });

    test('toJson and fromJson round trip', () {
      final config = WatchFolderConfig(
        folderPath: '/test/path',
        enabled: true,
        filePatterns: ['*.mkv', '*.mp4'],
        autoAdd: true,
        autoExport: false,
        recursive: true,
      );

      final json = config.toJson();
      final reconstructed = WatchFolderConfig.fromJson(json);

      expect(reconstructed.folderPath, equals(config.folderPath));
      expect(reconstructed.enabled, equals(config.enabled));
      expect(reconstructed.filePatterns, equals(config.filePatterns));
      expect(reconstructed.autoAdd, equals(config.autoAdd));
      expect(reconstructed.autoExport, equals(config.autoExport));
      expect(reconstructed.recursive, equals(config.recursive));
    });

    test('equality works correctly', () {
      final config1 = WatchFolderConfig(
        folderPath: '/test/path',
        enabled: true,
      );

      final config2 = WatchFolderConfig(
        folderPath: '/test/path',
        enabled: true,
      );

      final config3 = WatchFolderConfig(
        folderPath: '/test/path',
        enabled: false,
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });
  });
}

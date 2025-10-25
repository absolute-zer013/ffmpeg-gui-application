import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/watch_folder_config.dart';
import 'package:ffmpeg_filter_app/models/export_profile.dart';

void main() {
  group('WatchFolderConfig', () {
    test('creates with required fields and defaults', () {
      final config = WatchFolderConfig(
        folderPath: '/test/path',
      );

      expect(config.folderPath, equals('/test/path'));
      expect(config.enabled, isFalse);
      expect(config.autoAdd, isTrue);
      expect(config.autoExport, isFalse);
      expect(config.recursive, isFalse);
      expect(config.filePatterns, equals(['*.mkv', '*.mp4']));
    });

    test('creates with custom values', () {
      final profile = ExportProfile(name: 'Test', removeEnglishAudio: true);
      final config = WatchFolderConfig(
        folderPath: '/test/path',
        enabled: true,
        filePatterns: ['*.avi'],
        autoAdd: false,
        autoExport: true,
        autoExportProfile: profile,
        recursive: true,
      );

      expect(config.enabled, isTrue);
      expect(config.filePatterns, equals(['*.avi']));
      expect(config.autoAdd, isFalse);
      expect(config.autoExport, isTrue);
      expect(config.autoExportProfile, equals(profile));
      expect(config.recursive, isTrue);
    });

    test('copyWith creates modified copy', () {
      final config = WatchFolderConfig(
        folderPath: '/test/path',
        enabled: false,
      );

      final modified = config.copyWith(enabled: true);

      expect(modified.enabled, isTrue);
      expect(modified.folderPath, equals('/test/path'));
    });

    test('toJson and fromJson work correctly', () {
      final config = WatchFolderConfig(
        folderPath: '/test/path',
        enabled: true,
        filePatterns: ['*.mkv'],
        autoAdd: true,
        autoExport: false,
        recursive: true,
      );

      final json = config.toJson();
      final restored = WatchFolderConfig.fromJson(json);

      expect(restored.folderPath, equals(config.folderPath));
      expect(restored.enabled, equals(config.enabled));
      expect(restored.filePatterns, equals(config.filePatterns));
      expect(restored.autoAdd, equals(config.autoAdd));
      expect(restored.autoExport, equals(config.autoExport));
      expect(restored.recursive, equals(config.recursive));
    });

    test('toJson and fromJson with profile', () {
      final profile = ExportProfile(name: 'Test', removeEnglishAudio: true);
      final config = WatchFolderConfig(
        folderPath: '/test/path',
        autoExportProfile: profile,
      );

      final json = config.toJson();
      final restored = WatchFolderConfig.fromJson(json);

      expect(restored.autoExportProfile?.name, equals('Test'));
      expect(restored.autoExportProfile?.removeEnglishAudio, isTrue);
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

    test('hashCode is consistent', () {
      final config1 = WatchFolderConfig(
        folderPath: '/test/path',
        enabled: true,
      );

      final config2 = WatchFolderConfig(
        folderPath: '/test/path',
        enabled: true,
      );

      expect(config1.hashCode, equals(config2.hashCode));
    });
  });
}

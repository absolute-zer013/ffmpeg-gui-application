import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/batch_configuration.dart';
import 'package:ffmpeg_filter_app/models/export_profile.dart';
import 'package:ffmpeg_filter_app/models/auto_detect_rule.dart';
import 'package:ffmpeg_filter_app/models/rename_pattern.dart';

void main() {
  group('BatchConfiguration Model', () {
    test('BatchConfiguration creation with all fields', () {
      final config = BatchConfiguration(
        id: 'config_1',
        name: 'Test Config',
        description: 'Test configuration',
        files: [],
        profiles: [],
        rules: [],
        outputFormat: 'mkv',
        maxConcurrentExports: 3,
        enableVerification: true,
      );

      expect(config.id, equals('config_1'));
      expect(config.name, equals('Test Config'));
      expect(config.description, equals('Test configuration'));
      expect(config.outputFormat, equals('mkv'));
      expect(config.maxConcurrentExports, equals(3));
      expect(config.enableVerification, isTrue);
    });

    test('BatchConfiguration with default values', () {
      final config = BatchConfiguration(
        id: 'config_2',
        name: 'Simple Config',
      );

      expect(config.description, isEmpty);
      expect(config.files, isEmpty);
      expect(config.profiles, isEmpty);
      expect(config.rules, isEmpty);
      expect(config.outputFormat, equals('mkv'));
      expect(config.maxConcurrentExports, equals(2));
      expect(config.enableVerification, isTrue);
    });

    test('BatchConfiguration toJson/fromJson roundtrip', () {
      final original = BatchConfiguration(
        id: 'config_3',
        name: 'Test Config',
        description: 'Test description',
        outputFormat: 'mp4',
        maxConcurrentExports: 4,
        enableVerification: false,
      );

      final json = original.toJson();
      final decoded = BatchConfiguration.fromJson(json);

      expect(decoded.id, equals(original.id));
      expect(decoded.name, equals(original.name));
      expect(decoded.description, equals(original.description));
      expect(decoded.outputFormat, equals(original.outputFormat));
      expect(
          decoded.maxConcurrentExports, equals(original.maxConcurrentExports));
      expect(decoded.enableVerification, equals(original.enableVerification));
    });

    test('BatchConfiguration with profiles', () {
      final profile = ExportProfile(
        id: 'profile_1',
        name: 'Test Profile',
        selectedAudioLanguages: {'eng'},
        selectedSubtitleDescriptions: {'English'},
      );

      final config = BatchConfiguration(
        id: 'config_4',
        name: 'Config with Profile',
        profiles: [profile],
      );

      expect(config.profiles, hasLength(1));
      expect(config.profiles.first.id, equals('profile_1'));
    });

    test('BatchConfiguration with rules', () {
      final rule = AutoDetectRule(
        id: 'rule_1',
        name: 'Test Rule',
        type: RuleType.audio,
        condition: RuleCondition.languageEquals,
        conditionValue: 'jpn',
        action: RuleAction.select,
      );

      final config = BatchConfiguration(
        id: 'config_5',
        name: 'Config with Rule',
        rules: [rule],
      );

      expect(config.rules, hasLength(1));
      expect(config.rules.first.id, equals('rule_1'));
    });

    test('BatchConfiguration with rename pattern', () {
      final pattern = RenamePattern(
        name: 'TV Show',
        pattern: '{name} - S{season:2}E{episode:2}',
      );

      final config = BatchConfiguration(
        id: 'config_6',
        name: 'Config with Pattern',
        defaultRenamePattern: pattern,
      );

      expect(config.defaultRenamePattern, isNotNull);
      expect(config.defaultRenamePattern!.name, equals('TV Show'));
    });

    test('BatchConfiguration copyWith creates modified copy', () {
      final original = BatchConfiguration(
        id: 'config_7',
        name: 'Original',
        description: 'Original description',
        maxConcurrentExports: 2,
      );

      final modified = original.copyWith(
        name: 'Modified',
        maxConcurrentExports: 5,
      );

      expect(modified.name, equals('Modified'));
      expect(modified.maxConcurrentExports, equals(5));
      expect(modified.description, equals(original.description));
      expect(modified.id, equals(original.id));
    });

    test('BatchConfiguration toJson includes version', () {
      final config = BatchConfiguration(
        id: 'config_8',
        name: 'Test',
      );

      final json = config.toJson();
      expect(json['version'], isNotNull);
      expect(json['appName'], isNotNull);
    });
  });

  group('FileConfiguration Model', () {
    test('FileConfiguration creation with all fields', () {
      final fileConfig = FileConfiguration(
        path: '/path/to/file.mkv',
        outputName: 'output.mkv',
        selectedVideoTracks: {0},
        selectedAudioTracks: {0, 1},
        selectedSubtitleTracks: {0},
        defaultAudio: 0,
        defaultSubtitle: 0,
        renameIndex: 1,
        renameEpisode: 5,
        renameSeason: 2,
      );

      expect(fileConfig.path, equals('/path/to/file.mkv'));
      expect(fileConfig.outputName, equals('output.mkv'));
      expect(fileConfig.selectedVideoTracks, equals({0}));
      expect(fileConfig.selectedAudioTracks, equals({0, 1}));
      expect(fileConfig.selectedSubtitleTracks, equals({0}));
      expect(fileConfig.defaultAudio, equals(0));
      expect(fileConfig.defaultSubtitle, equals(0));
      expect(fileConfig.renameIndex, equals(1));
      expect(fileConfig.renameEpisode, equals(5));
      expect(fileConfig.renameSeason, equals(2));
    });

    test('FileConfiguration with default values', () {
      final fileConfig = FileConfiguration(
        path: '/path/to/file.mkv',
      );

      expect(fileConfig.selectedVideoTracks, isEmpty);
      expect(fileConfig.selectedAudioTracks, isEmpty);
      expect(fileConfig.selectedSubtitleTracks, isEmpty);
      expect(fileConfig.outputName, isNull);
      expect(fileConfig.defaultAudio, isNull);
    });

    test('FileConfiguration toJson/fromJson roundtrip', () {
      final original = FileConfiguration(
        path: '/path/to/file.mkv',
        outputName: 'output.mkv',
        selectedAudioTracks: {0, 1},
        defaultAudio: 0,
        renameEpisode: 10,
      );

      final json = original.toJson();
      final decoded = FileConfiguration.fromJson(json);

      expect(decoded.path, equals(original.path));
      expect(decoded.outputName, equals(original.outputName));
      expect(decoded.selectedAudioTracks, equals(original.selectedAudioTracks));
      expect(decoded.defaultAudio, equals(original.defaultAudio));
      expect(decoded.renameEpisode, equals(original.renameEpisode));
    });

    test('FileConfiguration with rename pattern', () {
      final pattern = RenamePattern(
        name: 'Anime',
        pattern: '{name} - {episode:3}',
      );

      final fileConfig = FileConfiguration(
        path: '/path/to/file.mkv',
        renamePattern: pattern,
        renameEpisode: 12,
      );

      expect(fileConfig.renamePattern, isNotNull);
      expect(fileConfig.renamePattern!.name, equals('Anime'));
      expect(fileConfig.renameEpisode, equals(12));
    });
  });
}

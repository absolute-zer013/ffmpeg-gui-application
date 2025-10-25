import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/external_preset.dart';

void main() {
  group('ExternalPreset', () {
    test('creates instance with required fields', () {
      final preset = ExternalPreset(
        name: 'Test Preset',
        source: 'HandBrake',
        rawData: {'key': 'value'},
      );

      expect(preset.name, 'Test Preset');
      expect(preset.source, 'HandBrake');
      expect(preset.description, isNull);
      expect(preset.category, isNull);
      expect(preset.mapping, isNull);
    });

    test('creates instance with all fields', () {
      const mapping = PresetMapping(
        videoCodec: 'h264',
        audioCodec: 'aac',
      );

      final preset = ExternalPreset(
        name: 'Test Preset',
        description: 'A test preset',
        source: 'HandBrake',
        category: 'General',
        rawData: {'key': 'value'},
        mapping: mapping,
      );

      expect(preset.name, 'Test Preset');
      expect(preset.description, 'A test preset');
      expect(preset.source, 'HandBrake');
      expect(preset.category, 'General');
      expect(preset.mapping, mapping);
    });

    test('copyWith creates new instance with updated values', () {
      final preset = ExternalPreset(
        name: 'Original',
        source: 'HandBrake',
        rawData: {},
      );

      final updated = preset.copyWith(name: 'Updated');

      expect(updated.name, 'Updated');
      expect(updated.source, 'HandBrake');
    });

    test('toJson serializes correctly', () {
      const mapping = PresetMapping(videoCodec: 'h264');
      final preset = ExternalPreset(
        name: 'Test',
        description: 'Desc',
        source: 'HandBrake',
        category: 'General',
        rawData: {'key': 'value'},
        mapping: mapping,
      );

      final json = preset.toJson();

      expect(json['name'], 'Test');
      expect(json['description'], 'Desc');
      expect(json['source'], 'HandBrake');
      expect(json['category'], 'General');
      expect(json['mapping'], isNotNull);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'name': 'Test',
        'description': 'Desc',
        'source': 'HandBrake',
        'category': 'General',
        'rawData': {'key': 'value'},
        'mapping': {
          'videoCodec': 'h264',
          'isCompatible': true,
        },
      };

      final preset = ExternalPreset.fromJson(json);

      expect(preset.name, 'Test');
      expect(preset.description, 'Desc');
      expect(preset.source, 'HandBrake');
      expect(preset.category, 'General');
      expect(preset.mapping, isNotNull);
    });
  });

  group('PresetMapping', () {
    test('creates instance with default values', () {
      const mapping = PresetMapping();

      expect(mapping.videoCodec, isNull);
      expect(mapping.audioCodec, isNull);
      expect(mapping.additionalArgs, isEmpty);
      expect(mapping.warnings, isEmpty);
      expect(mapping.isCompatible, true);
    });

    test('creates instance with custom values', () {
      const mapping = PresetMapping(
        videoCodec: 'h264',
        audioCodec: 'aac',
        videoQuality: 'CRF 23',
        audioBitrate: '192k',
        audioSampleRate: 48000,
        audioChannels: 2,
        resolution: '1920x1080',
        frameRate: '30',
        format: 'mkv',
        additionalArgs: ['-preset', 'fast'],
        warnings: ['Warning 1'],
        isCompatible: false,
      );

      expect(mapping.videoCodec, 'h264');
      expect(mapping.audioCodec, 'aac');
      expect(mapping.videoQuality, 'CRF 23');
      expect(mapping.audioBitrate, '192k');
      expect(mapping.audioSampleRate, 48000);
      expect(mapping.audioChannels, 2);
      expect(mapping.resolution, '1920x1080');
      expect(mapping.frameRate, '30');
      expect(mapping.format, 'mkv');
      expect(mapping.additionalArgs, ['-preset', 'fast']);
      expect(mapping.warnings, ['Warning 1']);
      expect(mapping.isCompatible, false);
    });

    test('copyWith creates new instance with updated values', () {
      const mapping = PresetMapping(videoCodec: 'h264');

      final updated = mapping.copyWith(audioCodec: 'aac');

      expect(updated.videoCodec, 'h264');
      expect(updated.audioCodec, 'aac');
    });

    test('toJson serializes correctly', () {
      const mapping = PresetMapping(
        videoCodec: 'h264',
        audioCodec: 'aac',
        additionalArgs: ['-preset', 'fast'],
        warnings: ['Warning'],
        isCompatible: true,
      );

      final json = mapping.toJson();

      expect(json['videoCodec'], 'h264');
      expect(json['audioCodec'], 'aac');
      expect(json['additionalArgs'], ['-preset', 'fast']);
      expect(json['warnings'], ['Warning']);
      expect(json['isCompatible'], true);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'videoCodec': 'h264',
        'audioCodec': 'aac',
        'videoQuality': 'CRF 23',
        'audioBitrate': '192k',
        'audioSampleRate': 48000,
        'audioChannels': 2,
        'resolution': '1920x1080',
        'frameRate': '30',
        'format': 'mkv',
        'additionalArgs': ['-preset', 'fast'],
        'warnings': ['Warning'],
        'isCompatible': false,
      };

      final mapping = PresetMapping.fromJson(json);

      expect(mapping.videoCodec, 'h264');
      expect(mapping.audioCodec, 'aac');
      expect(mapping.videoQuality, 'CRF 23');
      expect(mapping.audioBitrate, '192k');
      expect(mapping.audioSampleRate, 48000);
      expect(mapping.audioChannels, 2);
      expect(mapping.resolution, '1920x1080');
      expect(mapping.frameRate, '30');
      expect(mapping.format, 'mkv');
      expect(mapping.additionalArgs, ['-preset', 'fast']);
      expect(mapping.warnings, ['Warning']);
      expect(mapping.isCompatible, false);
    });

    test('fromJson handles missing values', () {
      final json = <String, dynamic>{};

      final mapping = PresetMapping.fromJson(json);

      expect(mapping.videoCodec, isNull);
      expect(mapping.additionalArgs, isEmpty);
      expect(mapping.warnings, isEmpty);
      expect(mapping.isCompatible, true);
    });

    test('getSummary returns correct string', () {
      const mapping = PresetMapping(
        videoCodec: 'h264',
        audioCodec: 'aac',
        videoQuality: 'CRF 23',
        resolution: '1920x1080',
      );

      final summary = mapping.getSummary();

      expect(summary, contains('Video: h264'));
      expect(summary, contains('Audio: aac'));
      expect(summary, contains('Quality: CRF 23'));
      expect(summary, contains('Resolution: 1920x1080'));
    });

    test('getSummary handles empty mapping', () {
      const mapping = PresetMapping();

      final summary = mapping.getSummary();

      expect(summary, 'No mapping');
    });

    test('roundtrip serialization preserves data', () {
      const original = PresetMapping(
        videoCodec: 'h264',
        audioCodec: 'aac',
        videoQuality: 'CRF 23',
        additionalArgs: ['-preset', 'fast'],
        warnings: ['Warning'],
        isCompatible: true,
      );

      final json = original.toJson();
      final restored = PresetMapping.fromJson(json);

      expect(restored.videoCodec, original.videoCodec);
      expect(restored.audioCodec, original.audioCodec);
      expect(restored.videoQuality, original.videoQuality);
      expect(restored.additionalArgs, original.additionalArgs);
      expect(restored.warnings, original.warnings);
      expect(restored.isCompatible, original.isCompatible);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/resolution_settings.dart';

void main() {
  group('ResolutionSettings', () {
    test('creates default disabled settings', () {
      const settings = ResolutionSettings();
      expect(settings.enabled, false);
      expect(settings.width, null);
      expect(settings.height, null);
      expect(settings.framerate, null);
    });

    test('creates settings with width and height', () {
      const settings = ResolutionSettings(
        width: 1920,
        height: 1080,
        enabled: true,
      );

      expect(settings.width, 1920);
      expect(settings.height, 1080);
      expect(settings.enabled, true);
    });

    test('provides common presets', () {
      expect(ResolutionSettings.presets.containsKey('4K (3840x2160)'), true);
      expect(ResolutionSettings.presets.containsKey('1080p (1920x1080)'), true);
      expect(ResolutionSettings.presets.containsKey('720p (1280x720)'), true);
      expect(ResolutionSettings.presets.containsKey('480p (854x480)'), true);
      expect(ResolutionSettings.presets.containsKey('360p (640x360)'), true);

      final preset1080p = ResolutionSettings.presets['1080p (1920x1080)'];
      expect(preset1080p?.width, 1920);
      expect(preset1080p?.height, 1080);
      expect(preset1080p?.enabled, true);
    });

    test('generates correct scale filter for both dimensions', () {
      const settings = ResolutionSettings(
        width: 1920,
        height: 1080,
        enabled: true,
      );

      expect(settings.scaleFilter, 'scale=1920:1080');
    });

    test('generates correct scale filter for width only', () {
      const settings = ResolutionSettings(
        width: 1920,
        enabled: true,
      );

      expect(settings.scaleFilter, 'scale=1920:-2');
    });

    test('generates correct scale filter for height only', () {
      const settings = ResolutionSettings(
        height: 1080,
        enabled: true,
      );

      expect(settings.scaleFilter, 'scale=-2:1080');
    });

    test('returns null scale filter when disabled', () {
      const settings = ResolutionSettings(
        width: 1920,
        height: 1080,
        enabled: false,
      );

      expect(settings.scaleFilter, null);
    });

    test('returns null scale filter when no dimensions set', () {
      const settings = ResolutionSettings(enabled: true);

      expect(settings.scaleFilter, null);
    });

    test('estimates size multiplier correctly for downscaling', () {
      const settings = ResolutionSettings(
        width: 1280,
        height: 720,
        enabled: true,
      );

      // Original: 1920x1080 (2073600 pixels)
      // Target: 1280x720 (921600 pixels)
      // Ratio: 921600 / 2073600 = ~0.444 * 1.1 overhead = ~0.49
      final multiplier = settings.estimateSizeMultiplier(1920, 1080);
      expect(multiplier, greaterThan(0.4));
      expect(multiplier, lessThan(0.6));
    });

    test('estimates size multiplier as ~1.0 for same resolution', () {
      const settings = ResolutionSettings(
        width: 1920,
        height: 1080,
        enabled: true,
      );

      final multiplier = settings.estimateSizeMultiplier(1920, 1080);
      expect(multiplier, closeTo(1.1, 0.01)); // 1.0 * 1.1 overhead
    });

    test('estimates size multiplier correctly for upscaling', () {
      const settings = ResolutionSettings(
        width: 3840,
        height: 2160,
        enabled: true,
      );

      // Original: 1920x1080 (2073600 pixels)
      // Target: 3840x2160 (8294400 pixels)
      // Ratio: 8294400 / 2073600 = 4.0 * 1.1 overhead = 4.4
      final multiplier = settings.estimateSizeMultiplier(1920, 1080);
      expect(multiplier, greaterThan(4.0));
      expect(multiplier, lessThan(5.0));
    });

    test('provides common framerate options', () {
      expect(ResolutionSettings.framerateOptions, contains(23.976));
      expect(ResolutionSettings.framerateOptions, contains(24.0));
      expect(ResolutionSettings.framerateOptions, contains(25.0));
      expect(ResolutionSettings.framerateOptions, contains(29.97));
      expect(ResolutionSettings.framerateOptions, contains(30.0));
      expect(ResolutionSettings.framerateOptions, contains(50.0));
      expect(ResolutionSettings.framerateOptions, contains(59.94));
      expect(ResolutionSettings.framerateOptions, contains(60.0));
    });

    test('copyWith creates new instance with updated values', () {
      const original = ResolutionSettings(
        width: 1920,
        height: 1080,
        framerate: 30.0,
        enabled: true,
      );

      final updated = original.copyWith(framerate: 60.0);

      expect(updated.width, 1920);
      expect(updated.height, 1080);
      expect(updated.framerate, 60.0);
      expect(updated.enabled, true);
    });

    test('toJson and fromJson work correctly', () {
      const original = ResolutionSettings(
        width: 1920,
        height: 1080,
        framerate: 30.0,
        presetName: '1080p',
        enabled: true,
      );

      final json = original.toJson();
      final restored = ResolutionSettings.fromJson(json);

      expect(restored.width, original.width);
      expect(restored.height, original.height);
      expect(restored.framerate, original.framerate);
      expect(restored.presetName, original.presetName);
      expect(restored.enabled, original.enabled);
    });

    test('toString provides useful description', () {
      const disabled = ResolutionSettings();
      expect(disabled.toString(), 'Resolution: Original');

      const withResolution = ResolutionSettings(
        width: 1920,
        height: 1080,
        enabled: true,
      );
      expect(withResolution.toString(), contains('1920x1080'));

      const withFramerate = ResolutionSettings(
        framerate: 60.0,
        enabled: true,
      );
      expect(withFramerate.toString(), contains('60.0fps'));

      const withPreset = ResolutionSettings(
        width: 1920,
        height: 1080,
        presetName: '1080p',
        enabled: true,
      );
      expect(withPreset.toString(), contains('(1080p)'));
    });
  });
}

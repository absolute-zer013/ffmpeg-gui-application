import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/trim_settings.dart';

void main() {
  group('TrimSettings', () {
    test('creates default disabled settings', () {
      const settings = TrimSettings();
      expect(settings.enabled, false);
      expect(settings.startTime, null);
      expect(settings.endTime, null);
    });

    test('parses time string in HH:MM:SS format', () {
      final settings = TrimSettings.fromTimeStrings(
        startTimeStr: '01:30:45',
        endTimeStr: '02:15:30',
        enabled: true,
      );

      expect(settings.enabled, true);
      expect(settings.startTime, 5445.0); // 1*3600 + 30*60 + 45
      expect(settings.endTime, 8130.0); // 2*3600 + 15*60 + 30
    });

    test('parses time string in MM:SS format', () {
      final settings = TrimSettings.fromTimeStrings(
        startTimeStr: '5:30',
        endTimeStr: '10:45',
        enabled: true,
      );

      expect(settings.startTime, 330.0); // 5*60 + 30
      expect(settings.endTime, 645.0); // 10*60 + 45
    });

    test('parses time string in SS format', () {
      final settings = TrimSettings.fromTimeStrings(
        startTimeStr: '90',
        endTimeStr: '180',
        enabled: true,
      );

      expect(settings.startTime, 90.0);
      expect(settings.endTime, 180.0);
    });

    test('handles decimal seconds', () {
      final settings = TrimSettings.fromTimeStrings(
        startTimeStr: '1:30:45.5',
        enabled: true,
      );

      expect(settings.startTime, 5445.5);
    });

    test('returns null for empty or invalid time strings', () {
      final settings = TrimSettings.fromTimeStrings(
        startTimeStr: '',
        endTimeStr: 'invalid',
        enabled: true,
      );

      expect(settings.startTime, null);
      expect(settings.endTime, null);
    });

    test('validates that end time is after start time', () {
      final validSettings = TrimSettings(
        startTime: 100.0,
        endTime: 200.0,
        enabled: true,
      );
      expect(validSettings.isValid, true);

      final invalidSettings = TrimSettings(
        startTime: 200.0,
        endTime: 100.0,
        enabled: true,
      );
      expect(invalidSettings.isValid, false);
    });

    test('validates when disabled', () {
      const settings = TrimSettings(
        startTime: 200.0,
        endTime: 100.0, // Invalid but disabled
        enabled: false,
      );
      expect(settings.isValid, true);
    });

    test('calculates duration correctly', () {
      const settings = TrimSettings(
        startTime: 100.0,
        endTime: 250.0,
        enabled: true,
      );

      expect(settings.duration, 150.0);
    });

    test('duration is null when times are invalid', () {
      const settings1 = TrimSettings(
        startTime: 200.0,
        endTime: 100.0,
        enabled: true,
      );
      expect(settings1.duration, null);

      const settings2 = TrimSettings(
        startTime: null,
        endTime: 100.0,
        enabled: true,
      );
      expect(settings2.duration, null);
    });

    test('formats time correctly', () {
      expect(TrimSettings.formatTime(90.0), '01:30');
      expect(TrimSettings.formatTime(5445.0), '01:30:45');
      expect(TrimSettings.formatTime(5445.5), '01:30:45.50');
      expect(TrimSettings.formatTime(3661.0), '01:01:01');
    });

    test('copyWith creates new instance with updated values', () {
      const original = TrimSettings(
        startTime: 100.0,
        endTime: 200.0,
        enabled: true,
      );

      final updated = original.copyWith(endTime: 300.0);

      expect(updated.startTime, 100.0);
      expect(updated.endTime, 300.0);
      expect(updated.enabled, true);
    });

    test('toJson and fromJson work correctly', () {
      const original = TrimSettings(
        startTime: 100.0,
        endTime: 200.0,
        enabled: true,
      );

      final json = original.toJson();
      final restored = TrimSettings.fromJson(json);

      expect(restored.startTime, original.startTime);
      expect(restored.endTime, original.endTime);
      expect(restored.enabled, original.enabled);
    });

    test('toString provides useful description', () {
      const disabled = TrimSettings();
      expect(disabled.toString(), 'Trim: Disabled');

      const enabled = TrimSettings(
        startTime: 90.0,
        endTime: 180.0,
        enabled: true,
      );
      expect(enabled.toString(), contains('Trim:'));
      expect(enabled.toString(), contains('01:30'));
      expect(enabled.toString(), contains('03:00'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/dual_pane_mode.dart';

void main() {
  group('DualPaneMode', () {
    test('creates instance with default values', () {
      const mode = DualPaneMode();

      expect(mode.enabled, false);
      expect(mode.orientation, DualPaneOrientation.horizontal);
      expect(mode.dividerPosition, 0.5);
      expect(mode.leftPaneFilePath, isNull);
      expect(mode.rightPaneFilePath, isNull);
      expect(mode.showDifferences, false);
    });

    test('creates instance with custom values', () {
      const mode = DualPaneMode(
        enabled: true,
        orientation: DualPaneOrientation.vertical,
        dividerPosition: 0.7,
        leftPaneFilePath: '/path/to/file1.mkv',
        rightPaneFilePath: '/path/to/file2.mkv',
        showDifferences: true,
      );

      expect(mode.enabled, true);
      expect(mode.orientation, DualPaneOrientation.vertical);
      expect(mode.dividerPosition, 0.7);
      expect(mode.leftPaneFilePath, '/path/to/file1.mkv');
      expect(mode.rightPaneFilePath, '/path/to/file2.mkv');
      expect(mode.showDifferences, true);
    });

    test('copyWith returns new instance with updated values', () {
      const mode = DualPaneMode(enabled: false, dividerPosition: 0.5);

      final updated = mode.copyWith(
        enabled: true,
        dividerPosition: 0.6,
      );

      expect(updated.enabled, true);
      expect(updated.dividerPosition, 0.6);
      expect(updated.orientation, mode.orientation);
    });

    test('copyWith preserves unchanged values', () {
      const mode = DualPaneMode(
        enabled: true,
        leftPaneFilePath: '/path/to/file.mkv',
      );

      final updated = mode.copyWith(dividerPosition: 0.7);

      expect(updated.enabled, true);
      expect(updated.leftPaneFilePath, '/path/to/file.mkv');
      expect(updated.dividerPosition, 0.7);
    });

    test('toJson serializes correctly', () {
      const mode = DualPaneMode(
        enabled: true,
        orientation: DualPaneOrientation.vertical,
        dividerPosition: 0.6,
        leftPaneFilePath: '/path/to/file1.mkv',
        rightPaneFilePath: '/path/to/file2.mkv',
        showDifferences: true,
      );

      final json = mode.toJson();

      expect(json['enabled'], true);
      expect(json['orientation'], 'vertical');
      expect(json['dividerPosition'], 0.6);
      expect(json['leftPaneFilePath'], '/path/to/file1.mkv');
      expect(json['rightPaneFilePath'], '/path/to/file2.mkv');
      expect(json['showDifferences'], true);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'enabled': true,
        'orientation': 'vertical',
        'dividerPosition': 0.6,
        'leftPaneFilePath': '/path/to/file1.mkv',
        'rightPaneFilePath': '/path/to/file2.mkv',
        'showDifferences': true,
      };

      final mode = DualPaneMode.fromJson(json);

      expect(mode.enabled, true);
      expect(mode.orientation, DualPaneOrientation.vertical);
      expect(mode.dividerPosition, 0.6);
      expect(mode.leftPaneFilePath, '/path/to/file1.mkv');
      expect(mode.rightPaneFilePath, '/path/to/file2.mkv');
      expect(mode.showDifferences, true);
    });

    test('fromJson handles missing values with defaults', () {
      final json = <String, dynamic>{};

      final mode = DualPaneMode.fromJson(json);

      expect(mode.enabled, false);
      expect(mode.orientation, DualPaneOrientation.horizontal);
      expect(mode.dividerPosition, 0.5);
      expect(mode.leftPaneFilePath, isNull);
      expect(mode.rightPaneFilePath, isNull);
      expect(mode.showDifferences, false);
    });

    test('fromJson handles invalid orientation', () {
      final json = {
        'orientation': 'invalid',
      };

      final mode = DualPaneMode.fromJson(json);

      expect(mode.orientation, DualPaneOrientation.horizontal);
    });

    test('roundtrip serialization preserves data', () {
      const original = DualPaneMode(
        enabled: true,
        orientation: DualPaneOrientation.vertical,
        dividerPosition: 0.75,
        leftPaneFilePath: '/path/to/file1.mkv',
        rightPaneFilePath: '/path/to/file2.mkv',
        showDifferences: true,
      );

      final json = original.toJson();
      final restored = DualPaneMode.fromJson(json);

      expect(restored.enabled, original.enabled);
      expect(restored.orientation, original.orientation);
      expect(restored.dividerPosition, original.dividerPosition);
      expect(restored.leftPaneFilePath, original.leftPaneFilePath);
      expect(restored.rightPaneFilePath, original.rightPaneFilePath);
      expect(restored.showDifferences, original.showDifferences);
    });
  });

  group('DualPaneOrientation', () {
    test('has correct values', () {
      expect(DualPaneOrientation.values.length, 2);
      expect(
          DualPaneOrientation.values, contains(DualPaneOrientation.horizontal));
      expect(
          DualPaneOrientation.values, contains(DualPaneOrientation.vertical));
    });
  });
}

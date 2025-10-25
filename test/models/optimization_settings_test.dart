import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/optimization_settings.dart';

void main() {
  group('OptimizationSettings', () {
    test('creates with default values', () {
      const settings = OptimizationSettings();

      expect(settings.reorderStreams, isTrue);
      expect(settings.removeMetadata, isFalse);
      expect(settings.optimizeHeader, isTrue);
      expect(
          settings.reorderPolicy, equals(StreamReorderPolicy.typeBasedDefault));
    });

    test('copyWith creates modified copy', () {
      const settings = OptimizationSettings();
      final modified = settings.copyWith(removeMetadata: true);

      expect(modified.removeMetadata, isTrue);
      expect(modified.reorderStreams, equals(settings.reorderStreams));
    });

    test('toJson and fromJson work correctly', () {
      const settings = OptimizationSettings(
        reorderStreams: false,
        removeMetadata: true,
        optimizeHeader: false,
        reorderPolicy: StreamReorderPolicy.keepOriginal,
      );

      final json = settings.toJson();
      final restored = OptimizationSettings.fromJson(json);

      expect(restored.reorderStreams, equals(settings.reorderStreams));
      expect(restored.removeMetadata, equals(settings.removeMetadata));
      expect(restored.optimizeHeader, equals(settings.optimizeHeader));
      expect(restored.reorderPolicy, equals(settings.reorderPolicy));
    });
  });

  group('OptimizationResult', () {
    test('calculates size savings correctly', () {
      const result = OptimizationResult(
        originalSize: 1000000,
        optimizedSize: 900000,
        durationMs: 5000,
      );

      expect(result.sizeSavings, equals(100000));
      expect(result.savingsPercentage, equals(10.0));
      expect(result.isSuccess, isTrue);
    });

    test('formats sizes correctly', () {
      expect(OptimizationResult.formatSize(500), equals('500 B'));
      expect(OptimizationResult.formatSize(1024), equals('1.00 KB'));
      expect(OptimizationResult.formatSize(1048576), equals('1.00 MB'));
      expect(OptimizationResult.formatSize(1073741824), equals('1.00 GB'));
    });

    test('handles zero original size', () {
      const result = OptimizationResult(
        originalSize: 0,
        optimizedSize: 0,
        durationMs: 1000,
      );

      expect(result.savingsPercentage, equals(0.0));
    });

    test('isSuccess returns false when error is present', () {
      const result = OptimizationResult(
        originalSize: 1000000,
        optimizedSize: 1000000,
        error: 'Test error',
        durationMs: 1000,
      );

      expect(result.isSuccess, isFalse);
    });
  });

  group('StreamReorderPolicy', () {
    test('has correct display names', () {
      expect(
        StreamReorderPolicy.keepOriginal.displayName,
        equals('Keep Original Order'),
      );
      expect(
        StreamReorderPolicy.typeBasedDefault.displayName,
        equals('Type-Based (Default First)'),
      );
      expect(
        StreamReorderPolicy.typeBasedOriginal.displayName,
        equals('Type-Based (Original Order)'),
      );
    });

    test('has descriptions', () {
      for (final policy in StreamReorderPolicy.values) {
        expect(policy.description, isNotEmpty);
      }
    });
  });
}

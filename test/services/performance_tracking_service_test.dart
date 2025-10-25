import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/services/performance_tracking_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Clear shared preferences before each test
    SharedPreferences.setMockInitialValues({});
  });

  group('PerformanceMetrics', () {
    test('creates metric with all required fields', () {
      final now = DateTime.now();
      final metric = PerformanceMetrics(
        speedMBps: 10.5,
        timestamp: now,
        fileSizeBytes: 1000000,
        durationSeconds: 95.24,
      );

      expect(metric.speedMBps, 10.5);
      expect(metric.timestamp, now);
      expect(metric.fileSizeBytes, 1000000);
      expect(metric.durationSeconds, 95.24);
    });

    test('toJson and fromJson work correctly', () {
      final now = DateTime.now();
      final original = PerformanceMetrics(
        speedMBps: 10.5,
        timestamp: now,
        fileSizeBytes: 1000000,
        durationSeconds: 95.24,
      );

      final json = original.toJson();
      final restored = PerformanceMetrics.fromJson(json);

      expect(restored.speedMBps, original.speedMBps);
      expect(restored.timestamp.toString(), original.timestamp.toString());
      expect(restored.fileSizeBytes, original.fileSizeBytes);
      expect(restored.durationSeconds, original.durationSeconds);
    });
  });

  group('PerformanceTrackingService', () {
    test('records export performance', () async {
      await PerformanceTrackingService.recordExport(
        fileSizeBytes: 10485760, // 10 MB
        durationSeconds: 10.0, // 10 seconds
      );

      final avgSpeed = await PerformanceTrackingService.getAverageSpeed();
      expect(avgSpeed, isNotNull);
      expect(avgSpeed, greaterThan(0));
      // 10 MB / 10 seconds = 1 MB/s
      expect(avgSpeed, closeTo(1.0, 0.01));
    });

    test('ignores invalid export data', () async {
      await PerformanceTrackingService.recordExport(
        fileSizeBytes: 0,
        durationSeconds: 10.0,
      );

      await PerformanceTrackingService.recordExport(
        fileSizeBytes: 1000,
        durationSeconds: 0,
      );

      final avgSpeed = await PerformanceTrackingService.getAverageSpeed();
      expect(avgSpeed, isNull);
    });

    test('calculates average speed from multiple exports', () async {
      // Record 3 exports
      await PerformanceTrackingService.recordExport(
        fileSizeBytes: 10485760, // 10 MB
        durationSeconds: 10.0, // 1 MB/s
      );

      await PerformanceTrackingService.recordExport(
        fileSizeBytes: 20971520, // 20 MB
        durationSeconds: 10.0, // 2 MB/s
      );

      await PerformanceTrackingService.recordExport(
        fileSizeBytes: 31457280, // 30 MB
        durationSeconds: 10.0, // 3 MB/s
      );

      final avgSpeed = await PerformanceTrackingService.getAverageSpeed();
      expect(avgSpeed, isNotNull);
      // Weighted average (more recent = higher weight)
      // Recent export (3 MB/s) should have highest weight
      expect(avgSpeed, greaterThan(1.5));
      expect(avgSpeed, lessThan(3.0));
    });

    test('estimates export time based on file size', () async {
      // Record an export: 10 MB in 10 seconds = 1 MB/s
      await PerformanceTrackingService.recordExport(
        fileSizeBytes: 10485760,
        durationSeconds: 10.0,
      );

      // Estimate for 20 MB file should be ~20 seconds
      final eta = await PerformanceTrackingService.estimateExportTime(20971520);
      expect(eta, isNotNull);
      expect(eta!.inSeconds, closeTo(20, 2));
    });

    test('returns null estimate when no historical data', () async {
      final eta = await PerformanceTrackingService.estimateExportTime(1000000);
      expect(eta, isNull);
    });

    test('estimates total time for multiple files', () async {
      // Record an export: 10 MB in 10 seconds = 1 MB/s
      await PerformanceTrackingService.recordExport(
        fileSizeBytes: 10485760,
        durationSeconds: 10.0,
      );

      // Estimate for 3 files: 10 MB, 20 MB, 30 MB
      final eta = await PerformanceTrackingService.estimateTotalTime([
        10485760,
        20971520,
        31457280,
      ]);
      expect(eta, isNotNull);
      // Total: 60 MB at 1 MB/s = 60 seconds
      expect(eta!.inSeconds, closeTo(60, 5));
    });

    test('calculates remaining time during export', () {
      final remaining = PerformanceTrackingService.calculateRemainingTime(
        fileSizeBytes: 10000000,
        progressPercent: 25.0,
        elapsedTime: const Duration(seconds: 10),
      );

      expect(remaining, isNotNull);
      // 25% done in 10 seconds means 100% will take 40 seconds
      // Remaining: 40 - 10 = 30 seconds
      expect(remaining!.inSeconds, closeTo(30, 2));
    });

    test('returns null remaining time when progress is invalid', () {
      final remaining1 = PerformanceTrackingService.calculateRemainingTime(
        fileSizeBytes: 10000000,
        progressPercent: 0,
        elapsedTime: const Duration(seconds: 10),
      );
      expect(remaining1, isNull);

      final remaining2 = PerformanceTrackingService.calculateRemainingTime(
        fileSizeBytes: 10000000,
        progressPercent: 100,
        elapsedTime: const Duration(seconds: 10),
      );
      expect(remaining2, isNull);
    });

    test('formats duration correctly', () {
      expect(
        PerformanceTrackingService.formatDuration(const Duration(seconds: 30)),
        '30s',
      );

      expect(
        PerformanceTrackingService.formatDuration(const Duration(seconds: 90)),
        '1m 30s',
      );

      expect(
        PerformanceTrackingService.formatDuration(
            const Duration(seconds: 3665)),
        '1h 1m',
      );
    });

    test('clears history', () async {
      // Add some data
      await PerformanceTrackingService.recordExport(
        fileSizeBytes: 10485760,
        durationSeconds: 10.0,
      );

      var avgSpeed = await PerformanceTrackingService.getAverageSpeed();
      expect(avgSpeed, isNotNull);

      // Clear history
      await PerformanceTrackingService.clearHistory();

      avgSpeed = await PerformanceTrackingService.getAverageSpeed();
      expect(avgSpeed, isNull);
    });

    test('provides statistics', () async {
      // Add multiple exports
      await PerformanceTrackingService.recordExport(
        fileSizeBytes: 10485760,
        durationSeconds: 10.0,
      );

      await PerformanceTrackingService.recordExport(
        fileSizeBytes: 20971520,
        durationSeconds: 10.0,
      );

      final stats = await PerformanceTrackingService.getStatistics();

      expect(stats['hasData'], true);
      expect(stats['count'], 2);
      expect(stats['avgSpeed'], greaterThan(0));
      expect(stats['medianSpeed'], greaterThan(0));
      expect(stats['minSpeed'], greaterThan(0));
      expect(stats['maxSpeed'], greaterThan(0));
      expect(stats['oldestDate'], isNotNull);
      expect(stats['newestDate'], isNotNull);
    });

    test('returns empty statistics when no data', () async {
      final stats = await PerformanceTrackingService.getStatistics();

      expect(stats['hasData'], false);
      expect(stats['count'], 0);
    });
  });
}

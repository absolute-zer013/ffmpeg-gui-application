import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    group('formatExportSummary', () {
      test('formats summary with all successful exports', () {
        final summary = NotificationService.formatExportSummary(
          totalFiles: 5,
          successCount: 5,
          failedCount: 0,
          cancelledCount: 0,
          duration: const Duration(minutes: 2, seconds: 30),
        );

        expect(summary, contains('5 files processed'));
        expect(summary, contains('5 succeeded'));
        expect(summary, contains('2m 30s'));
      });

      test('formats summary with mixed results', () {
        final summary = NotificationService.formatExportSummary(
          totalFiles: 10,
          successCount: 7,
          failedCount: 2,
          cancelledCount: 1,
          duration: const Duration(minutes: 5, seconds: 15),
        );

        expect(summary, contains('10 files processed'));
        expect(summary, contains('7 succeeded'));
        expect(summary, contains('2 failed'));
        expect(summary, contains('1 cancelled'));
        expect(summary, contains('5m 15s'));
      });

      test('formats summary with failures only', () {
        final summary = NotificationService.formatExportSummary(
          totalFiles: 3,
          successCount: 0,
          failedCount: 3,
          cancelledCount: 0,
          duration: const Duration(seconds: 45),
        );

        expect(summary, contains('3 files processed'));
        expect(summary, contains('3 failed'));
        expect(summary, contains('45s'));
      });

      test('formats duration with hours', () {
        final summary = NotificationService.formatExportSummary(
          totalFiles: 1,
          successCount: 1,
          failedCount: 0,
          cancelledCount: 0,
          duration: const Duration(hours: 1, minutes: 30, seconds: 45),
        );

        expect(summary, contains('1h 30m 45s'));
      });

      test('formats duration with minutes only', () {
        final summary = NotificationService.formatExportSummary(
          totalFiles: 1,
          successCount: 1,
          failedCount: 0,
          cancelledCount: 0,
          duration: const Duration(minutes: 3, seconds: 20),
        );

        expect(summary, contains('3m 20s'));
        expect(summary, isNot(contains('0h')));
      });

      test('formats duration with seconds only', () {
        final summary = NotificationService.formatExportSummary(
          totalFiles: 1,
          successCount: 1,
          failedCount: 0,
          cancelledCount: 0,
          duration: const Duration(seconds: 42),
        );

        expect(summary, contains('42s'));
        expect(summary, isNot(contains('0m')));
      });
    });

    group('getNotificationType', () {
      test('returns success for all successful exports', () {
        final type = NotificationService.getNotificationType(
          successCount: 5,
          failedCount: 0,
          totalFiles: 5,
        );

        expect(type, equals('success'));
      });

      test('returns error for all failed exports', () {
        final type = NotificationService.getNotificationType(
          successCount: 0,
          failedCount: 5,
          totalFiles: 5,
        );

        expect(type, equals('error'));
      });

      test('returns warning for mixed results', () {
        final type = NotificationService.getNotificationType(
          successCount: 3,
          failedCount: 2,
          totalFiles: 5,
        );

        expect(type, equals('warning'));
      });
    });

    group('getNotificationTitle', () {
      test('returns success title for all successful exports', () {
        final title = NotificationService.getNotificationTitle(
          successCount: 5,
          totalFiles: 5,
        );

        expect(title, contains('✓'));
        expect(title, contains('Complete'));
      });

      test('returns error title for all failed exports', () {
        final title = NotificationService.getNotificationTitle(
          successCount: 0,
          totalFiles: 5,
        );

        expect(title, contains('✗'));
        expect(title, contains('Failed'));
      });

      test('returns warning title for partial success', () {
        final title = NotificationService.getNotificationTitle(
          successCount: 3,
          totalFiles: 5,
        );

        expect(title, contains('⚠'));
        expect(title, contains('Finished'));
      });
    });

    group('showDesktopNotification', () {
      test('handles call without error on non-Windows platform', () async {
        // This test just ensures the method doesn't throw an error
        // On non-Windows platforms, it should return false
        final result = await NotificationService.showDesktopNotification(
          title: 'Test',
          message: 'Test message',
        );

        // On non-Windows, should return false
        // On Windows, might succeed or fail depending on environment
        expect(result, isA<bool>());
      });

      test('handles special characters in title and message', () async {
        // This test ensures special characters don't cause crashes
        final result = await NotificationService.showDesktopNotification(
          title: 'Test "with" special \'chars\' \$and symbols',
          message: 'Message with `backticks` and \$variables',
        );

        expect(result, isA<bool>());
      });
    });
  });
}

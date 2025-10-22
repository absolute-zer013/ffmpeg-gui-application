import 'dart:io';

/// Service for managing application notifications
/// 
/// Provides both in-app notifications (via callbacks) and 
/// Windows desktop notifications (via PowerShell)
class NotificationService {
  /// Shows a Windows desktop notification using PowerShell
  /// 
  /// [title] The notification title
  /// [message] The notification message body
  /// [type] The notification type: 'info', 'success', 'warning', or 'error'
  static Future<bool> showDesktopNotification({
    required String title,
    required String message,
    String type = 'info',
  }) async {
    if (!Platform.isWindows) {
      return false;
    }

    try {
      // Escape special characters for PowerShell
      final escapedTitle = _escapeForPowerShell(title);
      final escapedMessage = _escapeForPowerShell(message);

      // Create PowerShell script to show Windows toast notification
      final script = '''
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

\$app = 'FFmpeg Export Tool'
\$xml = @"
<toast>
    <visual>
        <binding template="ToastText02">
            <text id="1">$escapedTitle</text>
            <text id="2">$escapedMessage</text>
        </binding>
    </visual>
</toast>
"@

\$XmlDocument = [Windows.Data.Xml.Dom.XmlDocument]::new()
\$XmlDocument.LoadXml(\$xml)
\$toast = [Windows.UI.Notifications.ToastNotification]::new(\$XmlDocument)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier(\$app).Show(\$toast)
''';

      // Execute PowerShell script
      final result = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          script,
        ],
      );

      return result.exitCode == 0;
    } catch (e) {
      // Silently fail if desktop notifications aren't available
      return false;
    }
  }

  /// Escapes special characters for PowerShell strings
  static String _escapeForPowerShell(String text) {
    return text
        .replaceAll('"', '`"')
        .replaceAll("'", "`'")
        .replaceAll('\$', '`\$')
        .replaceAll('`', '``')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ');
  }

  /// Creates a detailed export completion message
  static String formatExportSummary({
    required int totalFiles,
    required int successCount,
    required int failedCount,
    required int cancelledCount,
    required Duration duration,
  }) {
    final parts = <String>[];

    if (successCount > 0) {
      parts.add('$successCount succeeded');
    }
    if (failedCount > 0) {
      parts.add('$failedCount failed');
    }
    if (cancelledCount > 0) {
      parts.add('$cancelledCount cancelled');
    }

    final summary = parts.join(', ');
    final durationStr = _formatDuration(duration);

    return '$totalFiles files processed: $summary (took $durationStr)';
  }

  /// Formats a duration in human-readable format
  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Determines the notification type based on export results
  static String getNotificationType({
    required int successCount,
    required int failedCount,
    required int totalFiles,
  }) {
    if (failedCount == 0 && successCount == totalFiles) {
      return 'success';
    } else if (successCount == 0) {
      return 'error';
    } else {
      return 'warning';
    }
  }

  /// Creates a notification title based on results
  static String getNotificationTitle({
    required int successCount,
    required int totalFiles,
  }) {
    if (successCount == totalFiles) {
      return '✓ Export Complete';
    } else if (successCount == 0) {
      return '✗ Export Failed';
    } else {
      return '⚠ Export Finished';
    }
  }
}

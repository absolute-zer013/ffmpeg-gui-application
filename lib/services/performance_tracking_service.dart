import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Tracks export performance metrics for estimating export times.
class PerformanceMetrics {
  /// Export speed in MB/s
  final double speedMBps;

  /// Timestamp when this metric was recorded
  final DateTime timestamp;

  /// File size in bytes
  final int fileSizeBytes;

  /// Duration taken to export in seconds
  final double durationSeconds;

  const PerformanceMetrics({
    required this.speedMBps,
    required this.timestamp,
    required this.fileSizeBytes,
    required this.durationSeconds,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      speedMBps: json['speedMBps'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
      fileSizeBytes: json['fileSizeBytes'] as int,
      durationSeconds: json['durationSeconds'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speedMBps': speedMBps,
      'timestamp': timestamp.toIso8601String(),
      'fileSizeBytes': fileSizeBytes,
      'durationSeconds': durationSeconds,
    };
  }
}

/// Service for tracking and estimating export performance.
class PerformanceTrackingService {
  static const String _prefsKey = 'performance_metrics';
  static const int _maxHistorySize = 50; // Keep last 50 exports
  static const int _maxHistoryAgeDays =
      30; // Only keep metrics from last 30 days

  /// Record a completed export for performance tracking
  static Future<void> recordExport({
    required int fileSizeBytes,
    required double durationSeconds,
  }) async {
    if (durationSeconds <= 0 || fileSizeBytes <= 0) return;

    final speedMBps = (fileSizeBytes / (1024 * 1024)) / durationSeconds;
    final metric = PerformanceMetrics(
      speedMBps: speedMBps,
      timestamp: DateTime.now(),
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds,
    );

    final prefs = await SharedPreferences.getInstance();
    final history = await _loadMetrics();

    // Add new metric
    history.add(metric);

    // Remove old metrics (older than max age)
    final cutoffDate =
        DateTime.now().subtract(const Duration(days: _maxHistoryAgeDays));
    history.removeWhere((m) => m.timestamp.isBefore(cutoffDate));

    // Keep only most recent metrics if we exceed max size
    if (history.length > _maxHistorySize) {
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      history.removeRange(_maxHistorySize, history.length);
    }

    // Save back to preferences
    final jsonList = history.map((m) => m.toJson()).toList();
    await prefs.setString(_prefsKey, jsonEncode(jsonList));
  }

  /// Load historical metrics
  static Future<List<PerformanceMetrics>> _loadMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList
          .map((json) =>
              PerformanceMetrics.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get average export speed based on historical data
  static Future<double?> getAverageSpeed() async {
    final metrics = await _loadMetrics();
    if (metrics.isEmpty) return null;

    // Use weighted average, giving more weight to recent exports
    double totalWeight = 0;
    double weightedSum = 0;

    for (var i = 0; i < metrics.length; i++) {
      // More recent exports get higher weight (exponential decay)
      final weight = 1.0 / (i + 1);
      weightedSum += metrics[i].speedMBps * weight;
      totalWeight += weight;
    }

    return weightedSum / totalWeight;
  }

  /// Estimate time to export a file based on its size
  static Future<Duration?> estimateExportTime(int fileSizeBytes) async {
    final avgSpeed = await getAverageSpeed();
    if (avgSpeed == null || avgSpeed <= 0) return null;

    final fileSizeMB = fileSizeBytes / (1024 * 1024);
    final estimatedSeconds = fileSizeMB / avgSpeed;

    return Duration(seconds: estimatedSeconds.ceil());
  }

  /// Estimate total time for multiple files
  static Future<Duration?> estimateTotalTime(List<int> fileSizes) async {
    final avgSpeed = await getAverageSpeed();
    if (avgSpeed == null || avgSpeed <= 0) return null;

    final totalSizeMB = fileSizes.fold<double>(
      0,
      (sum, size) => sum + (size / (1024 * 1024)),
    );

    final estimatedSeconds = totalSizeMB / avgSpeed;
    return Duration(seconds: estimatedSeconds.ceil());
  }

  /// Calculate remaining time for current export
  static Duration? calculateRemainingTime({
    required int fileSizeBytes,
    required double progressPercent,
    required Duration elapsedTime,
  }) {
    if (progressPercent <= 0 || progressPercent >= 100) return null;

    final totalEstimatedSeconds =
        elapsedTime.inSeconds / (progressPercent / 100);
    final remainingSeconds = totalEstimatedSeconds - elapsedTime.inSeconds;

    return Duration(seconds: remainingSeconds.ceil());
  }

  /// Format duration for display
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Clear all historical metrics
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// Get performance statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    final metrics = await _loadMetrics();
    if (metrics.isEmpty) {
      return {
        'hasData': false,
        'count': 0,
      };
    }

    final speeds = metrics.map((m) => m.speedMBps).toList()..sort();
    final avgSpeed = speeds.reduce((a, b) => a + b) / speeds.length;
    final medianSpeed = speeds[speeds.length ~/ 2];
    final minSpeed = speeds.first;
    final maxSpeed = speeds.last;

    return {
      'hasData': true,
      'count': metrics.length,
      'avgSpeed': avgSpeed,
      'medianSpeed': medianSpeed,
      'minSpeed': minSpeed,
      'maxSpeed': maxSpeed,
      'oldestDate': metrics
          .map((m) => m.timestamp)
          .reduce((a, b) => a.isBefore(b) ? a : b),
      'newestDate': metrics
          .map((m) => m.timestamp)
          .reduce((a, b) => a.isAfter(b) ? a : b),
    };
  }
}

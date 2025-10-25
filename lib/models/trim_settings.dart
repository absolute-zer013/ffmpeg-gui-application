/// Represents trim/cut settings for a media file.
class TrimSettings {
  /// Start time in seconds (null means start from beginning)
  final double? startTime;

  /// End time in seconds (null means go to the end)
  final double? endTime;

  /// Whether trim settings are enabled
  final bool enabled;

  const TrimSettings({
    this.startTime,
    this.endTime,
    this.enabled = false,
  });

  /// Create TrimSettings from start/end time strings (HH:MM:SS format)
  factory TrimSettings.fromTimeStrings({
    String? startTimeStr,
    String? endTimeStr,
    bool enabled = false,
  }) {
    return TrimSettings(
      startTime: startTimeStr != null ? _parseTimeString(startTimeStr) : null,
      endTime: endTimeStr != null ? _parseTimeString(endTimeStr) : null,
      enabled: enabled,
    );
  }

  /// Parse time string in HH:MM:SS or MM:SS or SS format to seconds
  static double? _parseTimeString(String timeStr) {
    if (timeStr.isEmpty) return null;

    try {
      final parts = timeStr.split(':').map((s) => s.trim()).toList();
      double seconds = 0;

      if (parts.length == 3) {
        // HH:MM:SS
        seconds = int.parse(parts[0]) * 3600 +
            int.parse(parts[1]) * 60 +
            double.parse(parts[2]);
      } else if (parts.length == 2) {
        // MM:SS
        seconds = int.parse(parts[0]) * 60 + double.parse(parts[1]);
      } else if (parts.length == 1) {
        // SS
        seconds = double.parse(parts[0]);
      }

      return seconds >= 0 ? seconds : null;
    } catch (e) {
      return null;
    }
  }

  /// Convert seconds to HH:MM:SS format
  static String formatTime(double seconds) {
    final hours = (seconds ~/ 3600);
    final minutes = ((seconds % 3600) ~/ 60);
    final secs = (seconds % 60).toInt();
    final ms = ((seconds % 1) * 100).toInt();

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}'
          '${ms > 0 ? '.$ms' : ''}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}'
          '${ms > 0 ? '.$ms' : ''}';
    }
  }

  /// Get duration in seconds (end - start)
  double? get duration {
    if (startTime != null && endTime != null && endTime! > startTime!) {
      return endTime! - startTime!;
    }
    return null;
  }

  /// Validate that end time is after start time
  bool get isValid {
    if (!enabled) return true;
    if (startTime == null && endTime == null) return false;
    if (startTime != null && endTime != null) {
      return endTime! > startTime!;
    }
    return true;
  }

  TrimSettings copyWith({
    double? startTime,
    double? endTime,
    bool? enabled,
  }) {
    return TrimSettings(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'enabled': enabled,
    };
  }

  factory TrimSettings.fromJson(Map<String, dynamic> json) {
    return TrimSettings(
      startTime: json['startTime'] as double?,
      endTime: json['endTime'] as double?,
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    if (!enabled) return 'Trim: Disabled';
    final start = startTime != null ? formatTime(startTime!) : 'start';
    final end = endTime != null ? formatTime(endTime!) : 'end';
    return 'Trim: $start to $end';
  }
}

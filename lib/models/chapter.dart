/// Represents a chapter marker in a video file
class Chapter {
  /// Unique ID for the chapter
  final int id;
  
  /// Start time in seconds
  final double startTime;
  
  /// End time in seconds
  final double endTime;
  
  /// Chapter title
  final String title;

  const Chapter({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.title,
  });

  /// Creates a copy with modified fields
  Chapter copyWith({
    int? id,
    double? startTime,
    double? endTime,
    String? title,
  }) {
    return Chapter(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      title: title ?? this.title,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime,
      'endTime': endTime,
      'title': title,
    };
  }

  /// Creates from JSON
  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as int,
      startTime: (json['startTime'] as num).toDouble(),
      endTime: (json['endTime'] as num).toDouble(),
      title: json['title'] as String,
    );
  }

  /// Formats time in HH:MM:SS format
  static String formatTime(double seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toInt().toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  /// Parses time from HH:MM:SS format
  static double parseTime(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 3) {
      throw FormatException('Invalid time format: $timeString');
    }
    
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = double.parse(parts[2]);
    
    return hours * 3600.0 + minutes * 60.0 + seconds;
  }

  /// Gets formatted start time
  String get formattedStartTime => formatTime(startTime);

  /// Gets formatted end time
  String get formattedEndTime => formatTime(endTime);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chapter &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          title == other.title;

  @override
  int get hashCode =>
      id.hashCode ^ startTime.hashCode ^ endTime.hashCode ^ title.hashCode;

  @override
  String toString() {
    return 'Chapter(id: $id, startTime: $startTime, endTime: $endTime, title: $title)';
  }
}

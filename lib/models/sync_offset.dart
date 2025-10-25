/// Represents timing offset settings for audio/subtitle synchronization.
class SyncOffset {
  /// Stream index to apply offset to
  final int streamIndex;

  /// Offset in milliseconds (can be positive or negative)
  final int offsetMs;

  /// Stream type ('audio' or 'subtitle')
  final String streamType;

  /// Track description for display
  final String? trackDescription;

  const SyncOffset({
    required this.streamIndex,
    required this.offsetMs,
    required this.streamType,
    this.trackDescription,
  });

  /// Get offset in seconds for FFmpeg
  double get offsetSeconds => offsetMs / 1000.0;

  /// Format offset for display
  String get formattedOffset {
    final absMs = offsetMs.abs();
    final seconds = (absMs / 1000).floor();
    final ms = absMs % 1000;
    final sign = offsetMs >= 0 ? '+' : '-';

    if (seconds > 0) {
      return '$sign${seconds}s ${ms}ms';
    } else {
      return '$sign${ms}ms';
    }
  }

  SyncOffset copyWith({
    int? streamIndex,
    int? offsetMs,
    String? streamType,
    String? trackDescription,
  }) {
    return SyncOffset(
      streamIndex: streamIndex ?? this.streamIndex,
      offsetMs: offsetMs ?? this.offsetMs,
      streamType: streamType ?? this.streamType,
      trackDescription: trackDescription ?? this.trackDescription,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'streamIndex': streamIndex,
      'offsetMs': offsetMs,
      'streamType': streamType,
      'trackDescription': trackDescription,
    };
  }

  factory SyncOffset.fromJson(Map<String, dynamic> json) {
    return SyncOffset(
      streamIndex: json['streamIndex'] as int,
      offsetMs: json['offsetMs'] as int,
      streamType: json['streamType'] as String,
      trackDescription: json['trackDescription'] as String?,
    );
  }

  @override
  String toString() {
    final desc = trackDescription ?? 'Stream $streamIndex';
    return '$desc: $formattedOffset';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncOffset &&
        other.streamIndex == streamIndex &&
        other.streamType == streamType;
  }

  @override
  int get hashCode => Object.hash(streamIndex, streamType);
}

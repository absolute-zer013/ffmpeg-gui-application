/// Enum for track types
enum TrackType { video, audio, subtitle }

/// Data model representing a media stream track.
class Track {
  final int position;
  final String language;
  final String? title;
  final String description;
  final int streamIndex;
  final TrackType type;
  final String? codec;
  final int? width;
  final int? height;
  final String? frameRate;

  Track({
    required this.position,
    required this.language,
    this.title,
    required this.description,
    int? streamIndex,
    this.type = TrackType.audio,
    this.codec,
    this.width,
    this.height,
    this.frameRate,
  }) : streamIndex = streamIndex ?? position;
}

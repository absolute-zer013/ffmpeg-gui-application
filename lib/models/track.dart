/// Data model representing a media stream track.
class Track {
  final int position;
  final String language;
  final String? title;
  final String description;
  final int streamIndex;

  Track({
    required this.position,
    required this.language,
    this.title,
    required this.description,
    int? streamIndex,
  }) : streamIndex = streamIndex ?? position;
}

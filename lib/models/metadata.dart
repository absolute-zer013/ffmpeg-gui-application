/// Data model for file-level metadata
class FileMetadata {
  String? title;
  String? artist;
  String? album;
  String? date;
  String? comment;
  String? genre;
  String? encoder;

  // Additional custom metadata
  Map<String, String> customFields;

  FileMetadata({
    this.title,
    this.artist,
    this.album,
    this.date,
    this.comment,
    this.genre,
    this.encoder,
    Map<String, String>? customFields,
  }) : customFields = customFields ?? {};

  /// Create from map (e.g., from FFprobe JSON)
  factory FileMetadata.fromMap(Map<String, dynamic> map) {
    final metadata = FileMetadata();

    for (final entry in map.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value?.toString();

      if (value == null || value.isEmpty) continue;

      switch (key) {
        case 'title':
          metadata.title = value;
          break;
        case 'artist':
          metadata.artist = value;
          break;
        case 'album':
          metadata.album = value;
          break;
        case 'date':
          metadata.date = value;
          break;
        case 'comment':
          metadata.comment = value;
          break;
        case 'genre':
          metadata.genre = value;
          break;
        case 'encoder':
          metadata.encoder = value;
          break;
        default:
          metadata.customFields[entry.key] = value;
      }
    }

    return metadata;
  }

  /// Convert to map for saving
  Map<String, String> toMap() {
    final map = <String, String>{};

    if (title != null && title!.isNotEmpty) map['title'] = title!;
    if (artist != null && artist!.isNotEmpty) map['artist'] = artist!;
    if (album != null && album!.isNotEmpty) map['album'] = album!;
    if (date != null && date!.isNotEmpty) map['date'] = date!;
    if (comment != null && comment!.isNotEmpty) map['comment'] = comment!;
    if (genre != null && genre!.isNotEmpty) map['genre'] = genre!;
    if (encoder != null && encoder!.isNotEmpty) map['encoder'] = encoder!;

    map.addAll(customFields);

    return map;
  }

  /// Create a copy with modifications
  FileMetadata copyWith({
    String? title,
    String? artist,
    String? album,
    String? date,
    String? comment,
    String? genre,
    String? encoder,
    Map<String, String>? customFields,
  }) {
    return FileMetadata(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      date: date ?? this.date,
      comment: comment ?? this.comment,
      genre: genre ?? this.genre,
      encoder: encoder ?? this.encoder,
      customFields: customFields ?? Map.from(this.customFields),
    );
  }
}

/// Data model for track-level metadata
class TrackMetadata {
  String? language;
  String? title;
  bool? isDefault;
  bool? isForced;

  TrackMetadata({
    this.language,
    this.title,
    this.isDefault,
    this.isForced,
  });

  /// Create from map
  factory TrackMetadata.fromMap(Map<String, dynamic> map) {
    return TrackMetadata(
      language: map['language']?.toString(),
      title: map['title']?.toString(),
      isDefault: map['default'] == 1 || map['default'] == '1',
      isForced: map['forced'] == 1 || map['forced'] == '1',
    );
  }

  /// Convert to map
  Map<String, String> toMap() {
    final map = <String, String>{};

    if (language != null && language!.isNotEmpty) map['language'] = language!;
    if (title != null && title!.isNotEmpty) map['title'] = title!;

    return map;
  }

  /// Create a copy with modifications
  TrackMetadata copyWith({
    String? language,
    String? title,
    bool? isDefault,
    bool? isForced,
  }) {
    return TrackMetadata(
      language: language ?? this.language,
      title: title ?? this.title,
      isDefault: isDefault ?? this.isDefault,
      isForced: isForced ?? this.isForced,
    );
  }
}

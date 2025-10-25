/// Model representing an external preset from another tool (e.g., HandBrake).
class ExternalPreset {
  /// The name of the preset.
  final String name;

  /// The description of the preset.
  final String? description;

  /// The source tool (e.g., "HandBrake", "FFmpeg").
  final String source;

  /// The preset category (e.g., "General", "Web", "Devices").
  final String? category;

  /// Raw preset data as a map.
  final Map<String, dynamic> rawData;

  /// Mapped FFmpeg parameters.
  final PresetMapping? mapping;

  const ExternalPreset({
    required this.name,
    this.description,
    required this.source,
    this.category,
    required this.rawData,
    this.mapping,
  });

  ExternalPreset copyWith({
    String? name,
    String? description,
    String? source,
    String? category,
    Map<String, dynamic>? rawData,
    PresetMapping? mapping,
  }) {
    return ExternalPreset(
      name: name ?? this.name,
      description: description ?? this.description,
      source: source ?? this.source,
      category: category ?? this.category,
      rawData: rawData ?? this.rawData,
      mapping: mapping ?? this.mapping,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'source': source,
      'category': category,
      'rawData': rawData,
      'mapping': mapping?.toJson(),
    };
  }

  factory ExternalPreset.fromJson(Map<String, dynamic> json) {
    return ExternalPreset(
      name: json['name'] as String,
      description: json['description'] as String?,
      source: json['source'] as String,
      category: json['category'] as String?,
      rawData: json['rawData'] as Map<String, dynamic>,
      mapping: json['mapping'] != null
          ? PresetMapping.fromJson(json['mapping'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Model representing the mapping from external preset parameters to FFmpeg parameters.
class PresetMapping {
  /// Video codec mapping.
  final String? videoCodec;

  /// Audio codec mapping.
  final String? audioCodec;

  /// Video bitrate or quality setting.
  final String? videoQuality;

  /// Audio bitrate.
  final String? audioBitrate;

  /// Audio sample rate.
  final int? audioSampleRate;

  /// Audio channels.
  final int? audioChannels;

  /// Resolution (width x height).
  final String? resolution;

  /// Frame rate.
  final String? frameRate;

  /// Container format.
  final String? format;

  /// Additional FFmpeg arguments.
  final List<String> additionalArgs;

  /// Compatibility warnings.
  final List<String> warnings;

  /// Whether the preset is fully compatible with FFmpeg.
  final bool isCompatible;

  const PresetMapping({
    this.videoCodec,
    this.audioCodec,
    this.videoQuality,
    this.audioBitrate,
    this.audioSampleRate,
    this.audioChannels,
    this.resolution,
    this.frameRate,
    this.format,
    this.additionalArgs = const [],
    this.warnings = const [],
    this.isCompatible = true,
  });

  PresetMapping copyWith({
    String? videoCodec,
    String? audioCodec,
    String? videoQuality,
    String? audioBitrate,
    int? audioSampleRate,
    int? audioChannels,
    String? resolution,
    String? frameRate,
    String? format,
    List<String>? additionalArgs,
    List<String>? warnings,
    bool? isCompatible,
  }) {
    return PresetMapping(
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      videoQuality: videoQuality ?? this.videoQuality,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      audioSampleRate: audioSampleRate ?? this.audioSampleRate,
      audioChannels: audioChannels ?? this.audioChannels,
      resolution: resolution ?? this.resolution,
      frameRate: frameRate ?? this.frameRate,
      format: format ?? this.format,
      additionalArgs: additionalArgs ?? this.additionalArgs,
      warnings: warnings ?? this.warnings,
      isCompatible: isCompatible ?? this.isCompatible,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoCodec': videoCodec,
      'audioCodec': audioCodec,
      'videoQuality': videoQuality,
      'audioBitrate': audioBitrate,
      'audioSampleRate': audioSampleRate,
      'audioChannels': audioChannels,
      'resolution': resolution,
      'frameRate': frameRate,
      'format': format,
      'additionalArgs': additionalArgs,
      'warnings': warnings,
      'isCompatible': isCompatible,
    };
  }

  factory PresetMapping.fromJson(Map<String, dynamic> json) {
    return PresetMapping(
      videoCodec: json['videoCodec'] as String?,
      audioCodec: json['audioCodec'] as String?,
      videoQuality: json['videoQuality'] as String?,
      audioBitrate: json['audioBitrate'] as String?,
      audioSampleRate: json['audioSampleRate'] as int?,
      audioChannels: json['audioChannels'] as int?,
      resolution: json['resolution'] as String?,
      frameRate: json['frameRate'] as String?,
      format: json['format'] as String?,
      additionalArgs: (json['additionalArgs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isCompatible: json['isCompatible'] as bool? ?? true,
    );
  }

  /// Returns a human-readable summary of the mapping.
  String getSummary() {
    final parts = <String>[];

    if (videoCodec != null) parts.add('Video: $videoCodec');
    if (audioCodec != null) parts.add('Audio: $audioCodec');
    if (videoQuality != null) parts.add('Quality: $videoQuality');
    if (resolution != null) parts.add('Resolution: $resolution');

    return parts.isEmpty ? 'No mapping' : parts.join(', ');
  }
}

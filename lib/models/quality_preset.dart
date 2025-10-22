/// Enum for quality preset types
enum QualityPresetType {
  fast,
  balanced,
  highQuality,
  custom,
}

/// Quality preset for video encoding
class QualityPreset {
  final QualityPresetType type;
  final String name;
  final String description;
  final int? crf; // Constant Rate Factor (0-51, lower = better quality)
  final String?
      preset; // FFmpeg preset: ultrafast, fast, medium, slow, veryslow
  final int? videoBitrate; // in kbps, used if CRF is null
  final int? audioBitrate; // in kbps

  const QualityPreset({
    required this.type,
    required this.name,
    required this.description,
    this.crf,
    this.preset,
    this.videoBitrate,
    this.audioBitrate,
  });

  /// Predefined quality presets
  static const fast = QualityPreset(
    type: QualityPresetType.fast,
    name: 'Fast',
    description: 'Quick encoding with acceptable quality',
    crf: 28,
    preset: 'fast',
    audioBitrate: 128,
  );

  static const balanced = QualityPreset(
    type: QualityPresetType.balanced,
    name: 'Balanced',
    description: 'Good balance between speed and quality',
    crf: 23,
    preset: 'medium',
    audioBitrate: 192,
  );

  static const highQuality = QualityPreset(
    type: QualityPresetType.highQuality,
    name: 'High Quality',
    description: 'Best quality, slower encoding',
    crf: 18,
    preset: 'slow',
    audioBitrate: 256,
  );

  /// Get all predefined presets
  static List<QualityPreset> get predefinedPresets => [
        fast,
        balanced,
        highQuality,
      ];

  /// Get preset by type
  static QualityPreset? getPresetByType(QualityPresetType type) {
    return predefinedPresets.where((p) => p.type == type).firstOrNull;
  }

  QualityPreset copyWith({
    QualityPresetType? type,
    String? name,
    String? description,
    int? crf,
    String? preset,
    int? videoBitrate,
    int? audioBitrate,
  }) {
    return QualityPreset(
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      crf: crf ?? this.crf,
      preset: preset ?? this.preset,
      videoBitrate: videoBitrate ?? this.videoBitrate,
      audioBitrate: audioBitrate ?? this.audioBitrate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'name': name,
      'description': description,
      'crf': crf,
      'preset': preset,
      'videoBitrate': videoBitrate,
      'audioBitrate': audioBitrate,
    };
  }

  factory QualityPreset.fromJson(Map<String, dynamic> json) {
    return QualityPreset(
      type: QualityPresetType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => QualityPresetType.balanced,
      ),
      name: json['name'] as String,
      description: json['description'] as String,
      crf: json['crf'] as int?,
      preset: json['preset'] as String?,
      videoBitrate: json['videoBitrate'] as int?,
      audioBitrate: json['audioBitrate'] as int?,
    );
  }
}

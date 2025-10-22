/// Data model representing a rename pattern with variable substitution
class RenamePattern {
  final String name;
  final String pattern;
  final String description;
  final bool isCustom;

  RenamePattern({
    required this.name,
    required this.pattern,
    this.description = '',
    this.isCustom = false,
  });

  /// Create pattern from JSON
  factory RenamePattern.fromJson(Map<String, dynamic> json) {
    return RenamePattern(
      name: json['name'] as String,
      pattern: json['pattern'] as String,
      description: json['description'] as String? ?? '',
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  /// Convert pattern to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'pattern': pattern,
      'description': description,
      'isCustom': isCustom,
    };
  }

  /// Create a copy with modified fields
  RenamePattern copyWith({
    String? name,
    String? pattern,
    String? description,
    bool? isCustom,
  }) {
    return RenamePattern(
      name: name ?? this.name,
      pattern: pattern ?? this.pattern,
      description: description ?? this.description,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  /// Get list of predefined rename patterns
  static List<RenamePattern> getPredefinedPatterns() {
    return [
      RenamePattern(
        name: 'Original',
        pattern: '{name}',
        description: 'Keep original filename',
      ),
      RenamePattern(
        name: 'TV Show',
        pattern: '{name} - S{season:2}E{episode:2}',
        description: 'Format: ShowName - S01E01',
      ),
      RenamePattern(
        name: 'TV Show Alt',
        pattern: '{name} {season}x{episode:2}',
        description: 'Format: ShowName 1x01',
      ),
      RenamePattern(
        name: 'Movie',
        pattern: '{name} ({year})',
        description: 'Format: MovieName (2024)',
      ),
      RenamePattern(
        name: 'Anime',
        pattern: '{name} - {episode:3}',
        description: 'Format: AnimeName - 001',
      ),
      RenamePattern(
        name: 'With Date',
        pattern: '{name} - {date}',
        description: 'Format: Name - 2024-10-22',
      ),
      RenamePattern(
        name: 'Indexed',
        pattern: '{name} - {index:3}',
        description: 'Format: Name - 001',
      ),
    ];
  }
}

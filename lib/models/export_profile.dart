/// Data model representing an export profile/template
class ExportProfile {
  final String id;
  final String name;
  final String description;
  final Set<String> selectedAudioLanguages;
  final Set<String> selectedSubtitleDescriptions;
  final String? defaultSubtitleDescription;
  final DateTime createdAt;
  final DateTime modifiedAt;

  ExportProfile({
    required this.id,
    required this.name,
    this.description = '',
    Set<String>? selectedAudioLanguages,
    Set<String>? selectedSubtitleDescriptions,
    this.defaultSubtitleDescription,
    DateTime? createdAt,
    DateTime? modifiedAt,
  })  : selectedAudioLanguages = selectedAudioLanguages ?? <String>{},
        selectedSubtitleDescriptions =
            selectedSubtitleDescriptions ?? <String>{},
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  /// Create profile from JSON
  factory ExportProfile.fromJson(Map<String, dynamic> json) {
    return ExportProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      selectedAudioLanguages:
          (json['selectedAudioLanguages'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toSet() ??
              <String>{},
      selectedSubtitleDescriptions:
          (json['selectedSubtitleDescriptions'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toSet() ??
              <String>{},
      defaultSubtitleDescription: json['defaultSubtitleDescription'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
    );
  }

  /// Convert profile to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'selectedAudioLanguages': selectedAudioLanguages.toList(),
      'selectedSubtitleDescriptions': selectedSubtitleDescriptions.toList(),
      'defaultSubtitleDescription': defaultSubtitleDescription,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  ExportProfile copyWith({
    String? id,
    String? name,
    String? description,
    Set<String>? selectedAudioLanguages,
    Set<String>? selectedSubtitleDescriptions,
    String? defaultSubtitleDescription,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return ExportProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      selectedAudioLanguages:
          selectedAudioLanguages ?? this.selectedAudioLanguages,
      selectedSubtitleDescriptions:
          selectedSubtitleDescriptions ?? this.selectedSubtitleDescriptions,
      defaultSubtitleDescription:
          defaultSubtitleDescription ?? this.defaultSubtitleDescription,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }
}

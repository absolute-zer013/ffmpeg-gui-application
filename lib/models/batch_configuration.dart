import 'auto_detect_rule.dart';
import 'export_profile.dart';
import 'rename_pattern.dart';

/// Data model representing a complete batch configuration
class BatchConfiguration {
  final String id;
  final String name;
  final String description;
  final List<FileConfiguration> files;
  final List<ExportProfile> profiles;
  final List<AutoDetectRule> rules;
  final RenamePattern? defaultRenamePattern;
  final String outputFormat;
  final int maxConcurrentExports;
  final bool enableVerification;
  final DateTime createdAt;
  final DateTime modifiedAt;

  BatchConfiguration({
    required this.id,
    required this.name,
    this.description = '',
    List<FileConfiguration>? files,
    List<ExportProfile>? profiles,
    List<AutoDetectRule>? rules,
    this.defaultRenamePattern,
    this.outputFormat = 'mkv',
    this.maxConcurrentExports = 2,
    this.enableVerification = true,
    DateTime? createdAt,
    DateTime? modifiedAt,
  })  : files = files ?? [],
        profiles = profiles ?? [],
        rules = rules ?? [],
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  /// Create configuration from JSON
  factory BatchConfiguration.fromJson(Map<String, dynamic> json) {
    return BatchConfiguration(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      files: (json['files'] as List<dynamic>?)
              ?.map((f) => FileConfiguration.fromJson(f))
              .toList() ??
          [],
      profiles: (json['profiles'] as List<dynamic>?)
              ?.map((p) => ExportProfile.fromJson(p))
              .toList() ??
          [],
      rules: (json['rules'] as List<dynamic>?)
              ?.map((r) => AutoDetectRule.fromJson(r))
              .toList() ??
          [],
      defaultRenamePattern: json['defaultRenamePattern'] != null
          ? RenamePattern.fromJson(json['defaultRenamePattern'])
          : null,
      outputFormat: json['outputFormat'] as String? ?? 'mkv',
      maxConcurrentExports: json['maxConcurrentExports'] as int? ?? 2,
      enableVerification: json['enableVerification'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
    );
  }

  /// Convert configuration to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'files': files.map((f) => f.toJson()).toList(),
      'profiles': profiles.map((p) => p.toJson()).toList(),
      'rules': rules.map((r) => r.toJson()).toList(),
      'defaultRenamePattern': defaultRenamePattern?.toJson(),
      'outputFormat': outputFormat,
      'maxConcurrentExports': maxConcurrentExports,
      'enableVerification': enableVerification,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'version': '1.0',
      'appName': 'FFmpeg Filter App',
    };
  }

  /// Create a copy with modified fields
  BatchConfiguration copyWith({
    String? id,
    String? name,
    String? description,
    List<FileConfiguration>? files,
    List<ExportProfile>? profiles,
    List<AutoDetectRule>? rules,
    RenamePattern? defaultRenamePattern,
    String? outputFormat,
    int? maxConcurrentExports,
    bool? enableVerification,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return BatchConfiguration(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      files: files ?? this.files,
      profiles: profiles ?? this.profiles,
      rules: rules ?? this.rules,
      defaultRenamePattern: defaultRenamePattern ?? this.defaultRenamePattern,
      outputFormat: outputFormat ?? this.outputFormat,
      maxConcurrentExports: maxConcurrentExports ?? this.maxConcurrentExports,
      enableVerification: enableVerification ?? this.enableVerification,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }
}

/// Configuration for a single file in a batch
class FileConfiguration {
  final String path;
  final String? outputName;
  final Set<int> selectedVideoTracks;
  final Set<int> selectedAudioTracks;
  final Set<int> selectedSubtitleTracks;
  final int? defaultVideo;
  final int? defaultAudio;
  final int? defaultSubtitle;
  final RenamePattern? renamePattern;
  final int? renameIndex;
  final int? renameEpisode;
  final int? renameSeason;
  final int? renameYear;
  final String? profileId;

  FileConfiguration({
    required this.path,
    this.outputName,
    Set<int>? selectedVideoTracks,
    Set<int>? selectedAudioTracks,
    Set<int>? selectedSubtitleTracks,
    this.defaultVideo,
    this.defaultAudio,
    this.defaultSubtitle,
    this.renamePattern,
    this.renameIndex,
    this.renameEpisode,
    this.renameSeason,
    this.renameYear,
    this.profileId,
  })  : selectedVideoTracks = selectedVideoTracks ?? {},
        selectedAudioTracks = selectedAudioTracks ?? {},
        selectedSubtitleTracks = selectedSubtitleTracks ?? {};

  /// Create file configuration from JSON
  factory FileConfiguration.fromJson(Map<String, dynamic> json) {
    return FileConfiguration(
      path: json['path'] as String,
      outputName: json['outputName'] as String?,
      selectedVideoTracks: (json['selectedVideoTracks'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toSet() ??
          {},
      selectedAudioTracks: (json['selectedAudioTracks'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toSet() ??
          {},
      selectedSubtitleTracks: (json['selectedSubtitleTracks'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toSet() ??
          {},
      defaultVideo: json['defaultVideo'] as int?,
      defaultAudio: json['defaultAudio'] as int?,
      defaultSubtitle: json['defaultSubtitle'] as int?,
      renamePattern: json['renamePattern'] != null
          ? RenamePattern.fromJson(json['renamePattern'])
          : null,
      renameIndex: json['renameIndex'] as int?,
      renameEpisode: json['renameEpisode'] as int?,
      renameSeason: json['renameSeason'] as int?,
      renameYear: json['renameYear'] as int?,
      profileId: json['profileId'] as String?,
    );
  }

  /// Convert file configuration to JSON
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'outputName': outputName,
      'selectedVideoTracks': selectedVideoTracks.toList(),
      'selectedAudioTracks': selectedAudioTracks.toList(),
      'selectedSubtitleTracks': selectedSubtitleTracks.toList(),
      'defaultVideo': defaultVideo,
      'defaultAudio': defaultAudio,
      'defaultSubtitle': defaultSubtitle,
      'renamePattern': renamePattern?.toJson(),
      'renameIndex': renameIndex,
      'renameEpisode': renameEpisode,
      'renameSeason': renameSeason,
      'renameYear': renameYear,
      'profileId': profileId,
    };
  }
}

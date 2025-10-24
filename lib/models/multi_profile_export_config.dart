import 'export_profile.dart';

/// Represents a configuration for exporting a file with multiple profiles.
class MultiProfileExportConfig {
  /// List of profiles to export with
  final List<ExportProfile> profiles;
  
  /// Suffix strategy for output filenames
  final FilenameSuffixStrategy suffixStrategy;
  
  /// Whether to export profiles in parallel or sequentially
  final bool parallel;

  const MultiProfileExportConfig({
    required this.profiles,
    this.suffixStrategy = FilenameSuffixStrategy.profileName,
    this.parallel = false,
  });

  /// Generate output filename with appropriate suffix
  String generateFilename(String originalName, ExportProfile profile, int index) {
    // Use path package for proper extension handling
    final baseName = originalName.substring(
      0, 
      originalName.lastIndexOf('.') > 0 
        ? originalName.lastIndexOf('.') 
        : originalName.length
    );
    final extension = originalName.lastIndexOf('.') > 0
        ? originalName.substring(originalName.lastIndexOf('.') + 1)
        : 'mkv';

    String suffix;
    switch (suffixStrategy) {
      case FilenameSuffixStrategy.profileName:
        suffix = profile.name.replaceAll(RegExp(r'[^\w_-]'), '_');
        break;
      case FilenameSuffixStrategy.index:
        suffix = (index + 1).toString().padLeft(2, '0');
        break;
      case FilenameSuffixStrategy.profileNameAndIndex:
        suffix = '${profile.name.replaceAll(RegExp(r'[^\w_-]'), '_')}_${(index + 1).toString().padLeft(2, '0')}';
        break;
    }

    return '$baseName-$suffix.$extension';
  }

  MultiProfileExportConfig copyWith({
    List<ExportProfile>? profiles,
    FilenameSuffixStrategy? suffixStrategy,
    bool? parallel,
  }) {
    return MultiProfileExportConfig(
      profiles: profiles ?? this.profiles,
      suffixStrategy: suffixStrategy ?? this.suffixStrategy,
      parallel: parallel ?? this.parallel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profiles': profiles.map((p) => p.toJson()).toList(),
      'suffixStrategy': suffixStrategy.name,
      'parallel': parallel,
    };
  }

  factory MultiProfileExportConfig.fromJson(Map<String, dynamic> json) {
    return MultiProfileExportConfig(
      profiles: (json['profiles'] as List)
          .map((p) => ExportProfile.fromJson(p as Map<String, dynamic>))
          .toList(),
      suffixStrategy: FilenameSuffixStrategy.values.firstWhere(
        (s) => s.name == json['suffixStrategy'],
        orElse: () => FilenameSuffixStrategy.profileName,
      ),
      parallel: json['parallel'] as bool? ?? false,
    );
  }
}

/// Strategy for generating output filenames with multiple profiles
enum FilenameSuffixStrategy {
  /// Use profile name as suffix (e.g., "movie-HighQuality.mkv")
  profileName,
  
  /// Use sequential index as suffix (e.g., "movie-01.mkv", "movie-02.mkv")
  index,
  
  /// Use both profile name and index (e.g., "movie-HighQuality_01.mkv")
  profileNameAndIndex,
}

extension FilenameSuffixStrategyExtension on FilenameSuffixStrategy {
  String get displayName {
    switch (this) {
      case FilenameSuffixStrategy.profileName:
        return 'Profile Name';
      case FilenameSuffixStrategy.index:
        return 'Sequential Number';
      case FilenameSuffixStrategy.profileNameAndIndex:
        return 'Profile Name + Number';
    }
  }

  String get description {
    switch (this) {
      case FilenameSuffixStrategy.profileName:
        return 'Uses profile name as suffix (e.g., movie-HighQuality.mkv)';
      case FilenameSuffixStrategy.index:
        return 'Uses sequential numbers (e.g., movie-01.mkv, movie-02.mkv)';
      case FilenameSuffixStrategy.profileNameAndIndex:
        return 'Combines profile name and number (e.g., movie-HighQuality_01.mkv)';
    }
  }
}

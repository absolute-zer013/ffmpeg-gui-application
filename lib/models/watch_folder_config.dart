import 'export_profile.dart';

/// Configuration for watch folder functionality
class WatchFolderConfig {
  /// Path to the folder to watch
  final String folderPath;

  /// Whether watch folder is enabled
  final bool enabled;

  /// File patterns to watch (e.g., '*.mkv', '*.mp4')
  final List<String> filePatterns;

  /// Whether to automatically add matching files to the list
  final bool autoAdd;

  /// Whether to automatically export added files
  final bool autoExport;

  /// Profile to use for auto-export (if autoExport is true)
  final ExportProfile? autoExportProfile;

  /// Whether to watch subdirectories
  final bool recursive;

  const WatchFolderConfig({
    required this.folderPath,
    this.enabled = false,
    this.filePatterns = const ['*.mkv', '*.mp4'],
    this.autoAdd = true,
    this.autoExport = false,
    this.autoExportProfile,
    this.recursive = false,
  });

  WatchFolderConfig copyWith({
    String? folderPath,
    bool? enabled,
    List<String>? filePatterns,
    bool? autoAdd,
    bool? autoExport,
    ExportProfile? autoExportProfile,
    bool? recursive,
  }) {
    return WatchFolderConfig(
      folderPath: folderPath ?? this.folderPath,
      enabled: enabled ?? this.enabled,
      filePatterns: filePatterns ?? this.filePatterns,
      autoAdd: autoAdd ?? this.autoAdd,
      autoExport: autoExport ?? this.autoExport,
      autoExportProfile: autoExportProfile ?? this.autoExportProfile,
      recursive: recursive ?? this.recursive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'folderPath': folderPath,
      'enabled': enabled,
      'filePatterns': filePatterns,
      'autoAdd': autoAdd,
      'autoExport': autoExport,
      'autoExportProfile': autoExportProfile?.toJson(),
      'recursive': recursive,
    };
  }

  factory WatchFolderConfig.fromJson(Map<String, dynamic> json) {
    return WatchFolderConfig(
      folderPath: json['folderPath'] as String,
      enabled: json['enabled'] as bool? ?? false,
      filePatterns:
          (json['filePatterns'] as List?)?.map((e) => e.toString()).toList() ??
              ['*.mkv', '*.mp4'],
      autoAdd: json['autoAdd'] as bool? ?? true,
      autoExport: json['autoExport'] as bool? ?? false,
      autoExportProfile: json['autoExportProfile'] != null
          ? ExportProfile.fromJson(
              json['autoExportProfile'] as Map<String, dynamic>)
          : null,
      recursive: json['recursive'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchFolderConfig &&
          runtimeType == other.runtimeType &&
          folderPath == other.folderPath &&
          enabled == other.enabled &&
          autoAdd == other.autoAdd &&
          autoExport == other.autoExport &&
          recursive == other.recursive;

  @override
  int get hashCode =>
      folderPath.hashCode ^
      enabled.hashCode ^
      autoAdd.hashCode ^
      autoExport.hashCode ^
      recursive.hashCode;
}

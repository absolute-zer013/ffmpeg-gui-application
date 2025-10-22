import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/batch_configuration.dart';
import '../models/file_item.dart';
import '../models/export_profile.dart';
import '../models/auto_detect_rule.dart';
import '../models/rename_pattern.dart';

/// Service for importing and exporting batch configurations
class ConfigService {
  /// Export current configuration to a JSON file
  static Future<File> exportConfiguration({
    required String filePath,
    required String name,
    required String description,
    required List<FileItem> files,
    required List<ExportProfile> profiles,
    required List<AutoDetectRule> rules,
    RenamePattern? defaultRenamePattern,
    String outputFormat = 'mkv',
    int maxConcurrentExports = 2,
    bool enableVerification = true,
  }) async {
    // Create batch configuration
    final config = BatchConfiguration(
      id: _generateConfigId(),
      name: name,
      description: description,
      files: files.map((f) => _fileItemToConfig(f)).toList(),
      profiles: profiles,
      rules: rules,
      defaultRenamePattern: defaultRenamePattern,
      outputFormat: outputFormat,
      maxConcurrentExports: maxConcurrentExports,
      enableVerification: enableVerification,
    );

    // Convert to JSON
    final jsonString = JsonEncoder.withIndent('  ').convert(config.toJson());

    // Write to file
    final file = File(filePath);
    await file.writeAsString(jsonString);

    return file;
  }

  /// Import configuration from a JSON file
  static Future<BatchConfiguration> importConfiguration(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('Configuration file not found: $filePath');
    }

    // Read file
    final jsonString = await file.readAsString();

    // Parse JSON
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    // Create configuration
    return BatchConfiguration.fromJson(json);
  }

  /// Validate a configuration file
  static Future<bool> validateConfiguration(String filePath) async {
    try {
      final config = await importConfiguration(filePath);
      return config.name.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get configuration info without fully loading it
  static Future<Map<String, dynamic>> getConfigurationInfo(
      String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      return {
        'name': json['name'] ?? 'Unknown',
        'description': json['description'] ?? '',
        'fileCount': (json['files'] as List?)?.length ?? 0,
        'profileCount': (json['profiles'] as List?)?.length ?? 0,
        'ruleCount': (json['rules'] as List?)?.length ?? 0,
        'createdAt': json['createdAt'],
        'modifiedAt': json['modifiedAt'],
        'version': json['version'] ?? 'unknown',
      };
    } catch (e) {
      return {
        'error': 'Failed to read configuration: $e',
      };
    }
  }

  /// Generate a default filename for export
  static String generateDefaultFilename(String configName) {
    // Sanitize config name
    final sanitized = configName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');

    final timestamp = DateTime.now().toIso8601String().split('T').first;
    return '${sanitized}_$timestamp.json';
  }

  /// Convert FileItem to FileConfiguration
  static FileConfiguration _fileItemToConfig(FileItem file) {
    return FileConfiguration(
      path: file.path,
      outputName: file.outputName,
      selectedVideoTracks: file.selectedVideo,
      selectedAudioTracks: file.selectedAudio,
      selectedSubtitleTracks: file.selectedSubtitles,
      defaultVideo: file.defaultVideo,
      defaultAudio: file.defaultAudio,
      defaultSubtitle: file.defaultSubtitle,
      renamePattern: file.renamePattern,
      renameIndex: file.renameIndex,
      renameEpisode: file.renameEpisode,
      renameSeason: file.renameSeason,
      renameYear: file.renameYear,
    );
  }

  /// Apply configuration to file items
  /// Returns a list of files that match the configuration
  static List<FileItem> applyConfiguration(
    BatchConfiguration config,
    List<FileItem> existingFiles,
  ) {
    final updatedFiles = <FileItem>[];

    for (final fileConfig in config.files) {
      // Try to find matching file in existing files
      final matchingFile = existingFiles.firstWhere(
        (f) => path.basename(f.path) == path.basename(fileConfig.path),
        orElse: () => existingFiles.firstWhere(
          (f) => f.path == fileConfig.path,
          orElse: () => existingFiles.first,
        ),
      );

      // Apply configuration to file
      matchingFile.outputName = fileConfig.outputName ?? matchingFile.name;
      matchingFile.selectedVideo = Set.from(fileConfig.selectedVideoTracks);
      matchingFile.selectedAudio = Set.from(fileConfig.selectedAudioTracks);
      matchingFile.selectedSubtitles = Set.from(fileConfig.selectedSubtitleTracks);
      matchingFile.defaultVideo = fileConfig.defaultVideo;
      matchingFile.defaultAudio = fileConfig.defaultAudio;
      matchingFile.defaultSubtitle = fileConfig.defaultSubtitle;
      matchingFile.renamePattern = fileConfig.renamePattern;
      matchingFile.renameIndex = fileConfig.renameIndex;
      matchingFile.renameEpisode = fileConfig.renameEpisode;
      matchingFile.renameSeason = fileConfig.renameSeason;
      matchingFile.renameYear = fileConfig.renameYear;

      updatedFiles.add(matchingFile);
    }

    return updatedFiles;
  }

  /// Generate a unique ID for a configuration
  static String _generateConfigId() {
    return 'config_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get suggested save location for configurations
  static Future<String> getDefaultConfigDirectory() async {
    // Use user's home directory + .ffmpeg_configs
    final home = Platform.environment['USERPROFILE'] ?? 
                 Platform.environment['HOME'] ?? 
                 Directory.current.path;
    
    final configDir = path.join(home, '.ffmpeg_configs');
    
    // Create directory if it doesn't exist
    final dir = Directory(configDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    return configDir;
  }
}

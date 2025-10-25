import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recent_file.dart';

/// Service for managing recently processed files
class RecentFilesService {
  static const String _recentFilesKey = 'recent_files';
  static const int _maxRecentFiles = 20;

  /// Load all recent files
  static Future<List<RecentFile>> loadRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final recentFilesJson = prefs.getString(_recentFilesKey);

    if (recentFilesJson == null || recentFilesJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(recentFilesJson);
      return decoded.map((fileJson) => RecentFile.fromJson(fileJson)).toList();
    } catch (e) {
      // If parsing fails, return empty list
      return [];
    }
  }

  /// Add a file to recent files list
  static Future<void> addRecentFile(String filePath) async {
    final recentFiles = await loadRecentFiles();

    // Remove if already exists
    recentFiles.removeWhere((file) => file.path == filePath);

    // Add to the beginning
    recentFiles.insert(
      0,
      RecentFile(path: filePath, processedAt: DateTime.now()),
    );

    // Keep only the most recent files
    if (recentFiles.length > _maxRecentFiles) {
      recentFiles.removeRange(_maxRecentFiles, recentFiles.length);
    }

    await _saveRecentFiles(recentFiles);
  }

  /// Remove a file from recent files list
  static Future<void> removeRecentFile(String filePath) async {
    final recentFiles = await loadRecentFiles();
    recentFiles.removeWhere((file) => file.path == filePath);
    await _saveRecentFiles(recentFiles);
  }

  /// Clear all recent files
  static Future<void> clearRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentFilesKey);
  }

  /// Get recent files that still exist on disk
  static Future<List<RecentFile>> getExistingRecentFiles() async {
    final recentFiles = await loadRecentFiles();
    final existingFiles = <RecentFile>[];

    for (final file in recentFiles) {
      if (await File(file.path).exists()) {
        existingFiles.add(file);
      }
    }

    // If any files were removed, save the updated list
    if (existingFiles.length != recentFiles.length) {
      await _saveRecentFiles(existingFiles);
    }

    return existingFiles;
  }

  static Future<void> _saveRecentFiles(List<RecentFile> recentFiles) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(recentFiles.map((f) => f.toJson()).toList());
    await prefs.setString(_recentFilesKey, encoded);
  }
}

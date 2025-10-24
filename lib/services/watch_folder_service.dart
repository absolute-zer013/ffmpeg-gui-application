import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import '../models/watch_folder_config.dart';

/// Service for monitoring a folder and automatically processing new files
class WatchFolderService {
  WatchFolderConfig? _config;
  StreamSubscription<FileSystemEvent>? _watcherSubscription;
  final Set<String> _processedFiles = {};
  
  /// Callback for when a new file is detected
  final void Function(String filePath)? onFileDetected;
  
  /// Callback for errors
  final void Function(String error)? onError;

  WatchFolderService({
    this.onFileDetected,
    this.onError,
  });

  /// Starts watching a folder with the given configuration
  Future<void> startWatching(WatchFolderConfig config) async {
    // Stop any existing watcher
    await stopWatching();

    _config = config;

    if (!config.enabled) {
      return;
    }

    final directory = Directory(config.folderPath);
    
    if (!await directory.exists()) {
      onError?.call('Watch folder does not exist: ${config.folderPath}');
      return;
    }

    try {
      // Watch for file system events
      final watcher = directory.watch(recursive: config.recursive);
      
      _watcherSubscription = watcher.listen(
        (event) => _handleFileSystemEvent(event),
        onError: (error) => onError?.call('Watch error: $error'),
      );

      // Process existing files on startup if autoAdd is enabled
      if (config.autoAdd) {
        await _processExistingFiles(directory, config);
      }
    } catch (e) {
      onError?.call('Failed to start watching: $e');
    }
  }

  /// Stops watching the folder
  Future<void> stopWatching() async {
    await _watcherSubscription?.cancel();
    _watcherSubscription = null;
    _config = null;
    _processedFiles.clear();
  }

  /// Handles file system events
  void _handleFileSystemEvent(FileSystemEvent event) {
    if (_config == null) return;

    // Only process file creation and modification events
    if (event.type != FileSystemEvent.create &&
        event.type != FileSystemEvent.modify) {
      return;
    }

    final filePath = event.path;

    // Check if file matches patterns
    if (!_matchesPatterns(filePath, _config!.filePatterns)) {
      return;
    }

    // Check if already processed
    if (_processedFiles.contains(filePath)) {
      return;
    }

    // Check if file is complete (not still being written)
    _checkFileComplete(filePath).then((isComplete) {
      if (isComplete) {
        _processedFiles.add(filePath);
        onFileDetected?.call(filePath);
      }
    });
  }

  /// Processes existing files in the directory
  Future<void> _processExistingFiles(
    Directory directory,
    WatchFolderConfig config,
  ) async {
    try {
      final entities = directory.listSync(recursive: config.recursive);
      
      for (final entity in entities) {
        if (entity is File) {
          final filePath = entity.path;
          
          if (_matchesPatterns(filePath, config.filePatterns) &&
              !_processedFiles.contains(filePath)) {
            _processedFiles.add(filePath);
            onFileDetected?.call(filePath);
          }
        }
      }
    } catch (e) {
      onError?.call('Error processing existing files: $e');
    }
  }

  /// Checks if a file matches any of the patterns
  bool _matchesPatterns(String filePath, List<String> patterns) {
    final fileName = path.basename(filePath).toLowerCase();
    
    for (final pattern in patterns) {
      final regexPattern = pattern
          .replaceAll('.', r'\.')
          .replaceAll('*', '.*')
          .replaceAll('?', '.');
      
      if (RegExp('^$regexPattern\$').hasMatch(fileName.toLowerCase())) {
        return true;
      }
    }
    
    return false;
  }

  /// Checks if a file is complete (not still being written)
  Future<bool> _checkFileComplete(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        return false;
      }

      // Get initial size
      final initialSize = await file.length();
      
      // Wait a short period
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check if size changed
      if (!await file.exists()) {
        return false;
      }
      
      final finalSize = await file.length();
      
      // File is complete if size hasn't changed
      return initialSize == finalSize;
    } catch (e) {
      return false;
    }
  }

  /// Gets the current configuration
  WatchFolderConfig? get config => _config;

  /// Checks if currently watching
  bool get isWatching => _watcherSubscription != null;

  /// Gets the list of processed files
  Set<String> get processedFiles => Set.unmodifiable(_processedFiles);

  /// Clears the processed files list
  void clearProcessedFiles() {
    _processedFiles.clear();
  }

  /// Disposes the service
  Future<void> dispose() async {
    await stopWatching();
  }
}

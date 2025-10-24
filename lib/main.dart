import 'dart:io';
import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

import 'models/export_profile.dart';
import 'models/file_item.dart';
import 'models/auto_detect_rule.dart';
import 'models/codec_options.dart';
import 'models/recent_file.dart';
import 'services/profile_service.dart';
import 'services/ffprobe_service.dart';
import 'services/ffmpeg_export_service.dart';
import 'services/verification_service.dart';
import 'services/rule_service.dart';
import 'services/notification_service.dart';
import 'services/recent_files_service.dart';
// import 'models/quality_preset.dart'; // Not used in the codec dialogs anymore
import 'utils/file_utils.dart';
import 'widgets/file_card.dart';
import 'widgets/audio_batch_card.dart';
import 'widgets/subtitle_batch_card.dart';
import 'widgets/codec_settings_dialog.dart';
import 'widgets/batch_rename_dialog.dart';
import 'widgets/quick_rename_dialog.dart';
import 'models/rename_pattern.dart';

void main() {
  runApp(const MyApp());
}

/// Top level widget for the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FFmpeg Filter App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const MyHomePage(),
    );
  }
}

/// Main page that allows picking files and running the filter.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // List of file items with their track selections.
  final List<FileItem> _files = [];
  String _log = '';
  bool _running = false;
  bool _batchMode = false;
  bool _dragging = false;
  bool _ffmpegAvailable = false;
  String? _lastOutputDir;
  int _maxConcurrentExports = 2;
  String _outputFormat = 'mkv';
  final List<Process> _activeProcesses = [];
  List<ExportProfile> _profiles = [];
  ExportProfile? _selectedProfile;
  bool _enableVerification = true;
  List<AutoDetectRule> _rules = [];
  final bool _autoApplyRules = true;
  bool _enableDesktopNotifications = true;
  bool _autoFixCompatibility = true;
  List<RecentFile> _recentFiles = [];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadProfiles();
    _loadRules();
    _loadRecentFiles();
    // Check FFmpeg and show dialog after check completes, but skip during tests
    final isRunningTests = Platform.environment.containsKey('FLUTTER_TEST');
    if (!isRunningTests) {
      _checkFFmpegAndShowDialog();
    }
  }

  Future<void> _checkFFmpegAndShowDialog() async {
    await _checkFFmpeg();
    // Schedule dialog after frame is built
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFFmpegCheckDialog();
      });
    }
  }

  Future<void> _checkFFmpeg() async {
    try {
      final result = await Process.run('ffmpeg', ['-version']);
      setState(() {
        _ffmpegAvailable = result.exitCode == 0;
      });
      if (_ffmpegAvailable) {
        _appendLog('FFmpeg detected successfully');
      }
    } catch (e) {
      setState(() {
        _ffmpegAvailable = false;
      });
      _appendLog(
          'ERROR: FFmpeg not found. Please install FFmpeg and add it to PATH');
    }
  }

  void _showFFmpegCheckDialog() {
    if (!_ffmpegAvailable && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('FFmpeg Not Detected'),
          content: const Text(
            'FFmpeg is not installed or not found in your system PATH.\n\n'
            'To use this application, you need to:\n\n'
            '1. Download FFmpeg from https://ffmpeg.org/download.html\n'
            '2. Extract it to a folder\n'
            '3. Add the folder to your system PATH environment variable\n'
            '4. Restart this application\n\n'
            'Some features will be disabled until FFmpeg is properly installed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retry'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                // Open FFmpeg download page
                _openFFmpegDownloadPage();
              },
              child: const Text('Download FFmpeg'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openFFmpegDownloadPage() async {
    const url = 'https://ffmpeg.org/download.html';
    try {
      await Process.run('start', [url], runInShell: true);
    } catch (e) {
      _appendLog('ERROR: Could not open FFmpeg download page: $e');
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastOutputDir = prefs.getString('lastOutputDir');
      _maxConcurrentExports = prefs.getInt('maxConcurrentExports') ?? 2;
      _outputFormat = prefs.getString('outputFormat') ?? 'mkv';
      _enableVerification = prefs.getBool('enableVerification') ?? true;
      _enableDesktopNotifications =
          prefs.getBool('enableDesktopNotifications') ?? true;
      _autoFixCompatibility = prefs.getBool('autoFixCompatibility') ?? true;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastOutputDir != null) {
      await prefs.setString('lastOutputDir', _lastOutputDir!);
    }
    await prefs.setInt('maxConcurrentExports', _maxConcurrentExports);
    await prefs.setString('outputFormat', _outputFormat);
    await prefs.setBool('enableVerification', _enableVerification);
    await prefs.setBool(
        'enableDesktopNotifications', _enableDesktopNotifications);
    await prefs.setBool('autoFixCompatibility', _autoFixCompatibility);
  }

  Future<void> _loadProfiles() async {
    final profiles = await ProfileService.loadProfiles();
    setState(() {
      _profiles = profiles;
    });
  }

  Future<void> _loadRules() async {
    final rules = await RuleService.loadRules();
    setState(() {
      _rules = rules;
    });
  }

  Future<void> _loadRecentFiles() async {
    final recentFiles = await RecentFilesService.getExistingRecentFiles();
    setState(() {
      _recentFiles = recentFiles;
    });
  }

  Future<void> _addFileToRecents(String filePath) async {
    await RecentFilesService.addRecentFile(filePath);
    await _loadRecentFiles();
  }

  Future<void> _loadRecentFile(String filePath) async {
    if (!await File(filePath).exists()) {
      _appendLog('ERROR: File not found: $filePath');
      await RecentFilesService.removeRecentFile(filePath);
      await _loadRecentFiles();
      return;
    }

    // Add to files list and probe
    await _handleFilePaths([filePath]);
  }

  void _showRecentFilesMenu(BuildContext context, Offset position) {
    if (_recentFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No recent files'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        ..._recentFiles.take(10).map((recentFile) {
          final fileName = path.basename(recentFile.path);
          return PopupMenuItem<String>(
            value: recentFile.path,
            child: SizedBox(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    recentFile.path,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'clear',
          child: Row(
            children: [
              Icon(Icons.clear_all, size: 20),
              SizedBox(width: 8),
              Text('Clear Recent Files'),
            ],
          ),
        ),
      ],
    ).then((value) async {
      if (value == 'clear') {
        await RecentFilesService.clearRecentFiles();
        await _loadRecentFiles();
        _appendLog('Recent files cleared');
      } else if (value != null) {
        await _loadRecentFile(value);
      }
    });
  }

  Future<void> _saveCurrentAsProfile() async {
    if (_files.isEmpty) {
      _appendLog('ERROR: No files loaded. Add files before saving a profile.');
      return;
    }

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Current Configuration as Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Profile Name',
                hintText: 'e.g., Japanese Audio Only',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g., Keeps only Japanese audio',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      // Collect current audio language selections
      final selectedAudioLanguages = <String>{};
      for (final file in _files) {
        for (final track in file.audioTracks) {
          if (file.selectedAudio.contains(track.position)) {
            selectedAudioLanguages.add(track.language);
          }
        }
      }

      // Collect current subtitle description selections
      final selectedSubtitleDescriptions = <String>{};
      String? defaultSubtitleDescription;
      for (final file in _files) {
        for (final track in file.subtitleTracks) {
          if (file.selectedSubtitles.contains(track.position)) {
            selectedSubtitleDescriptions.add(track.description);
            if (file.defaultSubtitle == track.position) {
              defaultSubtitleDescription = track.description;
            }
          }
        }
      }

      final profile = ExportProfile(
        id: ProfileService.generateProfileId(),
        name: nameController.text,
        description: descriptionController.text,
        selectedAudioLanguages: selectedAudioLanguages,
        selectedSubtitleDescriptions: selectedSubtitleDescriptions,
        defaultSubtitleDescription: defaultSubtitleDescription,
      );

      await ProfileService.saveProfile(profile);
      await _loadProfiles();
      _appendLog('Profile saved: ${profile.name}');
    }
  }

  Future<void> _applyProfile(ExportProfile profile) async {
    if (_files.isEmpty) {
      _appendLog(
          'No files loaded. Add files to apply profile: ${profile.name}');
      return;
    }

    setState(() {
      _selectedProfile = profile;

      // Apply audio language selections
      for (final file in _files) {
        file.selectedAudio.clear();
        for (int i = 0; i < file.audioTracks.length; i++) {
          final track = file.audioTracks[i];
          if (profile.selectedAudioLanguages.contains(track.language)) {
            file.selectedAudio.add(i);
          }
        }
      }

      // Apply subtitle description selections
      for (final file in _files) {
        file.selectedSubtitles.clear();
        file.defaultSubtitle = null;

        for (int i = 0; i < file.subtitleTracks.length; i++) {
          final track = file.subtitleTracks[i];
          if (profile.selectedSubtitleDescriptions
              .contains(track.description)) {
            file.selectedSubtitles.add(i);
            if (profile.defaultSubtitleDescription == track.description) {
              file.defaultSubtitle = i;
            }
          }
        }
      }
    });

    _appendLog('Applied profile: ${profile.name}');
  }

  void _showProfileManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Manage Profiles'),
          content: SizedBox(
            width: 500,
            height: 400,
            child: _profiles.isEmpty
                ? const Center(
                    child: Text(
                        'No profiles saved yet.\nSave your current configuration to create a profile.'),
                  )
                : ListView.builder(
                    itemCount: _profiles.length,
                    itemBuilder: (context, index) {
                      final profile = _profiles[index];
                      return Card(
                        child: ListTile(
                          title: Text(profile.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (profile.description.isNotEmpty)
                                Text(profile.description),
                              const SizedBox(height: 4),
                              Text(
                                'Audio: ${profile.selectedAudioLanguages.join(", ")}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Subtitles: ${profile.selectedSubtitleDescriptions.join(", ")}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check),
                                tooltip: 'Apply Profile',
                                onPressed: () {
                                  Navigator.pop(context);
                                  _applyProfile(profile);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Delete Profile',
                                onPressed: () async {
                                  await ProfileService.deleteProfile(
                                      profile.id);
                                  await _loadProfiles();
                                  setDialogState(() {});
                                  setState(() {
                                    if (_selectedProfile?.id == profile.id) {
                                      _selectedProfile = null;
                                    }
                                  });
                                  _appendLog(
                                      'Deleted profile: ${profile.name}');
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBatchVideoCodecDialog() async {
    if (_files.isEmpty) {
      _appendLog(
          'ERROR: No files loaded. Add files before applying batch codec settings.');
      return;
    }

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => CodecSettingsDialog(
        initialVideoCodec: null,
        isVideoTrack: true,
        showBatchOptions: true,
        fileCount: _files.length,
      ),
    );

    if (result != null && result['applyToAll'] == true) {
      setState(() {
        // Apply selected video codec (if any) to all video tracks in each file
        final codecSettings =
            result['codecSettings'] as CodecConversionSettings?;
        if (codecSettings?.videoCodec != null) {
          for (final file in _files) {
            for (final track in file.videoTracks) {
              file.codecSettings[track.streamIndex] = CodecConversionSettings(
                videoCodec: codecSettings!.videoCodec,
              );
            }
          }
          _appendLog(
              'Applied video codec (${codecSettings!.videoCodec!.displayName}) to ${_files.length} file(s)');
        }
      });
    }
  }

  Future<void> _showBatchAudioCodecDialog() async {
    if (_files.isEmpty) {
      _appendLog(
          'ERROR: No files loaded. Add files before applying batch codec settings.');
      return;
    }

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => CodecSettingsDialog(
        initialAudioCodec: null,
        initialAudioBitrate: null,
        initialAudioChannels: null,
        initialAudioSampleRate: null,
        isVideoTrack: false,
        showBatchOptions: true,
        fileCount: _files.length,
      ),
    );

    if (result != null && result['applyToAll'] == true) {
      setState(() {
        final codecSettings =
            result['codecSettings'] as CodecConversionSettings?;
        if (codecSettings != null) {
          for (final file in _files) {
            // Apply codec settings to all audio tracks in each file
            for (final track in file.audioTracks) {
              file.codecSettings[track.streamIndex] = CodecConversionSettings(
                audioCodec: codecSettings.audioCodec,
                audioBitrate: codecSettings.audioBitrate,
                audioChannels: codecSettings.audioChannels,
                audioSampleRate: codecSettings.audioSampleRate,
              );
            }
          }
        }
      });
      _appendLog('Applied audio codec settings to ${_files.length} file(s)');
    }
  }

  Future<void> _showBatchRenameDialog() async {
    if (_files.isEmpty) {
      _appendLog('ERROR: No files loaded. Add files before batch renaming.');
      return;
    }

    final result = await showBatchRenameDialog(
      context: context,
      paths: _files.map((f) => f.path).toList(),
    );

    if (result == null) return;

    // Apply rename parameters to files
    setState(() {
      for (int i = 0; i < _files.length; i++) {
        final file = _files[i];
        final mappedName = result.plan.renameMapping[file.path];
        file.renamePattern = RenamePattern(
          name: 'Batch',
          pattern: result.pattern,
          isCustom: true,
        );
        file.renameIndex = result.startIndex + i;
        file.renameEpisode =
            result.episodeStart != null ? (result.episodeStart! + i) : null;
        file.renameSeason = result.season;
        file.renameYear = result.year;

        if (mappedName != null) {
          // Update UI field to reflect preview
          file.outputName = mappedName;
        }
      }
    });

    _appendLog('Applied batch rename pattern to ${_files.length} file(s)');
  }

  Future<void> _showQuickRenameDialog() async {
    if (_files.isEmpty) {
      _appendLog('ERROR: No files loaded. Add files before quick renaming.');
      return;
    }

    final currentNames =
        _files.map((f) => f.outputName).toList(growable: false);
    final newNames = await showQuickRenameDialog(
      context: context,
      names: currentNames,
    );

    if (newNames == null) return;

    setState(() {
      for (var i = 0; i < _files.length; i++) {
        _files[i].outputName = newNames[i];
        // Ensure export uses the quick-renamed name (not a stale pattern)
        _files[i].renamePattern = null;
      }
    });

    _appendLog('Applied quick rename to ${_files.length} file(s)');
  }

  void _appendLog(String message) {
    final now = DateTime.now();
    final timestamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    setState(() {
      _log = '[$timestamp] $message\n$_log';
    });
  }

  Future<void> _saveLogToFile() async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Log',
        fileName: 'export_log_${DateTime.now().millisecondsSinceEpoch}.txt',
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null) {
        await File(result).writeAsString(_log);
        _appendLog('Log saved to: $result');
      }
    } catch (e) {
      _appendLog('ERROR: Failed to save log: $e');
    }
  }

  void _clearFiles() {
    setState(() {
      _files.clear();
      _batchMode = false;
      _appendLog('Cleared all files');
    });
  }

  void _resetSelections() {
    setState(() {
      for (final file in _files) {
        file.selectedAudio = file.audioTracks.asMap().keys.toSet();
        file.selectedSubtitles = file.subtitleTracks.isNotEmpty ? {0} : {};
        file.defaultSubtitle = file.subtitleTracks.isNotEmpty ? 0 : null;
      }
      _appendLog('Reset all selections to default');
    });
  }

  Future<void> _cancelExport() async {
    for (final process in _activeProcesses) {
      process.kill();
    }
    _activeProcesses.clear();

    setState(() {
      _running = false;
      for (final file in _files) {
        if (file.exportStatus == 'processing') {
          file.exportStatus = 'cancelled';
        }
      }
    });
    // Create per-file log stubs for cancelled items so a .log is always produced
    try {
      if (_lastOutputDir != null) {
        final dir = _lastOutputDir!;
        final ext = _outputFormat;
        final now = DateTime.now();
        for (final file in _files) {
          if (file.exportStatus == 'cancelled') {
            final outputFileName =
                '${path.basenameWithoutExtension(file.outputName)}.$ext';
            final outPath = path.join(dir, outputFileName);
            final logPath = path.setExtension(outPath, '.log');
            final buf = StringBuffer()
              ..writeln('FFmpeg Export Log')
              ..writeln('Source: ${file.path}')
              ..writeln('Destination dir: $dir')
              ..writeln('Planned output: $outputFileName')
              ..writeln('Started: $now')
              ..writeln('Status: Cancelled by user at $now');
            File(logPath).writeAsStringSync(buf.toString());
          }
        }
      }
    } catch (_) {
      // Best-effort: ignore log write errors on cancel
    }
    _appendLog('Export cancelled by user');
  }

  // Collect all unique audio languages across files.
  /// Opens a file picker to allow selection of multiple MKV files and probes their streams.
  Future<void> _selectFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mkv', 'mp4', 'avi', 'mov'],
    );
    if (result == null) return;
    await _addFiles(
        result.files.map((f) => f.path!).where((p) => p.isNotEmpty).toList());
  }

  Future<void> _addFiles(List<String> paths) async {
    _appendLog('Adding ${paths.length} file(s)...');
    for (final filePath in paths) {
      try {
        final item = await _probeFile(filePath);

        // Apply auto-detect rules if enabled
        if (_autoApplyRules && _rules.isNotEmpty) {
          RuleService.applyRules(item, _rules);
          final summary = RuleService.getRuleSummary(item, _rules);
          _appendLog('Auto-detect rules applied: $summary');
        }

        setState(() {
          _files.add(item);
        });
        _appendLog('Added: ${item.name}');
      } catch (e) {
        _appendLog('ERROR: Failed to probe $filePath: $e');
      }
    }
    // Update batch mode automatically based on file count
    setState(() {
      _batchMode = _files.length > 1;
    });
  }

  Future<void> _handleDrop(List<String> paths) async {
    final validPaths = paths
        .where((p) =>
            p.toLowerCase().endsWith('.mkv') ||
            p.toLowerCase().endsWith('.mp4') ||
            p.toLowerCase().endsWith('.avi') ||
            p.toLowerCase().endsWith('.mov'))
        .toList();

    if (validPaths.isEmpty) {
      _appendLog('ERROR: No valid video files in drop');
      return;
    }

    await _addFiles(validPaths);
  }

  /// Probes the given MKV file for audio and subtitle streams using ffprobe.
  Future<FileItem> _probeFile(String path) async {
    return await FFprobeService.probeFile(path);
  }

  /// Runs the FFmpeg filter on all files with the user's selections. Allows choosing an output directory.
  Future<void> _runFilter() async {
    if (!_ffmpegAvailable) {
      _appendLog('ERROR: FFmpeg not available. Please install FFmpeg.');
      return;
    }

    if (_files.isEmpty) {
      _appendLog('ERROR: Please select files first.');
      return;
    }

    // Show export summary
    final summary = _generateExportSummary();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Summary'),
        content: SingleChildScrollView(child: Text(summary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Next'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Ask user for output directory - always show dialog for confirmation
    if (!mounted) return; // Ensure context is valid after async gap
    final outDirPath = await showDialog<String>(
      context: context,
      builder: (context) => _buildSaveToDialog(),
    );

    if (outDirPath == null) {
      _appendLog('Export cancelled - no output directory selected');
      return;
    }

    final outDir = Directory(outDirPath);
    setState(() {
      _lastOutputDir = outDirPath;
      _running = true;
      for (final file in _files) {
        file.exportStatus = 'pending';
        file.exportProgress = 0.0;
      }
    });

    _savePreferences();
    _appendLog('Starting export of ${_files.length} file(s) to: $outDirPath');
    _appendLog(
        'Max concurrent: $_maxConcurrentExports, Format: $_outputFormat');

    final startTime = DateTime.now();

    // Process files in parallel batches
    for (var i = 0; i < _files.length; i += _maxConcurrentExports) {
      final batch = _files.skip(i).take(_maxConcurrentExports).toList();
      await Future.wait(batch.map((file) => _exportFile(file, outDir)));
    }

    setState(() {
      _running = false;
    });

    final duration = DateTime.now().difference(startTime);
    final successCount =
        _files.where((f) => f.exportStatus == 'completed').length;
    final failedCount = _files.where((f) => f.exportStatus == 'failed').length;
    final cancelledCount =
        _files.where((f) => f.exportStatus == 'cancelled').length;

    _appendLog(
        'Export finished: $successCount/${_files.length} files successful');

    // Show enhanced notification
    _showEnhancedNotification(
      successCount: successCount,
      failedCount: failedCount,
      cancelledCount: cancelledCount,
      totalFiles: _files.length,
      duration: duration,
    );
  }

  String _generateExportSummary() {
    return FFmpegExportService.generateExportSummary(_files, _outputFormat);
  }

  Future<void> _exportFile(FileItem item, Directory outDir) async {
    setState(() {
      item.exportStatus = 'processing';
      item.exportProgress = 0.0;
    });

    _appendLog('Processing: ${item.name}');

    try {
      final result = await FFmpegExportService.exportFile(
        item: item,
        outputDir: outDir,
        outputFormat: _outputFormat,
        onProgress: (progress) {
          setState(() {
            item.exportProgress = progress;
          });
        },
        onLog: (msg) => _appendLog(msg),
        onProcessStarted: (process, stage) {
          // Register live process immediately for cancellation
          setState(() {
            item.currentProcess = process;
            _activeProcesses.add(process);
          });
          // Ensure cleanup after process finishes
          process.exitCode.then((_) {
            if (!mounted) return;
            setState(() {
              _activeProcesses.remove(process);
              if (identical(item.currentProcess, process)) {
                item.currentProcess = null;
              }
            });
          });
        },
        autoFixIncompat: _autoFixCompatibility,
      );

      // Process lifecycle is handled by onProcessStarted callback above.

      if (result.success) {
        setState(() {
          item.exportStatus = 'completed';
          item.exportProgress = 1.0;
        });
        _appendLog('✓ Completed: ${item.name}');

        // Add to recent files
        await _addFileToRecents(item.path);

        // Run verification if enabled
        if (_enableVerification) {
          _appendLog('Verifying: ${item.name}');
          final extension = _outputFormat;
          final outputFileName =
              '${path.basenameWithoutExtension(item.outputName)}.$extension';
          final outPath = path.join(outDir.path, outputFileName);

          final verificationResult = await VerificationService.verifyFile(
            filePath: outPath,
            expectedVideoStreams: item.selectedVideo.length,
            expectedAudioStreams: item.selectedAudio.length,
            expectedSubtitleStreams: item.selectedSubtitles.length,
          );

          setState(() {
            item.verificationPassed = verificationResult.passed;
            item.verificationMessage = verificationResult.message;
          });

          if (verificationResult.passed) {
            _appendLog('✓ Verification passed: ${item.name}');
          } else {
            _appendLog(
                '⚠ Verification warning: ${item.name} - ${verificationResult.message}');
          }
        }
      } else {
        setState(() {
          item.exportStatus = 'failed';
        });
        _appendLog(
            '✗ Failed: ${item.name}${result.errorMessage != null ? " (${result.errorMessage})" : ""}');
      }
    } catch (e) {
      setState(() {
        item.exportStatus = 'failed';
      });
      _appendLog('✗ Error processing ${item.name}: $e');
    }
  }

  void _showEnhancedNotification({
    required int successCount,
    required int failedCount,
    required int cancelledCount,
    required int totalFiles,
    required Duration duration,
  }) {
    final title = NotificationService.getNotificationTitle(
      successCount: successCount,
      totalFiles: totalFiles,
    );

    final message = NotificationService.formatExportSummary(
      totalFiles: totalFiles,
      successCount: successCount,
      failedCount: failedCount,
      cancelledCount: cancelledCount,
      duration: duration,
    );

    // Show in-app notification using SnackBar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title\n$message'),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }

    // Show desktop notification if enabled
    if (_enableDesktopNotifications) {
      final notificationType = NotificationService.getNotificationType(
        successCount: successCount,
        failedCount: failedCount,
        totalFiles: totalFiles,
      );

      NotificationService.showDesktopNotification(
        title: title,
        message: message,
        type: notificationType,
      );
    }
  }

  // Deprecated: in-app notifications handled by NotificationService.showDesktopNotification

  Widget _buildSaveToDialog() {
    final selectedPath = ValueNotifier<String?>(_lastOutputDir);

    return AlertDialog(
      title: const Text('Select Output Directory'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Where would you like to save the exported files?'),
            const SizedBox(height: 16),
            ValueListenableBuilder<String?>(
              valueListenable: selectedPath,
              builder: (context, path, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (path != null)
                    Container(
                      width: double.maxFinite,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Selected Directory:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            path,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.maxFinite,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final dirPath =
                            await FilePicker.platform.getDirectoryPath();
                        if (dirPath != null) {
                          selectedPath.value = dirPath;
                        }
                      },
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Browse...'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: selectedPath.value != null
              ? () => Navigator.pop(context, selectedPath.value)
              : null,
          child: const Text('Export'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (details) {
        if (_running) return; // ignore drag UI while running
        setState(() => _dragging = true);
      },
      onDragExited: (details) => setState(() => _dragging = false),
      onDragDone: (details) {
        // Ignore new drops while an export is running to avoid disturbing encoding
        if (_running) {
          setState(() => _dragging = false);
          return;
        }
        setState(() => _dragging = false);
        _handleDrop(details.files.map((f) => f.path).toList());
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('FFmpeg Export Tool'),
          actions: [
            if (!_ffmpegAvailable)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Chip(
                  label: Text('FFmpeg Not Found'),
                  backgroundColor: Colors.red,
                ),
              ),
            if (_recentFiles.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Recent Files',
                onPressed: _running
                    ? null
                    : () {
                        final RenderBox button =
                            context.findRenderObject() as RenderBox;
                        final RenderBox overlay = Navigator.of(context)
                            .overlay!
                            .context
                            .findRenderObject() as RenderBox;
                        final RelativeRect position = RelativeRect.fromRect(
                          Rect.fromPoints(
                            button.localToGlobal(button.size.bottomRight(Offset.zero),
                                ancestor: overlay),
                            button.localToGlobal(button.size.bottomRight(Offset.zero),
                                ancestor: overlay),
                          ),
                          Offset.zero & overlay.size,
                        );
                        _showRecentFilesMenu(
                          context,
                          Offset(position.left, position.top),
                        );
                      },
              ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: _running ? null : () => _showSettingsDialog(),
            ),
          ],
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File selection controls
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _running ? null : _selectFiles,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Add Files'),
                      ),
                      if (_files.isNotEmpty) ...[
                        OutlinedButton.icon(
                          onPressed: _running ? null : _clearFiles,
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Clear All'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _running ? null : _resetSelections,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset Selections'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _running ? null : _saveCurrentAsProfile,
                          icon: const Icon(Icons.save),
                          label: const Text('Save as Profile'),
                        ),
                      ],
                      if (_profiles.isNotEmpty || _files.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed:
                              _running ? null : _showProfileManagementDialog,
                          icon: const Icon(Icons.library_books),
                          label: Text(_selectedProfile != null
                              ? 'Profiles (${_selectedProfile!.name})'
                              : 'Profiles (${_profiles.length})'),
                        ),
                      if (_files.isNotEmpty)
                        Text(
                            '${_files.length} file(s) | ${FileUtils.formatBytes(_files.fold<int>(0, (sum, f) => sum + (f.fileSize ?? 0)))}'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Main content area - scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Empty state
                          if (_files.isEmpty)
                            SizedBox(
                              height: 300,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.file_upload,
                                        size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Drag & drop video files here\nor click "Add Files"',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Files and Batch side by side
                          if (_files.isNotEmpty)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // File list on the left
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: _files
                                        .map((file) => _buildFileCard(file))
                                        .toList(),
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Batch mode section on the right (fixed width)
                                SizedBox(
                                  width: 400,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CheckboxListTile(
                                        contentPadding: EdgeInsets.zero,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        title: const Text('Batch mode'),
                                        value: _batchMode,
                                        onChanged: _running
                                            ? null
                                            : (v) => setState(
                                                () => _batchMode = v ?? false),
                                      ),
                                      if (_batchMode) ...[
                                        const SizedBox(height: 8),
                                        // Batch Codec/Quality Actions
                                        Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Batch Codecs',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    OutlinedButton.icon(
                                                      onPressed: _running
                                                          ? null
                                                          : _showBatchVideoCodecDialog,
                                                      icon: const Icon(
                                                          Icons.video_settings),
                                                      label: const Text(
                                                          'Video Codec'),
                                                    ),
                                                    OutlinedButton.icon(
                                                      onPressed: _running
                                                          ? null
                                                          : _showBatchAudioCodecDialog,
                                                      icon: const Icon(
                                                          Icons.audio_file),
                                                      label: const Text(
                                                          'Audio Codec Settings'),
                                                    ),
                                                    OutlinedButton.icon(
                                                      onPressed: _running
                                                          ? null
                                                          : _showBatchRenameDialog,
                                                      icon: const Icon(Icons
                                                          .drive_file_rename_outline),
                                                      label: const Text(
                                                          'Batch Rename'),
                                                    ),
                                                    OutlinedButton.icon(
                                                      onPressed: _running
                                                          ? null
                                                          : _showQuickRenameDialog,
                                                      icon: const Icon(
                                                          Icons.text_fields),
                                                      label: const Text(
                                                          'Quick Rename'),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildAudioBatchCard(),
                                        const SizedBox(height: 8),
                                        _buildSubtitleBatchCard(),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          // Show batch mode section even when no files, so users can preconfigure
                          if (_files.isEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: const Text('Batch mode'),
                                  value: _batchMode,
                                  onChanged: _running
                                      ? null
                                      : (v) => setState(
                                          () => _batchMode = v ?? false),
                                ),
                                if (_batchMode) ...[
                                  const SizedBox(height: 8),
                                  // Batch Codec/Quality Actions
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Batch Codecs',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: _running
                                                    ? null
                                                    : _showBatchVideoCodecDialog,
                                                icon: const Icon(
                                                    Icons.video_settings),
                                                label:
                                                    const Text('Video Codec'),
                                              ),
                                              OutlinedButton.icon(
                                                onPressed: _running
                                                    ? null
                                                    : _showBatchAudioCodecDialog,
                                                icon: const Icon(
                                                    Icons.audio_file),
                                                label: const Text(
                                                    'Audio Codec Settings'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildAudioBatchCard(),
                                  const SizedBox(height: 8),
                                  _buildSubtitleBatchCard(),
                                ],
                              ],
                            ),

                          const SizedBox(height: 16),

                          // Export controls
                          Row(
                            children: [
                              FilledButton.icon(
                                onPressed: _running ||
                                        _files.isEmpty ||
                                        !_ffmpegAvailable
                                    ? null
                                    : _runFilter,
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Start Export'),
                              ),
                              const SizedBox(width: 8),
                              if (_running)
                                OutlinedButton.icon(
                                  onPressed: _cancelExport,
                                  icon: const Icon(Icons.stop),
                                  label: const Text('Cancel'),
                                ),
                              const SizedBox(width: 8),
                              if (_running) const CircularProgressIndicator(),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Log area - always visible
                          Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      const Text('Log',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const Spacer(),
                                      TextButton.icon(
                                        onPressed: _running
                                            ? null
                                            : () => setState(() => _log = ''),
                                        icon: const Icon(Icons.clear, size: 16),
                                        label: const Text('Clear'),
                                      ),
                                      TextButton.icon(
                                        onPressed:
                                            _running ? null : _saveLogToFile,
                                        icon: const Icon(Icons.save, size: 16),
                                        label: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 100,
                                    maxHeight: 200,
                                  ),
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SelectableText(
                                      _log.isEmpty
                                          ? 'No log messages yet...'
                                          : _log,
                                      style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_dragging)
              Container(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    // ignore: deprecated_member_use
                    .withOpacity(0.1),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.file_download,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 16),
                          Text('Drop files here',
                              style: Theme.of(context).textTheme.headlineSmall),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Parallel Exports: $_maxConcurrentExports',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _maxConcurrentExports.toDouble(),
                min: 1,
                max: 8,
                divisions: 7,
                label: '$_maxConcurrentExports',
                onChanged: (value) {
                  setState(() {
                    _maxConcurrentExports = value.toInt();
                  });
                  this.setState(() {});
                },
              ),
              const SizedBox(height: 16),
              const Text('Output Format:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _outputFormat,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'mkv', child: Text('MKV (Matroska)')),
                  DropdownMenuItem(value: 'mp4', child: Text('MP4')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _outputFormat = value;
                    });
                    this.setState(() {});
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Verification:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SwitchListTile(
                title: const Text('Verify exports after completion'),
                subtitle: const Text('Check exported files for errors'),
                value: _enableVerification,
                onChanged: (value) {
                  setState(() {
                    _enableVerification = value;
                  });
                  this.setState(() {});
                },
              ),
              const SizedBox(height: 16),
              const Text('Compatibility:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SwitchListTile(
                title: const Text('Auto-fix container incompatibilities'),
                subtitle: const Text(
                    'Transcode incompatible audio (e.g., to AAC/Opus) and drop unsupported subtitles when needed'),
                value: _autoFixCompatibility,
                onChanged: (value) {
                  setState(() {
                    _autoFixCompatibility = value;
                  });
                  this.setState(() {});
                },
              ),
              const SizedBox(height: 16),
              const Text('Notifications:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SwitchListTile(
                title: const Text('Desktop notifications'),
                subtitle: const Text(
                    'Show Windows notifications on export completion'),
                value: _enableDesktopNotifications,
                onChanged: (value) {
                  setState(() {
                    _enableDesktopNotifications = value;
                  });
                  this.setState(() {});
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _savePreferences();
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard(FileItem item) {
    return FileCard(
      item: item,
      onChanged: () => setState(() {}),
      outputFormat: _outputFormat,
      autoFixEnabled: _autoFixCompatibility,
    );
  }

  Widget _buildAudioBatchCard() {
    return AudioBatchCard(
      files: _files,
      onChanged: () => setState(() {}),
    );
  }

  Widget _buildSubtitleBatchCard() {
    return SubtitleBatchCard(
      files: _files,
      onChanged: () => setState(() {}),
    );
  }
}

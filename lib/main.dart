import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import 'models/export_profile.dart';
import 'services/profile_service.dart';

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

/// Data model representing a media stream track.
class Track {
  final int position;
  final String language;
  final String? title;
  final String description;
  final int streamIndex;
  Track({
    required this.position,
    required this.language,
    this.title,
    required this.description,
    int? streamIndex,
  }) : streamIndex = streamIndex ?? position;
}

/// Data model representing a file with its streams and selections.
class FileItem {
  final String path;
  String name;
  String outputName;
  final List<Track> audioTracks;
  final List<Track> subtitleTracks;
  // Per-file selections used by UI
  Set<int> selectedAudio;
  // Deprecated in favor of selectedSubtitles + defaultSubtitle, but kept for compatibility if needed
  int? selectedSubtitle;
  // Multiple subtitle selections
  Set<int> selectedSubtitles;
  int? defaultAudio;
  int? defaultSubtitle;
  String exportStatus;
  double exportProgress;
  int? fileSize;
  String? duration;
  bool isExpanded;
  Process? currentProcess;

  FileItem({
    required this.path,
    String? name,
    String? outputName,
    required this.audioTracks,
    required this.subtitleTracks,
    Set<int>? selectedAudio,
    this.selectedSubtitle,
    Set<int>? selectedSubtitles,
    this.defaultAudio,
    this.defaultSubtitle,
    String? exportStatus,
    double? exportProgress,
    this.fileSize,
    this.duration,
    this.isExpanded = true,
  })  : name = name ?? File(path).uri.pathSegments.last,
        outputName = outputName ?? File(path).uri.pathSegments.last,
        selectedAudio = selectedAudio ?? <int>{},
        selectedSubtitles = selectedSubtitles ?? <int>{},
        exportStatus = exportStatus ?? '',
        exportProgress = exportProgress ?? 0.0;
}

class _MyHomePageState extends State<MyHomePage> {
  // List of file items with their track selections.
  List<FileItem> _files = [];
  String _log = '';
  bool _running = false;
  bool _batchMode = true;
  bool _dragging = false;
  bool _ffmpegAvailable = false;
  String? _lastOutputDir;
  int _maxConcurrentExports = 2;
  String _outputFormat = 'mkv';
  List<Process> _activeProcesses = [];
  List<ExportProfile> _profiles = [];
  ExportProfile? _selectedProfile;

  @override
  void initState() {
    super.initState();
    _checkFFmpeg();
    _loadPreferences();
    _loadProfiles();
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

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastOutputDir = prefs.getString('lastOutputDir');
      _maxConcurrentExports = prefs.getInt('maxConcurrentExports') ?? 2;
      _outputFormat = prefs.getString('outputFormat') ?? 'mkv';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastOutputDir != null) {
      await prefs.setString('lastOutputDir', _lastOutputDir!);
    }
    await prefs.setInt('maxConcurrentExports', _maxConcurrentExports);
    await prefs.setString('outputFormat', _outputFormat);
  }

  Future<void> _loadProfiles() async {
    final profiles = await ProfileService.loadProfiles();
    setState(() {
      _profiles = profiles;
    });
  }

  Future<void> _saveCurrentAsProfile() async {
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
                    child: Text('No profiles saved yet.\nSave your current configuration to create a profile.'),
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
                                  await ProfileService.deleteProfile(profile.id);
                                  await _loadProfiles();
                                  setDialogState(() {});
                                  setState(() {
                                    if (_selectedProfile?.id == profile.id) {
                                      _selectedProfile = null;
                                    }
                                  });
                                  _appendLog('Deleted profile: ${profile.name}');
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
    _appendLog('Export cancelled by user');
  }

  // Collect all unique audio languages across files.
  List<String> _getAllAudioLanguages() {
    final set = <String>{};
    for (final f in _files) {
      for (final t in f.audioTracks) {
        set.add(t.language);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  // Tri-state calculation for audio language selection across files.
  bool? _audioLanguageTriState(String lang) {
    int present = 0;
    int selected = 0;
    for (final f in _files) {
      final positions = f.audioTracks
          .where((t) => t.language == lang)
          .map((t) => t.position)
          .toList();
      if (positions.isEmpty) continue;
      present += positions.length;
      for (final p in positions) {
        if (f.selectedAudio.contains(p)) selected++;
      }
    }
    if (present == 0) return false;
    if (selected == 0) return false;
    if (selected == present) return true;
    return null; // indeterminate
  }

  void _toggleAudioLanguage(String lang, bool select) {
    setState(() {
      for (final f in _files) {
        for (final t in f.audioTracks.where((t) => t.language == lang)) {
          if (select) {
            f.selectedAudio.add(t.position);
          } else {
            f.selectedAudio.remove(t.position);
          }
        }
      }
    });
  }

  // Subtitle batch helpers: work by description (not language)
  List<String> _getAllSubtitleDescriptions() {
    final set = <String>{};
    for (final f in _files) {
      for (final t in f.subtitleTracks) {
        set.add(t.description);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  bool? _subtitleDescriptionTriState(String desc) {
    int present = 0;
    int selected = 0;
    for (final f in _files) {
      final positions = f.subtitleTracks
          .where((t) => t.description == desc)
          .map((t) => t.position)
          .toList();
      if (positions.isEmpty) continue;
      present += positions.length;
      for (final p in positions) {
        if (f.selectedSubtitles.contains(p)) selected++;
      }
    }
    if (present == 0) return false;
    if (selected == 0) return false;
    if (selected == present) return true;
    return null;
  }

  void _toggleSubtitleDescription(String desc, bool select) {
    setState(() {
      for (final f in _files) {
        for (final t in f.subtitleTracks.where((t) => t.description == desc)) {
          if (select) {
            f.selectedSubtitles.add(t.position);
            f.defaultSubtitle ??= t.position;
          } else {
            f.selectedSubtitles.remove(t.position);
            if (f.defaultSubtitle == t.position) {
              f.defaultSubtitle = f.selectedSubtitles.isNotEmpty
                  ? f.selectedSubtitles.first
                  : null;
            }
          }
        }
      }
    });
  }

  bool _isSubtitleDescriptionDefault(String desc) {
    for (final f in _files) {
      if (f.defaultSubtitle == null) return false;
      final def = f.defaultSubtitle!;
      final matching = f.subtitleTracks
          .where((t) => t.description == desc)
          .map((t) => t.position)
          .toSet();
      if (matching.isEmpty) continue;
      if (!matching.contains(def)) return false;
    }
    return true;
  }

  void _toggleSubtitleDescriptionDefault(String desc, bool value) {
    setState(() {
      for (final f in _files) {
        final positions = f.subtitleTracks
            .where((t) => t.description == desc)
            .map((t) => t.position)
            .toList();
        if (positions.isEmpty) continue;
        final firstMatch = positions.first;
        if (value) {
          f.selectedSubtitles.add(firstMatch);
          f.defaultSubtitle = firstMatch;
        } else {
          if (f.defaultSubtitle != null &&
              positions.contains(f.defaultSubtitle)) {
            f.defaultSubtitle = null;
          }
        }
      }
    });
  }

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
        setState(() {
          _files.add(item);
        });
        _appendLog('Added: ${item.name}');
      } catch (e) {
        _appendLog('ERROR: Failed to probe $filePath: $e');
      }
    }
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
    // Get file size and duration
    final file = File(path);
    final fileSize = await file.length();

    // Get duration
    String? duration;
    try {
      final durationResult = await Process.run(
        'ffprobe',
        [
          '-v',
          'error',
          '-show_entries',
          'format=duration',
          '-of',
          'default=noprint_wrappers=1:nokey=1',
          path,
        ],
      );
      final durationStr = durationResult.stdout.toString().trim();
      if (durationStr.isNotEmpty) {
        final seconds = double.tryParse(durationStr);
        if (seconds != null) {
          final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
          final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
          final secs = (seconds % 60).toInt().toString().padLeft(2, '0');
          duration = '$hours:$minutes:$secs';
        }
      }
    } catch (e) {
      // Duration probe failed, continue without it
    }

    // Probe audio tracks.
    final audioResult = await Process.run(
      'ffprobe',
      [
        '-v',
        'error',
        '-select_streams',
        'a',
        '-show_entries',
        'stream=index:stream_tags=language,title',
        '-of',
        'csv=p=0:s=|',
        path,
      ],
    );
    final audioLines = audioResult.stdout.toString().split('\n');
    final audioTracks = <Track>[];
    int audioPos = 0;
    for (final line in audioLines) {
      if (line.trim().isEmpty) continue;
      final parts = line.split('|');
      final language =
          parts.length > 1 && parts[1].isNotEmpty ? parts[1] : 'und';
      final title = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;
      final description =
          title != null ? '$language ($title)' : 'Audio $language';
      audioTracks.add(Track(
        position: audioPos,
        language: language,
        title: title,
        description: description,
      ));
      audioPos++;
    }
    // Probe subtitle tracks.
    final subResult = await Process.run(
      'ffprobe',
      [
        '-v',
        'error',
        '-select_streams',
        's',
        '-show_entries',
        'stream=index:stream_tags=language,title',
        '-of',
        'csv=p=0:s=|',
        path,
      ],
    );
    final subLines = subResult.stdout.toString().split('\n');
    final subtitleTracks = <Track>[];
    int subPos = 0;
    for (final line in subLines) {
      if (line.trim().isEmpty) continue;
      final parts = line.split('|');
      final language =
          parts.length > 1 && parts[1].isNotEmpty ? parts[1] : 'und';
      final title = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;
      final desc = title != null ? '$language ($title)' : 'Subtitle $language';
      subtitleTracks.add(Track(
        position: subPos,
        language: language,
        title: title,
        description: desc,
      ));
      subPos++;
    }
    // Initialize selections: select all audio tracks and first subtitle by default
    Set<int> initialSelectedAudio = <int>{};
    int? defaultAudio;
    for (int i = 0; i < audioTracks.length; i++) {
      initialSelectedAudio.add(i);
    }
    if (audioTracks.isNotEmpty) {
      defaultAudio = 0;
    }

    Set<int> initialSelectedSubtitles = <int>{};
    int? defaultSubtitle;
    if (subtitleTracks.isNotEmpty) {
      initialSelectedSubtitles.add(0);
      defaultSubtitle = 0;
    }

    return FileItem(
      path: path,
      audioTracks: audioTracks,
      subtitleTracks: subtitleTracks,
      selectedAudio: initialSelectedAudio,
      defaultAudio: defaultAudio,
      selectedSubtitles: initialSelectedSubtitles,
      defaultSubtitle: defaultSubtitle,
      fileSize: fileSize,
      duration: duration,
    );
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
            child: const Text('Start Export'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Ask user for output directory.
    final outDirPath = _lastOutputDir != null
        ? _lastOutputDir
        : await FilePicker.platform.getDirectoryPath();

    if (outDirPath == null) {
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

    // Process files in parallel batches
    for (var i = 0; i < _files.length; i += _maxConcurrentExports) {
      final batch = _files.skip(i).take(_maxConcurrentExports).toList();
      await Future.wait(batch.map((file) => _exportFile(file, outDir)));
    }

    setState(() {
      _running = false;
    });

    final successCount =
        _files.where((f) => f.exportStatus == 'completed').length;
    _appendLog(
        'Export finished: $successCount/${_files.length} files successful');

    // Show notification
    if (successCount == _files.length) {
      _showNotification(
          'Export Complete', 'All $successCount files exported successfully');
    } else {
      _showNotification(
          'Export Finished', '$successCount/${_files.length} files exported');
    }
  }

  String _generateExportSummary() {
    final buffer = StringBuffer();
    buffer.writeln('Files to export: ${_files.length}');
    buffer.writeln('Output format: $_outputFormat');
    buffer.writeln('');

    int totalAudioRemoved = 0;
    int totalSubtitlesKept = 0;

    for (final file in _files) {
      final audioRemoved = file.audioTracks.length - file.selectedAudio.length;
      totalAudioRemoved += audioRemoved;
      totalSubtitlesKept += file.selectedSubtitles.length;
    }

    buffer.writeln('Total audio tracks to remove: $totalAudioRemoved');
    buffer.writeln('Total subtitle tracks to keep: $totalSubtitlesKept');
    buffer.writeln('');
    buffer.writeln('Files:');

    for (final file in _files) {
      buffer.writeln('• ${file.name}');
      buffer.writeln(
          '  Audio: ${file.selectedAudio.length}/${file.audioTracks.length}');
      buffer.writeln(
          '  Subtitles: ${file.selectedSubtitles.length}/${file.subtitleTracks.length}');
    }

    return buffer.toString();
  }

  Future<void> _exportFile(FileItem item, Directory outDir) async {
    setState(() {
      item.exportStatus = 'processing';
      item.exportProgress = 0.0;
    });

    _appendLog('Processing: ${item.name}');

    final extension = _outputFormat;
    final outputFileName =
        path.basenameWithoutExtension(item.outputName) + '.$extension';
    final outPath = path.join(outDir.path, outputFileName);

    final args = <String>[
      '-i', item.path,
      '-map', '0',
      '-y', // Overwrite output files
    ];

    // Remove unselected audio streams.
    for (final track in item.audioTracks) {
      if (!item.selectedAudio.contains(track.position)) {
        args.addAll(['-map', '-0:a:${track.position}']);
      }
    }

    // Handle subtitles: if at least one subtitle stream exists.
    if (item.subtitleTracks.isNotEmpty) {
      args.addAll(['-map', '-0:s']);
      final selectedSubs = item.selectedSubtitles.toList()..sort();
      for (final pos in selectedSubs) {
        args.addAll(['-map', '0:s:$pos']);
      }
      if (selectedSubs.isNotEmpty) {
        for (var i = 0; i < selectedSubs.length; i++) {
          final pos = selectedSubs[i];
          if (item.defaultSubtitle != null && pos == item.defaultSubtitle) {
            args.addAll(['-disposition:s:$i', 'default']);
          } else {
            args.addAll(['-disposition:s:$i', '0']);
          }
        }
      }
    }

    args.addAll([
      '-map_chapters',
      '0',
      '-map_metadata',
      '0',
      '-c',
      'copy',
      '-progress',
      'pipe:1',
      outPath,
    ]);

    try {
      final process = await Process.start('ffmpeg', args);
      item.currentProcess = process;
      _activeProcesses.add(process);

      // Parse progress
      process.stdout.transform(utf8.decoder).listen((data) {
        // FFmpeg outputs progress in format: out_time_ms=123456
        final match = RegExp(r'out_time_ms=(\d+)').firstMatch(data);
        if (match != null && item.duration != null) {
          final outTimeMs = int.parse(match.group(1)!);
          final durationParts = item.duration!.split(':');
          final totalSeconds = int.parse(durationParts[0]) * 3600 +
              int.parse(durationParts[1]) * 60 +
              int.parse(durationParts[2]);
          final progress = (outTimeMs / 1000000) / totalSeconds;
          setState(() {
            item.exportProgress = progress.clamp(0.0, 1.0);
          });
        }
      });

      final exitCode = await process.exitCode;
      _activeProcesses.remove(process);
      item.currentProcess = null;

      if (exitCode == 0) {
        setState(() {
          item.exportStatus = 'completed';
          item.exportProgress = 1.0;
        });
        _appendLog('✓ Completed: ${item.name}');
      } else {
        setState(() {
          item.exportStatus = 'failed';
        });
        _appendLog('✗ Failed: ${item.name} (exit code: $exitCode)');
      }
    } catch (e) {
      setState(() {
        item.exportStatus = 'failed';
      });
      _appendLog('✗ Error processing ${item.name}: $e');
    }
  }

  void _showNotification(String title, String message) {
    // Simple in-app notification using SnackBar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title: $message'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (details) => setState(() => _dragging = true),
      onDragExited: (details) => setState(() => _dragging = false),
      onDragDone: (details) {
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
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () => _showSettingsDialog(),
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
                        OutlinedButton.icon(
                          onPressed: _running ? null : _showProfileManagementDialog,
                          icon: const Icon(Icons.library_books),
                          label: Text(_selectedProfile != null 
                              ? 'Profiles (${_selectedProfile!.name})'
                              : 'Profiles (${_profiles.length})'),
                        ),
                      ],
                      if (_files.isNotEmpty)
                        Text(
                            '${_files.length} file(s) | ${_formatBytes(_files.fold<int>(0, (sum, f) => sum + (f.fileSize ?? 0)))}'),
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
                                        onChanged: (v) => setState(
                                            () => _batchMode = v ?? false),
                                      ),
                                      if (_batchMode) ...[
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
                                        onPressed: () =>
                                            setState(() => _log = ''),
                                        icon: const Icon(Icons.clear, size: 16),
                                        label: const Text('Clear'),
                                      ),
                                      TextButton.icon(
                                        onPressed: _saveLogToFile,
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
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.file_download,
                              size: 64, color: Theme.of(context).primaryColor),
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

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
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
    final statusIcon = item.exportStatus == 'completed'
        ? const Icon(Icons.check_circle, color: Colors.green)
        : item.exportStatus == 'failed'
            ? const Icon(Icons.error, color: Colors.red)
            : item.exportStatus == 'processing'
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : item.exportStatus == 'cancelled'
                    ? const Icon(Icons.cancel, color: Colors.orange)
                    : const Icon(Icons.pending, color: Colors.grey);

    return Card(
      child: ExpansionTile(
        initiallyExpanded: item.isExpanded,
        onExpansionChanged: (expanded) =>
            setState(() => item.isExpanded = expanded),
        leading: statusIcon,
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(text: item.outputName),
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  labelText: 'Output filename',
                ),
                onChanged: (value) => item.outputName = value,
              ),
            ),
            if (item.exportProgress > 0 && item.exportProgress < 1) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: LinearProgressIndicator(value: item.exportProgress),
              ),
              const SizedBox(width: 8),
              Text('${(item.exportProgress * 100).toInt()}%'),
            ],
          ],
        ),
        subtitle: Text(
            '${item.name} ${item.fileSize != null ? "• ${_formatBytes(item.fileSize!)}" : ""} ${item.duration != null ? "• ${item.duration}" : ""}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Audio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Audio',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      if (item.audioTracks.isEmpty) const Text('No audio'),
                      for (final track in item.audioTracks)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(track.description,
                              style: const TextStyle(fontSize: 12)),
                          value: item.selectedAudio.contains(track.position),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                item.selectedAudio.add(track.position);
                              } else {
                                item.selectedAudio.remove(track.position);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Subtitles
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Subtitles',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      if (item.subtitleTracks.isEmpty)
                        const Text('No subtitles'),
                      for (final track in item.subtitleTracks)
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(track.description,
                                    style: const TextStyle(fontSize: 12)),
                                value: item.selectedSubtitles
                                    .contains(track.position),
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      item.selectedSubtitles
                                          .add(track.position);
                                      item.defaultSubtitle ??= track.position;
                                    } else {
                                      item.selectedSubtitles
                                          .remove(track.position);
                                      if (item.defaultSubtitle ==
                                          track.position) {
                                        item.defaultSubtitle =
                                            item.selectedSubtitles.isNotEmpty
                                                ? item.selectedSubtitles.first
                                                : null;
                                      }
                                    }
                                  });
                                },
                              ),
                            ),
                            Checkbox(
                              value: item.defaultSubtitle == track.position,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    item.selectedSubtitles.add(track.position);
                                    item.defaultSubtitle = track.position;
                                  } else {
                                    if (item.defaultSubtitle ==
                                        track.position) {
                                      item.defaultSubtitle = null;
                                    }
                                  }
                                });
                              },
                            ),
                            const Text('Default',
                                style: TextStyle(fontSize: 10)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioBatchCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Audio Batch', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_getAllAudioLanguages().isEmpty)
                      const Text('No audio languages found'),
                    for (final lang in _getAllAudioLanguages())
                      CheckboxListTile(
                        tristate: true,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(lang),
                        value: _audioLanguageTriState(lang),
                        onChanged: (val) {
                          setState(() {
                            final currentState = _audioLanguageTriState(lang);
                            final select = currentState != true;
                            _toggleAudioLanguage(lang, select);
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitleBatchCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Subtitle Batch',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_getAllSubtitleDescriptions().isEmpty)
                      const Text('No subtitles found'),
                    for (final desc in _getAllSubtitleDescriptions())
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              tristate: true,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(desc,
                                  style: const TextStyle(fontSize: 12)),
                              value: _subtitleDescriptionTriState(desc),
                              onChanged: (val) {
                                setState(() {
                                  final currentState =
                                      _subtitleDescriptionTriState(desc);
                                  final select = currentState != true;
                                  _toggleSubtitleDescription(desc, select);
                                });
                              },
                            ),
                          ),
                          Checkbox(
                            value: _isSubtitleDescriptionDefault(desc),
                            onChanged: (v) {
                              _toggleSubtitleDescriptionDefault(
                                  desc, v ?? false);
                            },
                          ),
                          const Text('Def', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

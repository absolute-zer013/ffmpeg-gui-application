import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import '../lib/services/ffprobe_service.dart';
import '../lib/services/ffmpeg_export_service.dart';
import '../lib/models/file_item.dart';
import '../lib/models/codec_options.dart';

/// Command-line interface for FFmpeg Filter App.
/// Allows automation and scripting without the GUI.
void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help message')
    ..addFlag('version', abbr: 'v', negatable: false, help: 'Show version information')
    ..addOption('input', abbr: 'i', help: 'Input file path (required)', mandatory: false)
    ..addMultiOption('audio', abbr: 'a', help: 'Audio track indices to keep (comma-separated)')
    ..addMultiOption('subtitle', abbr: 's', help: 'Subtitle track indices to keep (comma-separated)')
    ..addOption('output', abbr: 'o', help: 'Output file path (default: same directory with _filtered suffix)')
    ..addOption('format', abbr: 'f', help: 'Output format (mkv, mp4, avi)', defaultsTo: 'mkv')
    ..addFlag('json', negatable: false, help: 'Output results in JSON format')
    ..addFlag('info', negatable: false, help: 'Show file information only (no processing)')
    ..addFlag('dry-run', negatable: false, help: 'Show what would be done without executing')
    ..addOption('video-codec', help: 'Video codec (copy, h264, hevc, vp9, av1)')
    ..addOption('audio-codec', help: 'Audio codec (copy, aac, mp3, opus, ac3, flac)')
    ..addOption('audio-bitrate', help: 'Audio bitrate (e.g., 192k)')
    ..addFlag('verify', negatable: true, defaultsTo: false, help: 'Verify output file after export');

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      _printHelp(parser);
      exit(0);
    }

    if (results['version'] as bool) {
      _printVersion();
      exit(0);
    }

    final inputFile = results['input'] as String?;
    if (inputFile == null) {
      _printError('Input file is required. Use --input or -i to specify.');
      _printHelp(parser);
      exit(1);
    }

    if (!File(inputFile).existsSync()) {
      _printError('Input file does not exist: $inputFile');
      exit(1);
    }

    final jsonOutput = results['json'] as bool;
    final infoOnly = results['info'] as bool;
    final dryRun = results['dry-run'] as bool;

    // Get file information
    final ffprobeService = FFprobeService();
    final fileInfo = await ffprobeService.analyzeFile(inputFile);

    if (fileInfo == null) {
      _printError('Failed to analyze input file. Make sure ffprobe is installed.');
      exit(1);
    }

    if (infoOnly) {
      if (jsonOutput) {
        _printJson(_fileItemToJson(fileInfo));
      } else {
        _printFileInfo(fileInfo);
      }
      exit(0);
    }

    // Parse track selections
    final audioTracks = _parseTrackIndices(results['audio'] as List<String>);
    final subtitleTracks = _parseTrackIndices(results['subtitle'] as List<String>);

    // Set track selections
    for (var i = 0; i < fileInfo.audioTracks.length; i++) {
      fileInfo.audioTracks[i].selected = audioTracks.isEmpty || audioTracks.contains(i);
    }
    for (var i = 0; i < fileInfo.subtitleTracks.length; i++) {
      fileInfo.subtitleTracks[i].selected = subtitleTracks.isEmpty || subtitleTracks.contains(i);
    }

    // Set codec options if specified
    if (results.wasParsed('video-codec') || results.wasParsed('audio-codec')) {
      fileInfo.codecOptions = CodecOptions(
        videoCodec: _parseVideoCodec(results['video-codec'] as String?),
        audioCodec: _parseAudioCodec(results['audio-codec'] as String?),
        audioBitrate: results['audio-bitrate'] as String?,
      );
    }

    // Determine output path
    final outputFormat = results['format'] as String;
    final outputPath = results['output'] as String? ?? 
        _generateOutputPath(inputFile, outputFormat);

    if (dryRun) {
      if (jsonOutput) {
        _printJson({
          'dryRun': true,
          'input': inputFile,
          'output': outputPath,
          'format': outputFormat,
          'selectedAudioTracks': audioTracks,
          'selectedSubtitleTracks': subtitleTracks,
          'videoCodec': fileInfo.codecOptions?.videoCodec ?? 'copy',
          'audioCodec': fileInfo.codecOptions?.audioCodec ?? 'copy',
        });
      } else {
        print('Dry run - would execute:');
        print('  Input: $inputFile');
        print('  Output: $outputPath');
        print('  Format: $outputFormat');
        print('  Audio tracks: ${audioTracks.isEmpty ? "all" : audioTracks.join(", ")}');
        print('  Subtitle tracks: ${subtitleTracks.isEmpty ? "all" : subtitleTracks.join(", ")}');
      }
      exit(0);
    }

    // Execute export
    final exportService = FFmpegExportService();
    
    if (!jsonOutput) {
      print('Processing file: $inputFile');
      print('Output: $outputPath');
    }

    final success = await exportService.exportFile(
      fileInfo,
      outputPath,
      outputFormat: outputFormat,
    );

    if (success) {
      final outputFile = File(outputPath);
      final outputSize = outputFile.existsSync() ? outputFile.lengthSync() : 0;
      
      if (jsonOutput) {
        _printJson({
          'success': true,
          'input': inputFile,
          'output': outputPath,
          'outputSize': outputSize,
        });
      } else {
        print('Export completed successfully!');
        print('Output file: $outputPath');
        print('Output size: ${_formatFileSize(outputSize)}');
      }
      exit(0);
    } else {
      if (jsonOutput) {
        _printJson({
          'success': false,
          'error': 'Export failed',
        });
      } else {
        _printError('Export failed. Check ffmpeg output for details.');
      }
      exit(1);
    }
  } catch (e) {
    _printError('Error: $e');
    exit(1);
  }
}

void _printHelp(ArgParser parser) {
  print('FFmpeg Filter App - Command Line Interface');
  print('');
  print('Usage: ffmpeg_cli [options]');
  print('');
  print('Options:');
  print(parser.usage);
  print('');
  print('Examples:');
  print('  # Show file information');
  print('  ffmpeg_cli -i input.mkv --info');
  print('');
  print('  # Export with specific tracks');
  print('  ffmpeg_cli -i input.mkv -a 0,1 -s 0');
  print('');
  print('  # Export with codec conversion');
  print('  ffmpeg_cli -i input.mkv --video-codec h264 --audio-codec aac');
  print('');
  print('  # JSON output for scripting');
  print('  ffmpeg_cli -i input.mkv --info --json');
}

void _printVersion() {
  print('FFmpeg Filter App CLI v1.0.0');
}

void _printError(String message) {
  stderr.writeln('ERROR: $message');
}

void _printJson(Map<String, dynamic> data) {
  print(JsonEncoder.withIndent('  ').convert(data));
}

void _printFileInfo(FileItem file) {
  print('File: ${file.fileName}');
  print('Path: ${file.filePath}');
  print('Size: ${_formatFileSize(file.fileSize)}');
  print('Duration: ${file.duration ?? "Unknown"}');
  print('Format: ${file.format ?? "Unknown"}');
  print('');
  print('Video Tracks: ${file.videoTracks.length}');
  for (var track in file.videoTracks) {
    print('  [${track.index}] ${track.codec} - ${track.language ?? "Unknown"}');
  }
  print('');
  print('Audio Tracks: ${file.audioTracks.length}');
  for (var track in file.audioTracks) {
    print('  [${track.index}] ${track.codec} - ${track.title ?? track.language ?? "Unknown"}');
  }
  print('');
  print('Subtitle Tracks: ${file.subtitleTracks.length}');
  for (var track in file.subtitleTracks) {
    print('  [${track.index}] ${track.codec} - ${track.title ?? track.language ?? "Unknown"}');
  }
}

Map<String, dynamic> _fileItemToJson(FileItem file) {
  return {
    'fileName': file.fileName,
    'filePath': file.filePath,
    'fileSize': file.fileSize,
    'duration': file.duration,
    'format': file.format,
    'videoTracks': file.videoTracks.map((t) => {
      'index': t.index,
      'codec': t.codec,
      'language': t.language,
    }).toList(),
    'audioTracks': file.audioTracks.map((t) => {
      'index': t.index,
      'codec': t.codec,
      'title': t.title,
      'language': t.language,
      'channels': t.channels,
    }).toList(),
    'subtitleTracks': file.subtitleTracks.map((t) => {
      'index': t.index,
      'codec': t.codec,
      'title': t.title,
      'language': t.language,
    }).toList(),
  };
}

List<int> _parseTrackIndices(List<String> values) {
  final indices = <int>[];
  for (var value in values) {
    for (var part in value.split(',')) {
      final index = int.tryParse(part.trim());
      if (index != null) {
        indices.add(index);
      }
    }
  }
  return indices;
}

String _generateOutputPath(String inputPath, String format) {
  final dir = path.dirname(inputPath);
  final basename = path.basenameWithoutExtension(inputPath);
  return path.join(dir, '${basename}_filtered.$format');
}

String _parseVideoCodec(String? codec) {
  if (codec == null) return 'copy';
  switch (codec.toLowerCase()) {
    case 'h264':
    case 'x264':
      return 'h264';
    case 'h265':
    case 'hevc':
    case 'x265':
      return 'hevc';
    case 'vp9':
      return 'vp9';
    case 'av1':
      return 'av1';
    default:
      return 'copy';
  }
}

String _parseAudioCodec(String? codec) {
  if (codec == null) return 'copy';
  switch (codec.toLowerCase()) {
    case 'aac':
      return 'aac';
    case 'mp3':
      return 'mp3';
    case 'opus':
      return 'opus';
    case 'ac3':
      return 'ac3';
    case 'flac':
      return 'flac';
    default:
      return 'copy';
  }
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

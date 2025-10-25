import 'dart:io';
import '../models/optimization_settings.dart';

/// Service for optimizing MKV files using mkvpropedit
class MkvOptimizationService {
  /// Checks if mkvpropedit is available in the system
  static Future<bool> isMkvpropeditAvailable() async {
    try {
      final result = await Process.run('mkvpropedit', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Optimizes an MKV file according to the provided settings
  static Future<OptimizationResult> optimizeFile(
    String filePath,
    OptimizationSettings settings,
  ) async {
    final startTime = DateTime.now();

    try {
      // Get original file size
      final file = File(filePath);
      final originalSize = await file.length();

      // Build mkvpropedit command arguments
      final args = <String>[filePath];

      // Add optimization flags based on settings
      if (settings.optimizeHeader) {
        // mkvpropedit doesn't have a direct header optimization flag
        // but editing any property triggers a rewrite which can optimize
      }

      if (settings.removeMetadata) {
        // Remove common metadata tags
        args.addAll([
          '--delete',
          'title',
          '--delete',
          'date',
        ]);
      }

      // Run mkvpropedit if there are changes to make
      if (args.length > 1) {
        final result = await Process.run('mkvpropedit', args);

        if (result.exitCode != 0) {
          return OptimizationResult(
            originalSize: originalSize,
            optimizedSize: originalSize,
            error: 'mkvpropedit failed: ${result.stderr}',
            durationMs: DateTime.now().difference(startTime).inMilliseconds,
          );
        }
      }

      // For stream reordering, we need to use FFmpeg as mkvpropedit
      // doesn't support stream reordering
      if (settings.reorderStreams &&
          settings.reorderPolicy != StreamReorderPolicy.keepOriginal) {
        await _reorderStreams(filePath, settings.reorderPolicy);
      }

      // Get optimized file size
      final optimizedSize = await file.length();

      return OptimizationResult(
        originalSize: originalSize,
        optimizedSize: optimizedSize,
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
      );
    } catch (e) {
      final file = File(filePath);
      final size = await file.length();

      return OptimizationResult(
        originalSize: size,
        optimizedSize: size,
        error: 'Optimization failed: $e',
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
      );
    }
  }

  /// Reorders streams in an MKV file using FFmpeg
  static Future<void> _reorderStreams(
    String filePath,
    StreamReorderPolicy policy,
  ) async {
    if (policy == StreamReorderPolicy.keepOriginal) {
      return;
    }

    // Create temporary output file
    final tempFile = '$filePath.temp.mkv';

    try {
      // Get stream information
      final probeResult = await Process.run(
        'ffprobe',
        [
          '-v',
          'error',
          '-show_entries',
          'stream=index,codec_type',
          '-of',
          'csv=p=0',
          filePath,
        ],
      );

      final streams = <String, List<int>>{
        'video': [],
        'audio': [],
        'subtitle': [],
      };

      // Parse stream indices by type
      final lines = probeResult.stdout.toString().split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(',');
        if (parts.length < 2) continue;

        final index = int.tryParse(parts[0]);
        final type = parts[1].trim();

        if (index != null && streams.containsKey(type)) {
          streams[type]!.add(index);
        }
      }

      // Build FFmpeg map arguments based on policy
      final mapArgs = <String>[];

      // Add video streams
      for (final index in streams['video']!) {
        mapArgs.addAll(['-map', '0:$index']);
      }

      // Add audio streams
      for (final index in streams['audio']!) {
        mapArgs.addAll(['-map', '0:$index']);
      }

      // Add subtitle streams
      for (final index in streams['subtitle']!) {
        mapArgs.addAll(['-map', '0:$index']);
      }

      // Run FFmpeg to reorder streams
      final ffmpegArgs = [
        '-i',
        filePath,
        ...mapArgs,
        '-codec',
        'copy',
        tempFile,
      ];

      final result = await Process.run('ffmpeg', ffmpegArgs);

      if (result.exitCode != 0) {
        throw Exception('FFmpeg reorder failed: ${result.stderr}');
      }

      // Replace original file with reordered version
      final originalFile = File(filePath);
      final tempFileObj = File(tempFile);

      await originalFile.delete();
      await tempFileObj.rename(filePath);
    } catch (e) {
      // Clean up temp file if it exists
      final tempFileObj = File(tempFile);
      if (await tempFileObj.exists()) {
        await tempFileObj.delete();
      }
      rethrow;
    }
  }

  /// Validates that a file is an MKV file
  static bool isMkvFile(String filePath) {
    return filePath.toLowerCase().endsWith('.mkv');
  }

  /// Gets file size in bytes
  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    return await file.length();
  }
}

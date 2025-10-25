import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/file_item.dart';
import '../models/codec_options.dart';

/// Result of a disk space preflight check
class DiskSpaceCheckResult {
  final bool hasSufficientSpace;
  final int requiredBytes;
  final int availableBytes;
  final String targetPath;
  final String? tempPath;
  final int? tempAvailableBytes;
  final String message;

  DiskSpaceCheckResult({
    required this.hasSufficientSpace,
    required this.requiredBytes,
    required this.availableBytes,
    required this.targetPath,
    this.tempPath,
    this.tempAvailableBytes,
    required this.message,
  });

  String get formattedRequired => _formatBytes(requiredBytes);
  String get formattedAvailable => _formatBytes(availableBytes);
  String get formattedTempAvailable =>
      tempAvailableBytes != null ? _formatBytes(tempAvailableBytes!) : 'N/A';

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Service for checking disk space before exports
class DiskSpaceService {
  /// Estimate required disk space for an export job
  /// Returns estimated bytes needed
  static int estimateRequiredSpace(List<FileItem> files) {
    int totalEstimate = 0;

    for (final file in files) {
      // Base estimate on file size (bytes). If unknown, assume 0.
      final int fileSize = file.fileSize ?? 0;

      // Default estimate: assume output size similar to input (copy/remux)
      double multiplier = 1.1; // 10% buffer for remuxing overhead

      // Check if re-encoding is happening
      final hasVideoReencoding = file.codecSettings.values
          .any((s) => s.videoCodec != null && s.videoCodec != VideoCodec.copy);
      final hasAudioReencoding = file.codecSettings.values
          .any((s) => s.audioCodec != null && s.audioCodec != AudioCodec.copy);

      if (hasVideoReencoding) {
        // Video re-encoding can vary widely
        // Estimate based on quality preset or codec
        final hasQualityPreset = file.qualityPreset != null;

        if (hasQualityPreset) {
          final crf = file.qualityPreset!.crf;
          if (crf != null) {
            // Higher CRF = more compression = smaller file
            // CRF 18 (high quality) ~ 1.2x, CRF 23 (balanced) ~ 0.8x, CRF 28 (fast) ~ 0.5x
            if (crf <= 20) {
              multiplier = 1.2;
            } else if (crf <= 25) {
              multiplier = 0.8;
            } else {
              multiplier = 0.5;
            }
          }
        } else {
          // Conservative estimate for re-encoding without preset
          multiplier = 1.0;
        }
      } else if (hasAudioReencoding) {
        // Audio-only re-encoding has minimal impact on size
        multiplier = 1.05;
      }

      // Add temporary file space if re-encoding (two-stage pipeline)
      if (hasVideoReencoding || hasAudioReencoding) {
        // Need space for both temp and final file during export
        totalEstimate += (fileSize * multiplier * 2).toInt();
      } else {
        // Just need space for final file
        totalEstimate += (fileSize * multiplier).toInt();
      }
    }

    // Add 500MB safety margin
    totalEstimate += 500 * 1024 * 1024;

    return totalEstimate;
  }

  /// Check available disk space on a given path
  /// Returns available bytes, or null if cannot determine
  static Future<int?> getAvailableDiskSpace(String targetPath) async {
    try {
      // Use df command on Unix-like systems or fsutil on Windows
      if (Platform.isWindows) {
        return await _getAvailableSpaceWindows(targetPath);
      } else {
        return await _getAvailableSpaceUnix(targetPath);
      }
    } catch (e) {
      // Cannot determine disk space
      return null;
    }
  }

  static Future<int?> _getAvailableSpaceWindows(String targetPath) async {
    try {
      // Get drive letter from path
      final drive = path.split(targetPath).first;
      if (drive.isEmpty) return null;

      // Use PowerShell to get free space
      final result = await Process.run(
        'powershell',
        [
          '-Command',
          '(Get-PSDrive ${drive.replaceAll(':', '')} -ErrorAction SilentlyContinue).Free'
        ],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        final bytes = int.tryParse(output);
        return bytes;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<int?> _getAvailableSpaceUnix(String targetPath) async {
    try {
      // Use df command
      final result = await Process.run(
        'df',
        ['-k', targetPath],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        if (lines.length >= 2) {
          // Parse second line (data line)
          final parts = lines[1].split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            // Available is typically the 4th column (0-indexed: 3)
            final availableKB = int.tryParse(parts[3]);
            if (availableKB != null) {
              return availableKB * 1024; // Convert KB to bytes
            }
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Perform preflight disk space check
  static Future<DiskSpaceCheckResult> checkDiskSpace({
    required List<FileItem> files,
    required String outputDirectory,
    String? tempDirectory,
  }) async {
    final requiredBytes = estimateRequiredSpace(files);
    final availableBytes = await getAvailableDiskSpace(outputDirectory);

    // Check temp directory if specified
    int? tempAvailableBytes;
    if (tempDirectory != null && tempDirectory.isNotEmpty) {
      tempAvailableBytes = await getAvailableDiskSpace(tempDirectory);
    }

    // Determine if we have sufficient space
    bool hasSufficientSpace = true;
    String message = 'Sufficient disk space available';

    if (availableBytes == null) {
      // Cannot determine space - allow with warning
      message =
          'Cannot determine available disk space. Export may fail if insufficient space.';
    } else if (availableBytes < requiredBytes) {
      hasSufficientSpace = false;
      message =
          'Insufficient disk space in output directory. Required: ${DiskSpaceCheckResult._formatBytes(requiredBytes)}, Available: ${DiskSpaceCheckResult._formatBytes(availableBytes)}';
    } else if (tempAvailableBytes != null &&
        tempAvailableBytes < requiredBytes) {
      hasSufficientSpace = false;
      message =
          'Insufficient disk space in temporary directory. Required: ${DiskSpaceCheckResult._formatBytes(requiredBytes)}, Available: ${DiskSpaceCheckResult._formatBytes(tempAvailableBytes)}';
    } else {
      // All good
      message =
          'Sufficient space. Required: ${DiskSpaceCheckResult._formatBytes(requiredBytes)}, Available: ${DiskSpaceCheckResult._formatBytes(availableBytes)}';
    }

    return DiskSpaceCheckResult(
      hasSufficientSpace: hasSufficientSpace,
      requiredBytes: requiredBytes,
      availableBytes: availableBytes ?? 0,
      targetPath: outputDirectory,
      tempPath: tempDirectory,
      tempAvailableBytes: tempAvailableBytes,
      message: message,
    );
  }
}

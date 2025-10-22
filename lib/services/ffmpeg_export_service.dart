import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../models/file_item.dart';
import '../models/codec_options.dart';
import '../utils/rename_utils.dart';

/// Service for exporting files using FFmpeg
class FFmpegExportService {
  /// Export a single file with the user's track selections
  static Future<ExportResult> exportFile({
    required FileItem item,
    required Directory outputDir,
    required String outputFormat,
    required Function(double progress) onProgress,
  }) async {
    final extension = outputFormat;

    // Apply rename pattern if present
    String outputFileName;
    if (item.renamePattern != null) {
      outputFileName = RenameUtils.applyPattern(
        item.renamePattern!.pattern,
        item.path,
        index: item.renameIndex,
        episode: item.renameEpisode,
        season: item.renameSeason,
        year: item.renameYear,
      );
      // Ensure correct extension
      outputFileName =
          '${path.basenameWithoutExtension(outputFileName)}.$extension';
    } else {
      outputFileName =
          '${path.basenameWithoutExtension(item.outputName)}.$extension';
    }

    final outPath = path.join(outputDir.path, outputFileName);

    final args = <String>[
      '-i', item.path,
      '-map', '0',
      '-y', // Overwrite output files
    ];

    // Remove unselected video streams.
    for (final track in item.videoTracks) {
      if (!item.selectedVideo.contains(track.position)) {
        args.addAll(['-map', '-0:v:${track.position}']);
      }
    }

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

    // Add file-level metadata if present
    if (item.fileMetadata != null) {
      final metadataMap = item.fileMetadata!.toMap();
      for (final entry in metadataMap.entries) {
        args.addAll(['-metadata', '${entry.key}=${entry.value}']);
      }
    }

    // Add track-level metadata if present
    for (final entry in item.trackMetadata.entries) {
      final streamIndex = entry.key;
      final metadata = entry.value;
      final metadataMap = metadata.toMap();
      for (final metaEntry in metadataMap.entries) {
        args.addAll([
          '-metadata:s:$streamIndex',
          '${metaEntry.key}=${metaEntry.value}'
        ]);
      }
    }

    // Handle codec conversion settings
    bool needsEncoding = false;

    // Apply quality preset if present
    if (item.qualityPreset != null) {
      final preset = item.qualityPreset!;

      // Add video encoding parameters
      if (preset.crf != null) {
        args.addAll(['-crf', preset.crf.toString()]);
        needsEncoding = true;
      }
      if (preset.preset != null) {
        args.addAll(['-preset', preset.preset!]);
      }
      if (preset.videoBitrate != null) {
        args.addAll(['-b:v', '${preset.videoBitrate}k']);
        needsEncoding = true;
      }
      if (preset.audioBitrate != null) {
        args.addAll(['-b:a', '${preset.audioBitrate}k']);
        needsEncoding = true;
      }
    }

    // Apply codec conversion settings per track
    if (item.codecSettings.isNotEmpty) {
      needsEncoding = true;

      // Group settings by type
      final videoSettings = <int, CodecConversionSettings>{};
      final audioSettings = <int, CodecConversionSettings>{};

      for (final entry in item.codecSettings.entries) {
        final streamIndex = entry.key;
        final settings = entry.value;

        // Determine if this is a video or audio stream
        final videoTrack = item.videoTracks
            .where((t) => t.streamIndex == streamIndex)
            .firstOrNull;
        final audioTrack = item.audioTracks
            .where((t) => t.streamIndex == streamIndex)
            .firstOrNull;

        if (videoTrack != null && settings.videoCodec != null) {
          videoSettings[streamIndex] = settings;
        } else if (audioTrack != null && settings.audioCodec != null) {
          audioSettings[streamIndex] = settings;
        }
      }

      // Apply video codec settings
      if (videoSettings.isNotEmpty) {
        // If all video tracks use the same codec, use global setting
        final allSameCodec =
            videoSettings.values.map((s) => s.videoCodec).toSet().length == 1;
        if (allSameCodec && videoSettings.length == item.selectedVideo.length) {
          final codec = videoSettings.values.first.videoCodec!;
          args.addAll(['-c:v', codec.ffmpegName]);
        } else {
          // Use per-stream codec settings
          for (final entry in videoSettings.entries) {
            final streamIndex = entry.key;
            final settings = entry.value;
            if (settings.videoCodec != null) {
              args.addAll(
                  ['-c:v:$streamIndex', settings.videoCodec!.ffmpegName]);
            }
          }
        }
      }

      // Apply audio codec settings
      if (audioSettings.isNotEmpty) {
        for (final entry in audioSettings.entries) {
          final streamIndex = entry.key;
          final settings = entry.value;

          if (settings.audioCodec != null) {
            args.addAll(['-c:a:$streamIndex', settings.audioCodec!.ffmpegName]);
          }
          if (settings.audioBitrate != null) {
            args.addAll(['-b:a:$streamIndex', '${settings.audioBitrate}k']);
          }
          if (settings.audioChannels != null) {
            args.addAll(
                ['-ac:$streamIndex', settings.audioChannels.toString()]);
          }
          if (settings.audioSampleRate != null) {
            args.addAll(
                ['-ar:$streamIndex', settings.audioSampleRate.toString()]);
          }
        }
      }
    }

    // Add default codec copy if no encoding is needed
    if (!needsEncoding) {
      args.addAll(['-c', 'copy']);
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

      // Parse progress from stdout
      process.stdout.transform(utf8.decoder).listen((data) {
        // FFmpeg outputs progress in format: out_time_ms=123456
        final match = RegExp(r'out_time_ms=(\d+)').firstMatch(data);
        if (match != null && item.duration != null) {
          try {
            final outTimeMs = int.parse(match.group(1)!);
            final durationParts = item.duration!.split(':');
            final totalSeconds = int.parse(durationParts[0]) * 3600 +
                int.parse(durationParts[1]) * 60 +
                int.parse(durationParts[2]);
            final progress = (outTimeMs / 1000000) / totalSeconds;
            onProgress(progress.clamp(0.0, 1.0));
          } catch (e) {
            // Progress parsing failed, continue without updating
          }
        }
      });

      // Also capture stderr for any errors/warnings
      process.stderr.transform(utf8.decoder).listen((data) {
        // Silently capture stderr - FFmpeg writes lots of info here
      });

      final exitCode = await process.exitCode;

      if (exitCode == 0) {
        onProgress(1.0); // Ensure progress is set to 100%
        return ExportResult(success: true, process: process);
      } else {
        return ExportResult(
          success: false,
          errorMessage: 'FFmpeg exit code: $exitCode',
          process: process,
        );
      }
    } catch (e) {
      return ExportResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Generate export summary text
  static String generateExportSummary(
    List<FileItem> files,
    String outputFormat,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Files to export: ${files.length}');
    buffer.writeln('Output format: $outputFormat');
    buffer.writeln('');

    int totalVideoRemoved = 0;
    int totalAudioRemoved = 0;
    int totalSubtitlesKept = 0;

    for (final file in files) {
      final videoRemoved = file.videoTracks.length - file.selectedVideo.length;
      totalVideoRemoved += videoRemoved;
      final audioRemoved = file.audioTracks.length - file.selectedAudio.length;
      totalAudioRemoved += audioRemoved;
      totalSubtitlesKept += file.selectedSubtitles.length;
    }

    buffer.writeln('Total video tracks to remove: $totalVideoRemoved');
    buffer.writeln('Total audio tracks to remove: $totalAudioRemoved');
    buffer.writeln('Total subtitle tracks to keep: $totalSubtitlesKept');
    buffer.writeln('');
    buffer.writeln('Files:');

    for (final file in files) {
      buffer.writeln('• ${file.name}');
      buffer.writeln(
          '  Video: ${file.selectedVideo.length}/${file.videoTracks.length}');
      buffer.writeln(
          '  Audio: ${file.selectedAudio.length}/${file.audioTracks.length}');
      buffer.writeln(
          '  Subtitles: ${file.selectedSubtitles.length}/${file.subtitleTracks.length}');
    }

    return buffer.toString();
  }
}

/// Result of an export operation
class ExportResult {
  final bool success;
  final String? errorMessage;
  final Process? process;

  ExportResult({
    required this.success,
    this.errorMessage,
    this.process,
  });
}

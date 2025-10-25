import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../models/codec_options.dart';
import '../models/file_item.dart';
import '../utils/rename_utils.dart';
import 'ffmpeg_capabilities_service.dart';

/// Service for exporting files using FFmpeg
class FFmpegExportService {
  static String _muxerForExtension(String ext) {
    final e = ext.toLowerCase();
    switch (e) {
      case 'mkv':
      case 'mka':
      case 'mks':
        return 'matroska';
      case 'm4v':
        return 'mp4';
      default:
        return e; // mp4, mov, webm, avi, etc.
    }
  }

  /// Build args for Stage 1: copy/re-mux selected streams with track filtering and metadata
  static List<String> _buildStage1Args({
    required String inputPath,
    required FileItem item,
    required String tempPath,
    required String outputFormat,
    bool autoFix = false,
  }) {
    final args = <String>[];

    // Add trim/cut settings (Feature #9) - must come before -i
    if (item.trimSettings != null && item.trimSettings!.enabled) {
      if (item.trimSettings!.startTime != null) {
        args.addAll(['-ss', item.trimSettings!.startTime.toString()]);
      }
    }

    // Add audio/subtitle sync offsets (Feature #17) - must come before -i
    if (item.syncOffsets != null && item.syncOffsets!.isNotEmpty) {
      for (final offset in item.syncOffsets!) {
        args.addAll(['-itsoffset', offset.offsetSeconds.toString()]);
      }
    }

    args.addAll([
      '-i',
      inputPath,
    ]);

    // Add end time for trim/cut (Feature #9) - comes after -i
    if (item.trimSettings != null && item.trimSettings!.enabled) {
      if (item.trimSettings!.endTime != null) {
        args.addAll(['-to', item.trimSettings!.endTime.toString()]);
      }
    }

    args.addAll([
      '-map', '0',
      '-y', // Overwrite output files
    ]);

    // Remove unselected video streams
    for (final track in item.videoTracks) {
      if (!item.selectedVideo.contains(track.position)) {
        args.addAll(['-map', '-0:v:${track.position}']);
      }
    }

    // Remove unselected audio streams
    for (final track in item.audioTracks) {
      if (!item.selectedAudio.contains(track.position)) {
        args.addAll(['-map', '-0:a:${track.position}']);
      }
    }

    // Handle subtitles
    final isMp4Like =
        {'mp4', 'm4v', 'mov'}.contains(outputFormat.toLowerCase());
    final isWebm = outputFormat.toLowerCase() == 'webm';
    final dropSubsForContainer = autoFix && (isMp4Like || isWebm);

    if (item.subtitleTracks.isNotEmpty && !dropSubsForContainer) {
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

    // Exclude attachments (e.g., fonts in MKV) to improve container compatibility
    args.addAll(['-map', '-0:t']);

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

    // Copy streams without re-encoding
    args.addAll([
      '-f',
      _muxerForExtension(outputFormat), // ensure muxer despite .tmp suffix
      '-c',
      'copy',
      '-map_chapters',
      '0',
      '-map_metadata',
      '0',
      // Emit progress to stdout so the UI can track Stage 1 activity as well
      '-progress',
      'pipe:1',
      tempPath,
    ]);

    return args;
  }

  /// Build args for Stage 2: re-encode with codec/quality settings
  static List<String> _buildStage2Args({
    required String inputPath,
    required FileItem item,
    required String outputPath,
    String? outputFormat,
    bool autoFix = false,
    HardwareCapabilities? hwCapabilities,
    bool useHardwareAcceleration = true,
    void Function(String)? logCallback,
  }) {
    final args = <String>[
      '-i', inputPath,
      '-map', '0',
      '-y', // Overwrite output files
    ];

    // Apply quality preset if present
    if (item.qualityPreset != null) {
      final preset = item.qualityPreset!;
      if (preset.crf != null) {
        args.addAll(['-crf', preset.crf.toString()]);
      }
      if (preset.preset != null) {
        args.addAll(['-preset', preset.preset!]);
      }
      if (preset.videoBitrate != null) {
        args.addAll(['-b:v', '${preset.videoBitrate}k']);
      }
      if (preset.audioBitrate != null) {
        args.addAll(['-b:a', '${preset.audioBitrate}k']);
      }
    }

    // Apply codec conversion settings per track
    if (item.codecSettings.isNotEmpty) {
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

        if (videoTrack != null &&
            (settings.videoCodec != null ||
                settings.customVideoCodec != null)) {
          videoSettings[streamIndex] = settings;
        } else if (audioTrack != null &&
            (settings.audioCodec != null ||
                settings.customAudioCodec != null)) {
          audioSettings[streamIndex] = settings;
        }
      }

      // Apply video codec settings
      if (videoSettings.isNotEmpty) {
        String? codecNameOf(CodecConversionSettings s) =>
            s.videoCodec?.ffmpegName ?? s.customVideoCodec;
        final allSameCodec =
            videoSettings.values.map((s) => codecNameOf(s)).toSet().length == 1;

        if (allSameCodec && videoSettings.length == item.selectedVideo.length) {
          final s0 = videoSettings.values.first;
          var codec = codecNameOf(s0);
          if (codec != null) {
            // Try to use hardware encoder if available and enabled
            String? hwEncoder;
            if (useHardwareAcceleration &&
                hwCapabilities != null &&
                hwCapabilities.hasAnyHardwareAcceleration) {
              hwEncoder = FFmpegCapabilitiesService.selectHardwareEncoder(
                  codec, hwCapabilities);
              if (hwEncoder != null &&
                  (outputFormat == null ||
                      FFmpegCapabilitiesService.isEncoderCompatibleWithContainer(
                          hwEncoder, outputFormat))) {
                logCallback?.call(
                    'Using hardware encoder: $hwEncoder (instead of $codec)');
                codec = hwEncoder;
              } else if (hwEncoder != null) {
                logCallback?.call(
                    'Hardware encoder $hwEncoder not compatible with container $outputFormat, using software encoder $codec');
              } else {
                logCallback?.call(
                    'No hardware encoder available for $codec, using software encoder');
              }
            }

            args.addAll(['-c:v', codec]);
            if (s0.videoCrf != null) {
              args.addAll(['-crf', s0.videoCrf.toString()]);
            }
            if (s0.videoPreset != null) {
              final presetFlag =
                  codec.contains('libaom-av1') ? '-cpu-used' : '-preset';
              args.addAll([presetFlag, s0.videoPreset!]);
            } else if (codec.contains('libaom-av1')) {
              // Default to a faster AV1 speed if user didn't pick one
              // libaom-av1: -cpu-used 0..8 (higher = faster, lower quality). Use 6 as balanced default.
              args.addAll(['-cpu-used', '6']);
            }
            if (s0.videoBitrateKbps != null) {
              final kb = s0.videoBitrateKbps!;
              args.addAll(['-b:v', kb == 0 ? '0' : '${kb}k']);
            }
          }
        } else {
          // Per-stream settings
          for (final e in videoSettings.entries) {
            final streamIndex = e.key;
            final s = e.value;
            var codec = s.videoCodec?.ffmpegName ?? s.customVideoCodec;
            if (codec != null) {
              // Try to use hardware encoder if available and enabled
              String? hwEncoder;
              if (useHardwareAcceleration &&
                  hwCapabilities != null &&
                  hwCapabilities.hasAnyHardwareAcceleration) {
                hwEncoder = FFmpegCapabilitiesService.selectHardwareEncoder(
                    codec, hwCapabilities);
                if (hwEncoder != null &&
                    (outputFormat == null ||
                        FFmpegCapabilitiesService
                            .isEncoderCompatibleWithContainer(
                                hwEncoder, outputFormat))) {
                  logCallback?.call(
                      'Using hardware encoder for stream $streamIndex: $hwEncoder (instead of $codec)');
                  codec = hwEncoder;
                }
              }

              args.addAll(['-c:v:$streamIndex', codec]);
            }
            if (s.videoCrf != null) {
              args.addAll(['-crf:v:$streamIndex', s.videoCrf.toString()]);
            }
            if (s.videoPreset != null) {
              final presetFlag = (codec != null && codec.contains('libaom-av1'))
                  ? '-cpu-used:v:$streamIndex'
                  : '-preset:v:$streamIndex';
              args.addAll([presetFlag, s.videoPreset!]);
            } else if ((codec ?? '').contains('libaom-av1')) {
              // Apply default AV1 speed per-stream when not specified
              args.addAll(['-cpu-used:v:$streamIndex', '6']);
            }
            if (s.videoBitrateKbps != null) {
              final kb = s.videoBitrateKbps!;
              args.addAll(['-b:v:$streamIndex', kb == 0 ? '0' : '${kb}k']);
            }
          }
        }
      }

      // Apply audio codec settings
      final hasExplicitAudioSettings = audioSettings.isNotEmpty;
      if (hasExplicitAudioSettings) {
        for (final entry in audioSettings.entries) {
          final streamIndex = entry.key;
          final settings = entry.value;

          final codec =
              settings.audioCodec?.ffmpegName ?? settings.customAudioCodec;
          if (codec != null) {
            args.addAll(['-c:a:$streamIndex', codec]);
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
      } else if (autoFix && outputFormat != null) {
        // Auto-fix for container when user didn't specify audio transcodes
        final fmt = outputFormat.toLowerCase();
        final mp4Like = {'mp4', 'm4v', 'mov'}.contains(fmt);
        final webm = fmt == 'webm';
        if (mp4Like || webm) {
          for (final a in item.audioTracks
              .where((t) => item.selectedAudio.contains(t.position))) {
            final codec = (a.codec ?? '').toLowerCase();
            final simple = codec
                .split(RegExp(r'[^a-z0-9]+'))
                .where((s) => s.isNotEmpty)
                .join();
            bool needsTranscode = false;
            if (mp4Like) {
              const ok = {'aac', 'ac3', 'eac3', 'alac', 'mp3'};
              needsTranscode = !ok.any((k) => simple.contains(k));
            } else if (webm) {
              const ok = {'vorbis', 'opus'};
              needsTranscode = !ok.any((k) => simple.contains(k));
            }
            if (needsTranscode) {
              final si = a.streamIndex;
              final target = mp4Like ? 'aac' : 'libopus';
              final br = (a.channels ?? 2) >= 6 ? 384 : 192; // kbps
              args.addAll(['-c:a:$si', target]);
              args.addAll(['-b:a:$si', '${br}k']);
            }
          }
        }
      }
    }

    // Copy subtitle streams during re-encode (or convert if specified)
    final selectedSubs = item.selectedSubtitles.toList()..sort();
    for (var i = 0; i < selectedSubs.length; i++) {
      final pos = selectedSubs[i];
      final track = item.subtitleTracks[pos];
      final settings = item.codecSettings[track.streamIndex];

      if (settings?.subtitleFormat != null &&
          settings!.subtitleFormat != SubtitleFormat.copy) {
        // Convert subtitle format
        args.addAll(['-c:s:$i', settings.subtitleFormat!.ffmpegName]);
      } else {
        // Copy subtitle
        args.addAll(['-c:s:$i', 'copy']);
      }
    }

    // Apply resolution/framerate changes (Feature #10)
    final filters = <String>[];
    if (item.resolutionSettings != null && item.resolutionSettings!.enabled) {
      final scaleFilter = item.resolutionSettings!.scaleFilter;
      if (scaleFilter != null) {
        filters.add(scaleFilter);
      }
      if (item.resolutionSettings!.framerate != null) {
        args.addAll(['-r', item.resolutionSettings!.framerate.toString()]);
      }
    }

    if (filters.isNotEmpty) {
      args.addAll(['-vf', filters.join(',')]);
    }

    args.addAll([
      '-map_chapters',
      '0',
      '-map_metadata',
      '0',
      '-progress',
      'pipe:1',
      outputPath,
    ]);

    return args;
  }

  /// Returns a list of compatibility issues for the chosen output container.
  /// Empty list means the current selection should remux/encode fine.
  static List<String> _getCompatibilityIssues(
      FileItem item, String outputFormat) {
    final issues = <String>[];
    final fmt = outputFormat.toLowerCase();

    bool isMp4Like = {'mp4', 'm4v', 'mov'}.contains(fmt);
    bool isWebm = fmt == 'webm';

    // Selected tracks
    final selectedAudio = item.audioTracks
        .where((t) => item.selectedAudio.contains(t.position))
        .toList();
    final selectedVideo = item.videoTracks
        .where((t) => item.selectedVideo.contains(t.position))
        .toList();
    final selectedSubtitleCount = item.selectedSubtitles.length;

    if (isMp4Like) {
      // Subtitles in MP4: only mov_text is widely supported; MKV ASS/SSA/PGS won't copy.
      if (selectedSubtitleCount > 0) {
        issues.add(
            'MP4 does not support copying most subtitle formats (e.g., ASS/SSA/PGS). Please drop subtitles or convert to mov_text.');
      }
      // Audio in MP4: allow aac, ac3, eac3, alac, mp3; flag flac/opus/vorbis/others
      const mp4AudioOk = {'aac', 'ac3', 'eac3', 'alac', 'mp3'};
      for (final a in selectedAudio) {
        final codec = (a.codec ?? '').toLowerCase();
        if (codec.isEmpty) continue;
        final simple = codec
            .split(RegExp(r'[^a-z0-9]+'))
            .where((s) => s.isNotEmpty)
            .join();
        final containsOk = mp4AudioOk.any((ok) => simple.contains(ok));
        if (!containsOk) {
          issues.add(
              'Audio track #${a.position} codec "$codec" is not MP4-friendly. Transcode to AAC or choose MKV.');
        }
      }
      // Video: allow h264, hevc, mpeg4, av1
      const mp4VideoOk = {'h264', 'hevc', 'h265', 'mpeg4', 'av1'};
      for (final v in selectedVideo) {
        final codec = (v.codec ?? '').toLowerCase();
        if (codec.isEmpty) continue;
        final simple = codec
            .split(RegExp(r'[^a-z0-9]+'))
            .where((s) => s.isNotEmpty)
            .join();
        final ok = mp4VideoOk.any((k) => simple.contains(k));
        if (!ok) {
          issues.add(
              'Video track #${v.position} codec "$codec" may not be MP4-compatible.');
        }
      }
    } else if (isWebm) {
      // webm: vp8/vp9/av1 video; vorbis/opus audio; no ASS subs
      const webmVideoOk = {'vp8', 'vp9', 'av1'};
      const webmAudioOk = {'vorbis', 'opus'};
      for (final v in selectedVideo) {
        final codec = (v.codec ?? '').toLowerCase();
        final simple = codec
            .split(RegExp(r'[^a-z0-9]+'))
            .where((s) => s.isNotEmpty)
            .join();
        final ok = webmVideoOk.any((k) => simple.contains(k));
        if (!ok) {
          issues.add('WebM requires VP8/VP9/AV1 video (found "$codec").');
        }
      }
      for (final a in selectedAudio) {
        final codec = (a.codec ?? '').toLowerCase();
        final simple = codec
            .split(RegExp(r'[^a-z0-9]+'))
            .where((s) => s.isNotEmpty)
            .join();
        final ok = webmAudioOk.any((k) => simple.contains(k));
        if (!ok) {
          issues.add('WebM requires Vorbis or Opus audio (found "$codec").');
        }
      }
      if (selectedSubtitleCount > 0) {
        issues.add('WebM does not support copying ASS/SSA subtitles.');
      }
    }

    return issues;
  }

  /// Check if encoding is needed (any codec or quality settings)
  static bool _needsEncoding(FileItem item) {
    if (item.qualityPreset != null) {
      final preset = item.qualityPreset!;
      if (preset.crf != null ||
          preset.videoBitrate != null ||
          preset.audioBitrate != null) {
        return true;
      }
    }

    if (item.codecSettings.isNotEmpty) {
      for (final settings in item.codecSettings.values) {
        if (settings.videoCodec != null ||
            settings.customVideoCodec != null ||
            settings.audioCodec != null ||
            settings.customAudioCodec != null ||
            settings.videoCrf != null ||
            settings.videoPreset != null ||
            settings.videoBitrateKbps != null) {
          return true;
        }
      }
    }

    return false;
  }

  /// Run FFmpeg process and track progress
  static Future<ExportResult> _runFFmpegProcess(
      List<String> args, String? duration, Function(double progress) onProgress,
      {Function(String message)? onLog,
      String stageLabel = '',
      void Function(Process process, String stageLabel)?
          onProcessStarted}) async {
    try {
      final process = await Process.start('ffmpeg', args);
      // Notify caller immediately so they can register/track the live process for cancellation
      if (onProcessStarted != null) {
        onProcessStarted(process, stageLabel);
      }

      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();

      // Helper to parse HH:MM:SS(.ms) into seconds
      double? parseHms(String s) {
        final m = RegExp(r'^(\d+):(\d+):(\d+(?:\.\d+)?)$').firstMatch(s.trim());
        if (m == null) return null;
        final h = double.tryParse(m.group(1)!);
        final mm = double.tryParse(m.group(2)!);
        final ss = double.tryParse(m.group(3)!);
        if (h == null || mm == null || ss == null) return null;
        return h * 3600 + mm * 60 + ss;
      }

      final double? totalSeconds = duration == null
          ? null
          : parseHms(duration) ??
              () {
                try {
                  final parts = duration.split(':');
                  if (parts.length != 3) return null;
                  return (int.parse(parts[0]) * 3600 +
                          int.parse(parts[1]) * 60 +
                          double.parse(parts[2]))
                      .toDouble();
                } catch (_) {
                  return null;
                }
              }();

      // Parse progress from stdout (-progress pipe:1), also capture for logs
      int lastLoggedPercent = -1;
      process.stdout.transform(utf8.decoder).listen((data) {
        stdoutBuffer.write(data);
        final match = RegExp(r'out_time_ms=(\d+)').firstMatch(data);
        if (match != null && totalSeconds != null && totalSeconds > 0) {
          try {
            final outTimeMs = int.parse(match.group(1)!);
            final progress = (outTimeMs / 1000000) / totalSeconds;
            onProgress(progress.clamp(0.0, 1.0));
            final percent = (progress * 100).clamp(0, 100).toInt();
            if (onLog != null && percent != lastLoggedPercent) {
              lastLoggedPercent = percent;
              final label =
                  stageLabel.isEmpty ? 'Progress' : '$stageLabel progress';
              onLog('$label: $percent%');
            }
          } catch (_) {
            // ignore parse errors
          }
        }
      });

      // Capture stderr for logs and fallback progress (parse time=)
      process.stderr.transform(utf8.decoder).listen((data) {
        stderrBuffer.write(data);
        if (totalSeconds != null && totalSeconds > 0) {
          final tm =
              RegExp(r'time=\s*(\d+:\d+:\d+(?:\.\d+)?)').firstMatch(data);
          if (tm != null) {
            final secs = parseHms(tm.group(1)!);
            if (secs != null) {
              final progress = (secs / totalSeconds).clamp(0.0, 1.0);
              onProgress(progress);
              final percent = (progress * 100).clamp(0, 100).toInt();
              if (onLog != null && percent != lastLoggedPercent) {
                lastLoggedPercent = percent;
                final label =
                    stageLabel.isEmpty ? 'Progress' : '$stageLabel progress';
                onLog('$label: $percent%');
              }
            }
          }
        }
      });

      final exitCode = await process.exitCode;

      if (exitCode == 0) {
        onProgress(1.0);
        if (onLog != null && stageLabel.isNotEmpty) {
          onLog('$stageLabel: 100%');
        }
        return ExportResult(
          success: true,
          process: process,
          exitCode: exitCode,
          stdoutLog: stdoutBuffer.toString(),
          stderrLog: stderrBuffer.toString(),
        );
      } else {
        // Heuristics: map common termination codes to a clearer cancellation message
        String message = 'FFmpeg exit code: $exitCode';
        // Windows Ctrl+C / termination often reports 0xC000013A (3221225786) or -1073741510
        // Some kills may surface as -1 or 255 depending on how the process is terminated
        if (exitCode == -1 ||
            exitCode == 130 ||
            exitCode == 255 ||
            exitCode == 3221225786 ||
            exitCode == -1073741510) {
          message = 'Cancelled by user';
        }
        return ExportResult(
          success: false,
          errorMessage: message,
          process: process,
          exitCode: exitCode,
          stdoutLog: stdoutBuffer.toString(),
          stderrLog: stderrBuffer.toString(),
        );
      }
    } catch (e) {
      return ExportResult(success: false, errorMessage: e.toString());
    }
  }

  /// Export a single file with the user's track selections (two-stage process)
  static Future<ExportResult> exportFile({
    required FileItem item,
    required Directory outputDir,
    required String outputFormat,
    required Function(double progress) onProgress,
    Function(String message)? onLog,
    void Function(Process process, String stageLabel)? onProcessStarted,
    bool autoFixIncompat = false,
    String? sessionLogPath,
    HardwareCapabilities? hwCapabilities,
    bool useHardwareAcceleration = true,
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
      outputFileName =
          '${path.basenameWithoutExtension(outputFileName)}.$extension';
    } else {
      outputFileName =
          '${path.basenameWithoutExtension(item.outputName)}.$extension';
    }

    final outPath = path.join(outputDir.path, outputFileName);

    // Ensure output directory exists before any file/log writes
    try {
      if (!outputDir.existsSync()) {
        outputDir.createSync(recursive: true);
      }
    } catch (_) {
      // Continue; we'll still try to export and log with fallback
    }

    // Prepare run log buffer early so we can always persist logs, even on preflight failure
    final runLog = StringBuffer();
    final startedAt = DateTime.now();
    runLog.writeln('FFmpeg Export Log');
    runLog.writeln('Source: ${item.path}');
    runLog.writeln('Destination dir: ${outputDir.path}');
    runLog.writeln('Planned output: $outputFileName');
    runLog.writeln('Started: $startedAt');

    // Helper to save run log to primary path, with fallback to input file directory on failure
    void saveRunLog(String text) {
      // Choose log target: sessionLogPath if provided; else per-file .log next to output
      final primaryLogPath =
          sessionLogPath ?? path.setExtension(outPath, '.log');
      try {
        final logFile = File(primaryLogPath);
        logFile.parent.createSync(recursive: true);
        // Append to allow multiple files to accumulate in one session log
        logFile.writeAsStringSync(text + (text.endsWith('\n') ? '' : '\n'),
            mode: FileMode.append);
      } catch (_) {
        try {
          final fallbackDir = path.dirname(item.path);
          final fallbackLogPath = path.join(
            fallbackDir,
            path.basename(primaryLogPath),
          );
          File(fallbackLogPath).writeAsStringSync(
              text + (text.endsWith('\n') ? '' : '\n'),
              mode: FileMode.append);
        } catch (_) {
          // Swallow as last resort; nothing else to do
        }
      }
    }

    // Preflight container compatibility check
    final compatIssues = _getCompatibilityIssues(item, extension);
    if (compatIssues.isNotEmpty && !autoFixIncompat) {
      final msg = StringBuffer()
        ..writeln('Incompatible selection for .$extension container:')
        ..writeln(compatIssues.map((e) => '- $e').join('\n'))
        ..writeln(
            'Tip: Choose MKV, or transcode incompatible tracks (e.g., audio to AAC, subtitles to mov_text or drop).');
      if (onLog != null) onLog(msg.toString());
      runLog.writeln('Preflight check failed for container: .$extension');
      runLog.writeln(compatIssues.map((e) => '- $e').join('\n'));
      final endedAt = DateTime.now();
      runLog.writeln(
          'Finished: $endedAt (elapsed: ${endedAt.difference(startedAt)})');
      saveRunLog(runLog.toString());
      return ExportResult(
          success: false, errorMessage: 'Container compatibility check failed');
    }
    if (compatIssues.isNotEmpty && autoFixIncompat) {
      if (onLog != null) {
        onLog('Auto-fix enabled. Applying adjustments for .$extension:');
        for (final issue in compatIssues) {
          onLog(' - $issue');
        }
      }
      runLog.writeln('Auto-fix enabled. Applying adjustments for .$extension:');
      for (final issue in compatIssues) {
        runLog.writeln(' - $issue');
      }
    }

    final tempPath = '$outPath.tmp';
    final needsEncoding = _needsEncoding(item);

    // Log plan
    if (onLog != null) {
      final summary = StringBuffer();
      final baseFileName = path.basename(item.path);
      summary.writeln('Export plan for $baseFileName');
      summary.writeln('Stage 1: Copy/re-mux selected streams (no encoding)');
      if (needsEncoding) {
        summary.writeln('Stage 2: Re-encode with codec/quality settings');
      } else {
        summary.writeln('Stage 2: Skipped (no encoding needed)');
      }
      onLog(summary.toString());
      runLog.writeln(summary.toString());
    } else {
      final baseFileName = path.basename(item.path);
      runLog.writeln('Export plan for $baseFileName');
      runLog.writeln('Stage 1: Copy/re-mux selected streams (no encoding)');
      runLog.writeln(needsEncoding
          ? 'Stage 2: Re-encode with codec/quality settings'
          : 'Stage 2: Skipped (no encoding needed)');
    }

    String argsToCmd(List<String> args) {
      final joined = args.map((a) => a.contains(' ') ? '"$a"' : a).join(' ');
      return 'ffmpeg $joined';
    }

    void logToFile(String text) {
      runLog.writeln(text);
    }

    try {
      // Stage 1: Copy selected streams with metadata to temp file
      if (onLog != null) onLog('Stage 1: Copy/re-mux streams...');
      final stage1Args = _buildStage1Args(
        inputPath: item.path,
        item: item,
        tempPath: tempPath,
        outputFormat: extension,
        autoFix: autoFixIncompat,
      );
      logToFile('Stage 1 command:');
      logToFile(argsToCmd(stage1Args));
      var result = await _runFFmpegProcess(stage1Args, item.duration, (p) {
        onProgress(needsEncoding ? p * 0.5 : p);
      },
          onLog: onLog,
          stageLabel: 'Stage 1',
          onProcessStarted: onProcessStarted);
      if (result.stdoutLog != null && result.stdoutLog!.isNotEmpty) {
        logToFile('Stage 1 stdout:');
        logToFile(result.stdoutLog!);
      }
      if (result.stderrLog != null && result.stderrLog!.isNotEmpty) {
        logToFile('Stage 1 stderr:');
        logToFile(result.stderrLog!);
      }
      if (!result.success) {
        final isCancelled =
            (result.errorMessage ?? '').toLowerCase().contains('cancelled');
        if (onLog != null) {
          onLog(isCancelled
              ? 'Stage 1 cancelled by user.'
              : 'Stage 1 failed: ${result.errorMessage}');
        }
        final endedAt = DateTime.now();
        logToFile(isCancelled
            ? 'Stage 1 cancelled by user.'
            : 'Stage 1 failed: ${result.errorMessage ?? 'Unknown error'}');
        logToFile(
            'Finished: $endedAt (elapsed: ${endedAt.difference(startedAt)})');
        saveRunLog(runLog.toString());
        return result;
      }
      if (onLog != null) {
        onLog('Stage 1 complete. Temp file: $tempPath');
      }

      // Stage 2: Re-encode if needed
      if (needsEncoding) {
        if (onLog != null) {
          onLog('Stage 2: Re-encode with codec/quality settings...');
        }
        final stage2Args = _buildStage2Args(
          inputPath: tempPath,
          item: item,
          outputPath: outPath,
          outputFormat: extension,
          autoFix: autoFixIncompat,
          hwCapabilities: hwCapabilities,
          useHardwareAcceleration: useHardwareAcceleration,
          logCallback: (msg) {
            onLog?.call(msg);
            logToFile(msg);
          },
        );
        logToFile('Stage 2 command:');
        logToFile(argsToCmd(stage2Args));
        result = await _runFFmpegProcess(stage2Args, item.duration, (p) {
          onProgress(0.5 + p * 0.5);
        },
            onLog: onLog,
            stageLabel: 'Stage 2',
            onProcessStarted: onProcessStarted);
        if (result.stdoutLog != null && result.stdoutLog!.isNotEmpty) {
          logToFile('Stage 2 stdout:');
          logToFile(result.stdoutLog!);
        }
        if (result.stderrLog != null && result.stderrLog!.isNotEmpty) {
          logToFile('Stage 2 stderr:');
          logToFile(result.stderrLog!);
        }
        if (!result.success) {
          final isCancelled =
              (result.errorMessage ?? '').toLowerCase().contains('cancelled');
          if (onLog != null) {
            onLog(isCancelled
                ? 'Stage 2 cancelled by user.'
                : 'Stage 2 failed: ${result.errorMessage}');
          }
          final endedAt = DateTime.now();
          logToFile(isCancelled
              ? 'Stage 2 cancelled by user.'
              : 'Stage 2 failed: ${result.errorMessage ?? 'Unknown error'}');
          logToFile(
              'Finished: $endedAt (elapsed: ${endedAt.difference(startedAt)})');
          saveRunLog(runLog.toString());
          return result;
        }
        if (onLog != null) {
          onLog('Stage 2 complete.');
        }

        // Clean up temp file
        try {
          File(tempPath).deleteSync();
        } catch (e) {
          if (onLog != null) {
            onLog('Warning: Could not delete temp file $tempPath: $e');
          }
        }
      } else {
        // No encoding needed; move temp to final output
        try {
          File(tempPath).renameSync(outPath);
        } catch (e) {
          if (onLog != null) {
            onLog('Error moving temp file to output: $e');
          }
          return ExportResult(
              success: false, errorMessage: 'Failed to finalize output: $e');
        }
      }

      onProgress(1.0);
      final endedAt = DateTime.now();
      logToFile('Success: output -> $outPath');
      logToFile(
          'Finished: $endedAt (elapsed: ${endedAt.difference(startedAt)})');
      saveRunLog(runLog.toString());
      return ExportResult(success: true, process: null);
    } catch (e) {
      final endedAt = DateTime.now();
      logToFile('Unexpected error: $e');
      logToFile(
          'Finished: $endedAt (elapsed: ${endedAt.difference(startedAt)})');
      saveRunLog(runLog.toString());
      return ExportResult(success: false, errorMessage: e.toString());
    }
  }

  /// Generate export summary text
  static String generateExportSummary(
      List<FileItem> files, String outputFormat) {
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

    // Collect and display codec/quality settings
    bool hasCodecSettings = false;
    for (final file in files) {
      if (file.codecSettings.isNotEmpty || file.qualityPreset != null) {
        hasCodecSettings = true;
        break;
      }
    }

    if (hasCodecSettings) {
      buffer.writeln('Encoding Settings:');
      for (final file in files) {
        if (file.codecSettings.isEmpty && file.qualityPreset == null) {
          buffer.writeln('• ${file.name}: No encoding (copy only)');
          continue;
        }

        final encInfo = <String>[];

        // Quality preset
        if (file.qualityPreset != null) {
          final q = file.qualityPreset!;
          if (q.crf != null) {
            encInfo.add('CRF: ${q.crf}');
          }
          if (q.videoBitrate != null) {
            encInfo.add('Video BR: ${q.videoBitrate}k');
          }
          if (q.audioBitrate != null) {
            encInfo.add('Audio BR: ${q.audioBitrate}k');
          }
        }

        // Per-track codec settings
        for (final entry in file.codecSettings.entries) {
          final streamIdx = entry.key;
          final settings = entry.value;

          // Find track name
          String trackName = 'Stream #$streamIdx';
          for (final vt in file.videoTracks) {
            if (vt.streamIndex == streamIdx) {
              trackName = 'Video #${vt.position}';
              break;
            }
          }
          for (final at in file.audioTracks) {
            if (at.streamIndex == streamIdx) {
              trackName = 'Audio #${at.position}';
              break;
            }
          }

          final trackCodecs = <String>[];
          if (settings.videoCodec != null) {
            trackCodecs.add('Video: ${settings.videoCodec!.displayName}');
            if (settings.videoCrf != null) {
              trackCodecs.add('CRF: ${settings.videoCrf}');
            }
            if (settings.videoPreset != null) {
              trackCodecs.add('Preset: ${settings.videoPreset}');
            }
            if (settings.videoBitrateKbps != null) {
              trackCodecs.add('BR: ${settings.videoBitrateKbps}k');
            }
          }
          if (settings.audioCodec != null) {
            trackCodecs.add('Audio: ${settings.audioCodec!.displayName}');
            if (settings.audioBitrate != null) {
              trackCodecs.add('BR: ${settings.audioBitrate}k');
            }
            if (settings.audioChannels != null) {
              trackCodecs.add('Channels: ${settings.audioChannels}');
            }
            if (settings.audioSampleRate != null) {
              trackCodecs.add('Sample: ${settings.audioSampleRate}Hz');
            }
          }

          if (trackCodecs.isNotEmpty) {
            encInfo.add('  $trackName: ${trackCodecs.join(', ')}');
          }
        }

        if (encInfo.isNotEmpty) {
          buffer.writeln('• ${file.name}');
          for (final info in encInfo) {
            buffer.writeln(info);
          }
        } else {
          buffer.writeln('• ${file.name}: No encoding (copy only)');
        }
      }
      buffer.writeln('');
    }

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
  final int? exitCode;
  final String? stdoutLog;
  final String? stderrLog;

  ExportResult({
    required this.success,
    this.errorMessage,
    this.process,
    this.exitCode,
    this.stdoutLog,
    this.stderrLog,
  });
}

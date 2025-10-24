import 'dart:io';
import 'track.dart';
import 'metadata.dart';
import 'codec_options.dart';
import 'quality_preset.dart';
import 'rename_pattern.dart';
import 'trim_settings.dart';
import 'resolution_settings.dart';
import 'sync_offset.dart';
import 'multi_profile_export_config.dart';

/// Data model representing a file with its streams and selections.
class FileItem {
  final String path;
  String name;
  String outputName;
  final List<Track> videoTracks;
  final List<Track> audioTracks;
  final List<Track> subtitleTracks;
  // Per-file selections used by UI
  Set<int> selectedVideo;
  Set<int> selectedAudio;
  // Deprecated in favor of selectedSubtitles + defaultSubtitle, but kept for compatibility if needed
  int? selectedSubtitle;
  // Multiple subtitle selections
  Set<int> selectedSubtitles;
  int? defaultVideo;
  int? defaultAudio;
  int? defaultSubtitle;
  String exportStatus;
  double exportProgress;
  int? fileSize;
  String? duration;
  bool isExpanded;
  Process? currentProcess;
  // Metadata
  FileMetadata? fileMetadata;
  Map<int, TrackMetadata> trackMetadata; // keyed by track stream index
  // Codec conversion settings
  Map<int, CodecConversionSettings>
      codecSettings; // keyed by track stream index
  QualityPreset? qualityPreset;
  // Verification results
  bool? verificationPassed;
  String? verificationMessage;
  // Rename pattern
  RenamePattern? renamePattern;
  int? renameIndex;
  int? renameEpisode;
  int? renameSeason;
  int? renameYear;
  // Trim/Cut settings (Feature #9)
  TrimSettings? trimSettings;
  // Resolution/Framerate settings (Feature #10)
  ResolutionSettings? resolutionSettings;
  // Audio/Subtitle sync offsets (Feature #17)
  List<SyncOffset>? syncOffsets;
  // ETA tracking (Feature #25)
  DateTime? exportStartTime;
  Duration? estimatedTimeRemaining;
  // Multi-profile export (Feature #14)
  MultiProfileExportConfig? multiProfileConfig;

  FileItem({
    required this.path,
    String? name,
    String? outputName,
    List<Track>? videoTracks,
    required this.audioTracks,
    required this.subtitleTracks,
    Set<int>? selectedVideo,
    Set<int>? selectedAudio,
    this.selectedSubtitle,
    Set<int>? selectedSubtitles,
    this.defaultVideo,
    this.defaultAudio,
    this.defaultSubtitle,
    String? exportStatus,
    double? exportProgress,
    this.fileSize,
    this.duration,
    this.isExpanded = true,
    this.fileMetadata,
    Map<int, TrackMetadata>? trackMetadata,
    Map<int, CodecConversionSettings>? codecSettings,
    this.qualityPreset,
    this.verificationPassed,
    this.verificationMessage,
    this.renamePattern,
    this.renameIndex,
    this.renameEpisode,
    this.renameSeason,
    this.renameYear,
    this.trimSettings,
    this.resolutionSettings,
    this.syncOffsets,
    this.exportStartTime,
    this.estimatedTimeRemaining,
    this.multiProfileConfig,
  })  : name = name ?? File(path).uri.pathSegments.last,
        outputName = outputName ?? File(path).uri.pathSegments.last,
        videoTracks = videoTracks ?? [],
        selectedVideo = selectedVideo ?? <int>{},
        selectedAudio = selectedAudio ?? <int>{},
        selectedSubtitles = selectedSubtitles ?? <int>{},
        exportStatus = exportStatus ?? '',
        exportProgress = exportProgress ?? 0.0,
        trackMetadata = trackMetadata ?? {},
        codecSettings = codecSettings ?? {};
}

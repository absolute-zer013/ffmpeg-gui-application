import 'dart:io';
import 'track.dart';
import 'metadata.dart';

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
  })  : name = name ?? File(path).uri.pathSegments.last,
        outputName = outputName ?? File(path).uri.pathSegments.last,
        videoTracks = videoTracks ?? [],
        selectedVideo = selectedVideo ?? <int>{},
        selectedAudio = selectedAudio ?? <int>{},
        selectedSubtitles = selectedSubtitles ?? <int>{},
        exportStatus = exportStatus ?? '',
        exportProgress = exportProgress ?? 0.0,
        trackMetadata = trackMetadata ?? {};
}

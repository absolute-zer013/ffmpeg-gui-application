import 'dart:io';
import '../models/track.dart';
import '../models/file_item.dart';

/// Service for probing video files using FFprobe
class FFprobeService {
  /// Probes the given video file for video, audio and subtitle streams using ffprobe.
  static Future<FileItem> probeFile(String path) async {
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

    // Probe video tracks.
    final videoResult = await Process.run(
      'ffprobe',
      [
        '-v',
        'error',
        '-select_streams',
        'v',
        '-show_entries',
        'stream=index,codec_name,width,height,r_frame_rate:stream_tags=language,title',
        '-of',
        'csv=p=0:s=|',
        path,
      ],
    );
    final videoLines = videoResult.stdout.toString().split('\n');
    final videoTracks = <Track>[];
    int videoPos = 0;
    for (final line in videoLines) {
      if (line.trim().isEmpty) continue;
      final parts = line.split('|');
      if (parts.isEmpty) continue;
      
      final streamIndex = int.tryParse(parts[0]) ?? videoPos;
      final codec = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : 'unknown';
      final width = parts.length > 2 ? int.tryParse(parts[2]) : null;
      final height = parts.length > 3 ? int.tryParse(parts[3]) : null;
      final frameRate = parts.length > 4 && parts[4].isNotEmpty ? parts[4] : null;
      final language = parts.length > 5 && parts[5].isNotEmpty ? parts[5] : 'und';
      final title = parts.length > 6 && parts[6].isNotEmpty ? parts[6] : null;
      
      final resolutionStr = (width != null && height != null) ? '${width}x$height' : '';
      final codecStr = codec.toUpperCase();
      final description = title != null 
          ? '$language ($title) [$codecStr${resolutionStr.isNotEmpty ? " $resolutionStr" : ""}]'
          : 'Video $language [$codecStr${resolutionStr.isNotEmpty ? " $resolutionStr" : ""}]';
      
      videoTracks.add(Track(
        position: videoPos,
        language: language,
        title: title,
        description: description,
        streamIndex: streamIndex,
        type: TrackType.video,
        codec: codec,
        width: width,
        height: height,
        frameRate: frameRate,
      ));
      videoPos++;
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
      final streamIndex = int.tryParse(parts[0]) ?? audioPos;
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
        streamIndex: streamIndex,
        type: TrackType.audio,
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
      final streamIndex = int.tryParse(parts[0]) ?? subPos;
      final language =
          parts.length > 1 && parts[1].isNotEmpty ? parts[1] : 'und';
      final title = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;
      final desc = title != null ? '$language ($title)' : 'Subtitle $language';
      subtitleTracks.add(Track(
        position: subPos,
        language: language,
        title: title,
        description: desc,
        streamIndex: streamIndex,
        type: TrackType.subtitle,
      ));
      subPos++;
    }

    // Initialize selections: select all video and audio tracks, first subtitle by default
    Set<int> initialSelectedVideo = <int>{};
    int? defaultVideo;
    for (int i = 0; i < videoTracks.length; i++) {
      initialSelectedVideo.add(i);
    }
    if (videoTracks.isNotEmpty) {
      defaultVideo = 0;
    }

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
      videoTracks: videoTracks,
      audioTracks: audioTracks,
      subtitleTracks: subtitleTracks,
      selectedVideo: initialSelectedVideo,
      selectedAudio: initialSelectedAudio,
      defaultVideo: defaultVideo,
      defaultAudio: defaultAudio,
      selectedSubtitles: initialSelectedSubtitles,
      defaultSubtitle: defaultSubtitle,
      fileSize: fileSize,
      duration: duration,
    );
  }

  /// Check if FFmpeg is available in system PATH
  static Future<bool> checkFFmpegAvailable() async {
    try {
      final result = await Process.run('ffmpeg', ['-version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}

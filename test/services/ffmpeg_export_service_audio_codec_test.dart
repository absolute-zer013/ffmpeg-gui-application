import 'package:flutter_test/flutter_test.dart';

import 'package:ffmpeg_filter_app/models/codec_options.dart';
import 'package:ffmpeg_filter_app/models/file_item.dart';
import 'package:ffmpeg_filter_app/models/track.dart';
import 'package:ffmpeg_filter_app/services/ffmpeg_export_service.dart';

void main() {
  test('Audio stage targets correct output audio index', () {
    // Simulate a common case where ffprobe streamIndex is global (#1), while
    // the audio stream is the first (and only) audio stream in the output.
    final audioTrack = Track(
      position: 0, // first audio stream (a:0)
      language: 'jpn',
      description: 'Audio',
      streamIndex: 1, // global stream index in the container
      type: TrackType.audio,
      codec: 'vorbis',
      channels: 2,
    );

    final item = FileItem(
      path: 'input.mkv',
      audioTracks: [audioTrack],
      subtitleTracks: const [],
      videoTracks: const [],
      selectedAudio: {0},
      selectedVideo: const {},
      selectedSubtitles: const {},
      codecSettings: {
        1: CodecConversionSettings(
          audioCodec: AudioCodec.aac,
          audioBitrate: 128,
        ),
      },
    );

    final args = FFmpegExportService.buildAudioEncodeArgsForTesting(
      inputPath: 'temp.mkv',
      item: item,
      outputPath: 'out.mkv',
      outputFormat: 'mkv',
    );

    final joined = args.join(' ');
    expect(joined.contains('-c:v copy'), isTrue);
    expect(joined.contains('-c:a:0 aac'), isTrue);
    expect(joined.contains('-b:a:0 128k'), isTrue);
    expect(joined.contains('-c:a:1 aac'), isFalse);
  });

  test('Audio stage remaps when selection is non-contiguous', () {
    // Two audio tracks in the source: a:0 and a:2 selected (a:1 removed).
    // Stage 1 output will renumber them to a:0 and a:1.
    final a0 = Track(
      position: 0,
      language: 'jpn',
      description: 'Audio 0',
      streamIndex: 1,
      type: TrackType.audio,
      codec: 'flac',
      channels: 2,
    );
    final a2 = Track(
      position: 2,
      language: 'eng',
      description: 'Audio 2',
      streamIndex: 4,
      type: TrackType.audio,
      codec: 'vorbis',
      channels: 2,
    );

    final item = FileItem(
      path: 'input.mkv',
      audioTracks: [a0, a2],
      subtitleTracks: const [],
      videoTracks: const [],
      selectedAudio: {2},
      selectedVideo: const {},
      selectedSubtitles: const {},
      codecSettings: {
        4: CodecConversionSettings(
          audioCodec: AudioCodec.aac,
          audioBitrate: 128,
        ),
      },
    );

    final args = FFmpegExportService.buildAudioEncodeArgsForTesting(
      inputPath: 'temp.mkv',
      item: item,
      outputPath: 'out.mkv',
      outputFormat: 'mkv',
    );

    final joined = args.join(' ');
    expect(joined.contains('-c:v copy'), isTrue);
    // Only one selected audio stream => it becomes output a:0.
    expect(joined.contains('-c:a:0 aac'), isTrue);
    expect(joined.contains('-b:a:0 128k'), isTrue);
    // Must not try to target a:2.
    expect(joined.contains('-c:a:2'), isFalse);
  });
}

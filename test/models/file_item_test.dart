import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/file_item.dart';
import 'package:ffmpeg_filter_app/models/track.dart';

void main() {
  group('FileItem Model', () {
    late FileItem fileItem;

    setUp(() {
      fileItem = FileItem(
        path: '/path/to/video.mkv',
        audioTracks: [],
        subtitleTracks: [],
      );
    });

    test('FileItem initializes with default values', () {
      expect(fileItem.path, equals('/path/to/video.mkv'));
      expect(fileItem.name, equals('video.mkv'));
      expect(fileItem.outputName, equals('video.mkv'));
      expect(fileItem.videoTracks, isEmpty);
      expect(fileItem.audioTracks, isEmpty);
      expect(fileItem.subtitleTracks, isEmpty);
      expect(fileItem.selectedVideo, isEmpty);
      expect(fileItem.selectedAudio, isEmpty);
      expect(fileItem.selectedSubtitles, isEmpty);
      expect(fileItem.exportStatus, isEmpty);
      expect(fileItem.exportProgress, equals(0.0));
    });

    test('FileItem can add video tracks', () {
      final track = Track(
        position: 0,
        language: 'und',
        description: 'Video Track',
        type: TrackType.video,
        width: 1920,
        height: 1080,
      );

      fileItem.videoTracks.add(track);

      expect(fileItem.videoTracks.length, equals(1));
      expect(fileItem.videoTracks.first.position, equals(0));
    });

    test('FileItem can add audio tracks', () {
      final track = Track(
        position: 0,
        language: 'en',
        description: 'English Audio',
        type: TrackType.audio,
      );

      fileItem.audioTracks.add(track);

      expect(fileItem.audioTracks.length, equals(1));
      expect(fileItem.audioTracks.first.language, equals('en'));
    });

    test('FileItem can select audio tracks', () {
      fileItem.audioTracks.add(Track(
        position: 0,
        language: 'en',
        description: 'English',
        type: TrackType.audio,
      ));
      fileItem.audioTracks.add(Track(
        position: 1,
        language: 'ja',
        description: 'Japanese',
        type: TrackType.audio,
      ));

      fileItem.selectedAudio.add(0);
      fileItem.selectedAudio.add(1);

      expect(fileItem.selectedAudio.length, equals(2));
      expect(fileItem.selectedAudio.contains(0), isTrue);
      expect(fileItem.selectedAudio.contains(1), isTrue);
    });

    test('FileItem can add and select subtitles', () {
      fileItem.subtitleTracks.add(Track(
        position: 0,
        language: 'en',
        description: 'English Subtitles',
        type: TrackType.subtitle,
      ));

      fileItem.selectedSubtitles.add(0);
      fileItem.defaultSubtitle = 0;

      expect(fileItem.selectedSubtitles.length, equals(1));
      expect(fileItem.defaultSubtitle, equals(0));
    });

    test('FileItem export status can be updated', () {
      fileItem.exportStatus = 'processing';
      expect(fileItem.exportStatus, equals('processing'));

      fileItem.exportProgress = 0.5;
      expect(fileItem.exportProgress, equals(0.5));

      fileItem.exportStatus = 'completed';
      fileItem.exportProgress = 1.0;
      expect(fileItem.exportStatus, equals('completed'));
      expect(fileItem.exportProgress, equals(1.0));
    });

    test('FileItem can have custom output name', () {
      fileItem.outputName = 'custom_output.mkv';
      expect(fileItem.outputName, equals('custom_output.mkv'));
    });
  });
}

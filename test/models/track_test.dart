import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/track.dart';

void main() {
  group('Track Model', () {
    test('Track creation with required fields', () {
      final track = Track(
        position: 0,
        language: 'en',
        description: 'English Audio',
        type: TrackType.audio,
      );

      expect(track.position, equals(0));
      expect(track.language, equals('en'));
      expect(track.description, equals('English Audio'));
      expect(track.type, equals(TrackType.audio));
      expect(track.streamIndex, equals(0));
    });

    test('Track with optional fields', () {
      final track = Track(
        position: 1,
        language: 'ja',
        title: 'Japanese',
        description: 'Japanese Audio',
        streamIndex: 1,
        type: TrackType.audio,
        codec: 'aac',
      );

      expect(track.position, equals(1));
      expect(track.language, equals('ja'));
      expect(track.title, equals('Japanese'));
      expect(track.codec, equals('aac'));
    });

    test('Video track creation', () {
      final track = Track(
        position: 0,
        language: 'und',
        description: 'Video Track',
        type: TrackType.video,
        width: 1920,
        height: 1080,
        frameRate: '23.976',
      );

      expect(track.type, equals(TrackType.video));
      expect(track.width, equals(1920));
      expect(track.height, equals(1080));
      expect(track.frameRate, equals('23.976'));
    });

    test('Subtitle track creation', () {
      final track = Track(
        position: 0,
        language: 'en',
        description: 'English Subtitles',
        type: TrackType.subtitle,
        codec: 'subrip',
      );

      expect(track.type, equals(TrackType.subtitle));
      expect(track.codec, equals('subrip'));
    });

    test('Track streamIndex defaults to position', () {
      final track = Track(
        position: 5,
        language: 'en',
        description: 'Test',
      );

      expect(track.streamIndex, equals(5));
    });
  });
}

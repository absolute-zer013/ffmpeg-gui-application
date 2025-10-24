import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/sync_offset.dart';

void main() {
  group('SyncOffset', () {
    test('creates sync offset with required values', () {
      const offset = SyncOffset(
        streamIndex: 1,
        offsetMs: 500,
        streamType: 'audio',
      );

      expect(offset.streamIndex, 1);
      expect(offset.offsetMs, 500);
      expect(offset.streamType, 'audio');
      expect(offset.trackDescription, null);
    });

    test('creates sync offset with track description', () {
      const offset = SyncOffset(
        streamIndex: 2,
        offsetMs: -200,
        streamType: 'subtitle',
        trackDescription: 'English Subtitles',
      );

      expect(offset.trackDescription, 'English Subtitles');
    });

    test('converts milliseconds to seconds correctly', () {
      const offset1 = SyncOffset(
        streamIndex: 1,
        offsetMs: 1000,
        streamType: 'audio',
      );
      expect(offset1.offsetSeconds, 1.0);

      const offset2 = SyncOffset(
        streamIndex: 1,
        offsetMs: 500,
        streamType: 'audio',
      );
      expect(offset2.offsetSeconds, 0.5);

      const offset3 = SyncOffset(
        streamIndex: 1,
        offsetMs: -1500,
        streamType: 'audio',
      );
      expect(offset3.offsetSeconds, -1.5);
    });

    test('formats positive offset correctly', () {
      const offset1 = SyncOffset(
        streamIndex: 1,
        offsetMs: 500,
        streamType: 'audio',
      );
      expect(offset1.formattedOffset, '+500ms');

      const offset2 = SyncOffset(
        streamIndex: 1,
        offsetMs: 1500,
        streamType: 'audio',
      );
      expect(offset2.formattedOffset, '+1s 500ms');

      const offset3 = SyncOffset(
        streamIndex: 1,
        offsetMs: 5000,
        streamType: 'audio',
      );
      expect(offset3.formattedOffset, '+5s 0ms');
    });

    test('formats negative offset correctly', () {
      const offset1 = SyncOffset(
        streamIndex: 1,
        offsetMs: -500,
        streamType: 'audio',
      );
      expect(offset1.formattedOffset, '-500ms');

      const offset2 = SyncOffset(
        streamIndex: 1,
        offsetMs: -1500,
        streamType: 'audio',
      );
      expect(offset2.formattedOffset, '-1s 500ms');
    });

    test('formats zero offset correctly', () {
      const offset = SyncOffset(
        streamIndex: 1,
        offsetMs: 0,
        streamType: 'audio',
      );
      expect(offset.formattedOffset, '+0ms');
    });

    test('copyWith creates new instance with updated values', () {
      const original = SyncOffset(
        streamIndex: 1,
        offsetMs: 500,
        streamType: 'audio',
        trackDescription: 'Track 1',
      );

      final updated = original.copyWith(offsetMs: 1000);

      expect(updated.streamIndex, 1);
      expect(updated.offsetMs, 1000);
      expect(updated.streamType, 'audio');
      expect(updated.trackDescription, 'Track 1');
    });

    test('toJson and fromJson work correctly', () {
      const original = SyncOffset(
        streamIndex: 2,
        offsetMs: -500,
        streamType: 'subtitle',
        trackDescription: 'English',
      );

      final json = original.toJson();
      final restored = SyncOffset.fromJson(json);

      expect(restored.streamIndex, original.streamIndex);
      expect(restored.offsetMs, original.offsetMs);
      expect(restored.streamType, original.streamType);
      expect(restored.trackDescription, original.trackDescription);
    });

    test('toString provides useful description', () {
      const offset1 = SyncOffset(
        streamIndex: 1,
        offsetMs: 500,
        streamType: 'audio',
      );
      expect(offset1.toString(), 'Stream 1: +500ms');

      const offset2 = SyncOffset(
        streamIndex: 2,
        offsetMs: -1500,
        streamType: 'subtitle',
        trackDescription: 'English Subtitles',
      );
      expect(offset2.toString(), 'English Subtitles: -1s 500ms');
    });

    test('equality works correctly', () {
      const offset1 = SyncOffset(
        streamIndex: 1,
        offsetMs: 500,
        streamType: 'audio',
      );

      const offset2 = SyncOffset(
        streamIndex: 1,
        offsetMs: 500,
        streamType: 'audio',
      );

      const offset3 = SyncOffset(
        streamIndex: 1,
        offsetMs: 1000, // Different offset
        streamType: 'audio',
      );

      const offset4 = SyncOffset(
        streamIndex: 2, // Different stream
        offsetMs: 500,
        streamType: 'audio',
      );

      expect(offset1, equals(offset2));
      expect(offset1, equals(offset3)); // Equality only checks streamIndex and streamType
      expect(offset1, isNot(equals(offset4)));
    });

    test('hashCode is consistent with equality', () {
      const offset1 = SyncOffset(
        streamIndex: 1,
        offsetMs: 500,
        streamType: 'audio',
      );

      const offset2 = SyncOffset(
        streamIndex: 1,
        offsetMs: 500,
        streamType: 'audio',
      );

      expect(offset1.hashCode, equals(offset2.hashCode));
    });
  });
}

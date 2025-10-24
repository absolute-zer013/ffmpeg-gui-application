import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/codec_options.dart';

void main() {
  group('SubtitleFormat', () {
    test('Has correct enum values', () {
      expect(SubtitleFormat.values.length, greaterThanOrEqualTo(5));
      expect(SubtitleFormat.copy.displayName, 'Copy');
      expect(SubtitleFormat.srt.displayName, 'SRT');
      expect(SubtitleFormat.ass.displayName, 'ASS');
    });

    test('Has correct FFmpeg codec names', () {
      expect(SubtitleFormat.copy.ffmpegName, 'copy');
      expect(SubtitleFormat.srt.ffmpegName, 'srt');
      expect(SubtitleFormat.ass.ffmpegName, 'ass');
      expect(SubtitleFormat.ssa.ffmpegName, 'ssa');
      expect(SubtitleFormat.webvtt.ffmpegName, 'webvtt');
      expect(SubtitleFormat.mov_text.ffmpegName, 'mov_text');
    });

    test('Each format has a description', () {
      for (final format in SubtitleFormat.values) {
        expect(format.description.isNotEmpty, true);
      }
    });
  });

  group('CodecConversionSettings with SubtitleFormat', () {
    test('Can set subtitle format', () {
      final settings = CodecConversionSettings(
        subtitleFormat: SubtitleFormat.srt,
      );

      expect(settings.subtitleFormat, SubtitleFormat.srt);
    });

    test('copyWith updates subtitle format', () {
      final settings = CodecConversionSettings(
        subtitleFormat: SubtitleFormat.copy,
      );

      final updated = settings.copyWith(
        subtitleFormat: SubtitleFormat.ass,
      );

      expect(updated.subtitleFormat, SubtitleFormat.ass);
      expect(settings.subtitleFormat, SubtitleFormat.copy);
    });

    test('toJson includes subtitle format', () {
      final settings = CodecConversionSettings(
        subtitleFormat: SubtitleFormat.srt,
        audioCodec: AudioCodec.aac,
      );

      final json = settings.toJson();

      expect(json['subtitleFormat'], 'srt');
      expect(json['audioCodec'], 'aac');
    });

    test('fromJson restores subtitle format', () {
      final json = {
        'subtitleFormat': 'ass',
        'audioCodec': 'mp3',
      };

      final settings = CodecConversionSettings.fromJson(json);

      expect(settings.subtitleFormat, SubtitleFormat.ass);
      expect(settings.audioCodec, AudioCodec.mp3);
    });

    test('fromJson handles null subtitle format', () {
      final json = <String, dynamic>{};

      final settings = CodecConversionSettings.fromJson(json);

      expect(settings.subtitleFormat, null);
    });

    test('Serialization round-trip preserves data', () {
      final original = CodecConversionSettings(
        videoCodec: VideoCodec.h264,
        audioCodec: AudioCodec.aac,
        subtitleFormat: SubtitleFormat.srt,
        audioBitrate: 192,
      );

      final json = original.toJson();
      final restored = CodecConversionSettings.fromJson(json);

      expect(restored.videoCodec, original.videoCodec);
      expect(restored.audioCodec, original.audioCodec);
      expect(restored.subtitleFormat, original.subtitleFormat);
      expect(restored.audioBitrate, original.audioBitrate);
    });
  });
}

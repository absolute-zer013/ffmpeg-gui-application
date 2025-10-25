import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/services/disk_space_service.dart';
import 'package:ffmpeg_filter_app/models/file_item.dart';
import 'package:ffmpeg_filter_app/models/codec_options.dart';
import 'package:ffmpeg_filter_app/models/quality_preset.dart';

void main() {
  group('DiskSpaceService', () {
    test('estimateRequiredSpace for copy/remux adds 10% buffer', () {
      final files = [
        FileItem(
          path: '/test/video1.mkv',
          audioTracks: [],
          subtitleTracks: [],
        )..size = 1000 * 1024 * 1024, // 1000 MB
      ];

      final estimate = DiskSpaceService.estimateRequiredSpace(files);

      // Should be ~1100 MB (1.1x) + 500MB safety margin
      expect(estimate, greaterThan(1100 * 1024 * 1024));
      expect(estimate, lessThan(2000 * 1024 * 1024));
    });

    test('estimateRequiredSpace for high quality re-encode adds 20% buffer', () {
      final files = [
        FileItem(
          path: '/test/video1.mkv',
          audioTracks: [],
          subtitleTracks: [],
        )
          ..size = 1000 * 1024 * 1024 // 1000 MB
          ..qualityPreset = QualityPreset.highQuality()
          ..codecSettings = {
            0: CodecConversionSettings(videoCodec: VideoCodec.h264),
          },
      ];

      final estimate = DiskSpaceService.estimateRequiredSpace(files);

      // High quality (CRF 18) should use 1.2x multiplier, doubled for temp file
      // (1000 * 1.2 * 2) + 500MB = 2900 MB
      expect(estimate, greaterThan(2500 * 1024 * 1024));
      expect(estimate, lessThan(3500 * 1024 * 1024));
    });

    test('estimateRequiredSpace for fast/low quality re-encode uses 50% multiplier', () {
      final files = [
        FileItem(
          path: '/test/video1.mkv',
          audioTracks: [],
          subtitleTracks: [],
        )
          ..size = 1000 * 1024 * 1024 // 1000 MB
          ..qualityPreset = QualityPreset.fast()
          ..codecSettings = {
            0: CodecConversionSettings(videoCodec: VideoCodec.h264),
          },
      ];

      final estimate = DiskSpaceService.estimateRequiredSpace(files);

      // Fast (CRF 28) should use 0.5x multiplier, doubled for temp file
      // (1000 * 0.5 * 2) + 500MB = 1500 MB
      expect(estimate, greaterThan(1000 * 1024 * 1024));
      expect(estimate, lessThan(2000 * 1024 * 1024));
    });

    test('estimateRequiredSpace for multiple files sums correctly', () {
      final files = [
        FileItem(
          path: '/test/video1.mkv',
          audioTracks: [],
          subtitleTracks: [],
        )..size = 500 * 1024 * 1024, // 500 MB
        FileItem(
          path: '/test/video2.mkv',
          audioTracks: [],
          subtitleTracks: [],
        )..size = 500 * 1024 * 1024, // 500 MB
      ];

      final estimate = DiskSpaceService.estimateRequiredSpace(files);

      // (500 * 1.1 + 500 * 1.1) + 500MB = 1600 MB
      expect(estimate, greaterThan(1100 * 1024 * 1024));
      expect(estimate, lessThan(2200 * 1024 * 1024));
    });

    test('DiskSpaceCheckResult formats bytes correctly', () {
      final result = DiskSpaceCheckResult(
        hasSufficientSpace: true,
        requiredBytes: 1024 * 1024 * 1024, // 1 GB
        availableBytes: 5 * 1024 * 1024 * 1024, // 5 GB
        targetPath: '/test',
        message: 'Test message',
      );

      expect(result.formattedRequired, contains('1.00 GB'));
      expect(result.formattedAvailable, contains('5.00 GB'));
    });

    test('DiskSpaceCheckResult formats KB correctly', () {
      final result = DiskSpaceCheckResult(
        hasSufficientSpace: true,
        requiredBytes: 1024 * 100, // 100 KB
        availableBytes: 1024 * 1024, // 1 MB
        targetPath: '/test',
        message: 'Test message',
      );

      expect(result.formattedRequired, contains('100.00 KB'));
      expect(result.formattedAvailable, contains('1.00 MB'));
    });

    test('estimateRequiredSpace handles audio-only re-encoding', () {
      final files = [
        FileItem(
          path: '/test/video1.mkv',
          audioTracks: [],
          subtitleTracks: [],
        )
          ..size = 1000 * 1024 * 1024 // 1000 MB
          ..codecSettings = {
            0: CodecConversionSettings(audioCodec: AudioCodec.aac),
          },
      ];

      final estimate = DiskSpaceService.estimateRequiredSpace(files);

      // Audio-only re-encoding uses 1.05x multiplier, doubled for temp
      // (1000 * 1.05 * 2) + 500MB = 2600 MB
      expect(estimate, greaterThan(2000 * 1024 * 1024));
      expect(estimate, lessThan(3000 * 1024 * 1024));
    });

    test('estimateRequiredSpace accounts for two-stage pipeline needing temp space', () {
      final files = [
        FileItem(
          path: '/test/video1.mkv',
          audioTracks: [],
          subtitleTracks: [],
        )
          ..size = 1000 * 1024 * 1024 // 1000 MB
          ..codecSettings = {
            0: CodecConversionSettings(videoCodec: VideoCodec.h264),
          },
      ];

      final estimate = DiskSpaceService.estimateRequiredSpace(files);

      // With re-encoding, needs space for both temp and final (2x)
      // Base estimate should be at least 2x file size
      expect(estimate, greaterThan(2000 * 1024 * 1024));
    });
  });
}

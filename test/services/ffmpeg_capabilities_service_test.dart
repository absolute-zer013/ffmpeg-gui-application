import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/services/ffmpeg_capabilities_service.dart';

void main() {
  group('FFmpegCapabilitiesService', () {
    test('HardwareCapabilities detects no hardware acceleration', () {
      final capabilities = HardwareCapabilities(
        hasNVENC: false,
        hasAMF: false,
        hasQSV: false,
        availableHardwareEncoders: [],
        detectedAt: DateTime.now(),
      );

      expect(capabilities.hasAnyHardwareAcceleration, isFalse);
      expect(capabilities.toString(), contains('No hardware'));
    });

    test('HardwareCapabilities detects NVENC', () {
      final capabilities = HardwareCapabilities(
        hasNVENC: true,
        hasAMF: false,
        hasQSV: false,
        availableHardwareEncoders: ['h264_nvenc', 'hevc_nvenc'],
        detectedAt: DateTime.now(),
      );

      expect(capabilities.hasAnyHardwareAcceleration, isTrue);
      expect(capabilities.hasNVENC, isTrue);
      expect(capabilities.toString(), contains('NVENC'));
    });

    test('HardwareCapabilities detects multiple hardware types', () {
      final capabilities = HardwareCapabilities(
        hasNVENC: true,
        hasAMF: true,
        hasQSV: false,
        availableHardwareEncoders: ['h264_nvenc', 'h264_amf'],
        detectedAt: DateTime.now(),
      );

      expect(capabilities.hasAnyHardwareAcceleration, isTrue);
      expect(capabilities.hasNVENC, isTrue);
      expect(capabilities.hasAMF, isTrue);
      expect(capabilities.toString(), contains('NVENC'));
      expect(capabilities.toString(), contains('AMF'));
    });

    test('selectHardwareEncoder prefers NVENC for H.264', () {
      final capabilities = HardwareCapabilities(
        hasNVENC: true,
        hasAMF: true,
        hasQSV: true,
        availableHardwareEncoders: ['h264_nvenc', 'h264_amf', 'h264_qsv'],
        detectedAt: DateTime.now(),
      );

      final encoder = FFmpegCapabilitiesService.selectHardwareEncoder(
        'libx264',
        capabilities,
      );

      expect(encoder, equals('h264_nvenc'));
    });

    test('selectHardwareEncoder falls back to AMF when NVENC unavailable', () {
      final capabilities = HardwareCapabilities(
        hasNVENC: false,
        hasAMF: true,
        hasQSV: true,
        availableHardwareEncoders: ['h264_amf', 'h264_qsv'],
        detectedAt: DateTime.now(),
      );

      final encoder = FFmpegCapabilitiesService.selectHardwareEncoder(
        'libx264',
        capabilities,
      );

      expect(encoder, equals('h264_amf'));
    });

    test('selectHardwareEncoder falls back to QSV when NVENC and AMF unavailable', () {
      final capabilities = HardwareCapabilities(
        hasNVENC: false,
        hasAMF: false,
        hasQSV: true,
        availableHardwareEncoders: ['h264_qsv'],
        detectedAt: DateTime.now(),
      );

      final encoder = FFmpegCapabilitiesService.selectHardwareEncoder(
        'libx264',
        capabilities,
      );

      expect(encoder, equals('h264_qsv'));
    });

    test('selectHardwareEncoder returns null when no hardware available', () {
      final capabilities = HardwareCapabilities(
        hasNVENC: false,
        hasAMF: false,
        hasQSV: false,
        availableHardwareEncoders: [],
        detectedAt: DateTime.now(),
      );

      final encoder = FFmpegCapabilitiesService.selectHardwareEncoder(
        'libx264',
        capabilities,
      );

      expect(encoder, isNull);
    });

    test('selectHardwareEncoder works for H.265', () {
      final capabilities = HardwareCapabilities(
        hasNVENC: true,
        hasAMF: false,
        hasQSV: false,
        availableHardwareEncoders: ['hevc_nvenc'],
        detectedAt: DateTime.now(),
      );

      final encoder = FFmpegCapabilitiesService.selectHardwareEncoder(
        'libx265',
        capabilities,
      );

      expect(encoder, equals('hevc_nvenc'));
    });

    test('selectHardwareEncoder returns null for unsupported codec', () {
      final capabilities = HardwareCapabilities(
        hasNVENC: true,
        hasAMF: false,
        hasQSV: false,
        availableHardwareEncoders: ['h264_nvenc'],
        detectedAt: DateTime.now(),
      );

      final encoder = FFmpegCapabilitiesService.selectHardwareEncoder(
        'libvpx-vp9',
        capabilities,
      );

      expect(encoder, isNull);
    });

    test('isEncoderCompatibleWithContainer accepts H.264 in MP4', () {
      expect(
        FFmpegCapabilitiesService.isEncoderCompatibleWithContainer(
          'h264_nvenc',
          'mp4',
        ),
        isTrue,
      );
    });

    test('isEncoderCompatibleWithContainer accepts H.265 in MP4', () {
      expect(
        FFmpegCapabilitiesService.isEncoderCompatibleWithContainer(
          'hevc_nvenc',
          'mp4',
        ),
        isTrue,
      );
    });

    test('isEncoderCompatibleWithContainer accepts everything in MKV', () {
      expect(
        FFmpegCapabilitiesService.isEncoderCompatibleWithContainer(
          'h264_nvenc',
          'mkv',
        ),
        isTrue,
      );
      expect(
        FFmpegCapabilitiesService.isEncoderCompatibleWithContainer(
          'hevc_qsv',
          'mkv',
        ),
        isTrue,
      );
    });

    test('isEncoderCompatibleWithContainer accepts VP9/AV1 in WebM', () {
      expect(
        FFmpegCapabilitiesService.isEncoderCompatibleWithContainer(
          'vp9_vaapi',
          'webm',
        ),
        isTrue,
      );
      expect(
        FFmpegCapabilitiesService.isEncoderCompatibleWithContainer(
          'av1_qsv',
          'webm',
        ),
        isTrue,
      );
    });
  });
}

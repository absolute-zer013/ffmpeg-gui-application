import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/utils/file_utils.dart';

void main() {
  group('FileUtils', () {
    group('isSupportedVideoFormat', () {
      test('returns true for supported formats', () {
        expect(FileUtils.isSupportedVideoFormat('video.mkv'), isTrue);
        expect(FileUtils.isSupportedVideoFormat('video.mp4'), isTrue);
        expect(FileUtils.isSupportedVideoFormat('video.avi'), isTrue);
        expect(FileUtils.isSupportedVideoFormat('video.mov'), isTrue);
      });

      test('returns false for unsupported formats', () {
        expect(FileUtils.isSupportedVideoFormat('image.jpg'), isFalse);
        expect(FileUtils.isSupportedVideoFormat('audio.mp3'), isFalse);
        expect(FileUtils.isSupportedVideoFormat('document.pdf'), isFalse);
        expect(FileUtils.isSupportedVideoFormat('archive.zip'), isFalse);
      });

      test('is case-insensitive', () {
        expect(FileUtils.isSupportedVideoFormat('VIDEO.MKV'), isTrue);
        expect(FileUtils.isSupportedVideoFormat('Video.Mp4'), isTrue);
      });

      test('handles paths correctly', () {
        expect(FileUtils.isSupportedVideoFormat('/path/to/video.mkv'), isTrue);
        expect(
            FileUtils.isSupportedVideoFormat('C:\\Videos\\movie.mp4'), isTrue);
      });
    });

    group('formatBytes', () {
      test('formats bytes correctly', () {
        expect(FileUtils.formatBytes(0), equals('0 B'));
        expect(FileUtils.formatBytes(500), equals('500 B'));
        expect(FileUtils.formatBytes(1024), equals('1.0 KB'));
        expect(FileUtils.formatBytes(1536), equals('1.5 KB'));
        expect(FileUtils.formatBytes(1048576), equals('1.0 MB'));
        expect(FileUtils.formatBytes(1572864), equals('1.5 MB'));
        // GB format uses 2 decimal places
        expect(FileUtils.formatBytes(1073741824), equals('1.00 GB'));
        expect(FileUtils.formatBytes(1610612736), equals('1.50 GB'));
      });

      test('formats large files', () {
        expect(FileUtils.formatBytes(5368709120), equals('5.00 GB'));
        expect(FileUtils.formatBytes(1099511627776), equals('1024.00 GB'));
      });

      test('handles edge cases', () {
        expect(FileUtils.formatBytes(1023), equals('1023 B'));
        expect(FileUtils.formatBytes(1024 * 1024 * 1024), equals('1.00 GB'));
      });
    });
  });
}

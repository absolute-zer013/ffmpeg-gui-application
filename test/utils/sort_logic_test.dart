import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/file_item.dart';

void main() {
  group('Sort Logic', () {
    late List<FileItem> testFiles;

    setUp(() {
      testFiles = [
        FileItem(
          path: '/path/to/b_file.mkv',
          name: 'B File.mkv',
          audioTracks: [],
          subtitleTracks: [],
          exportStatus: 'completed',
          fileSize: 200000000, // 200 MB
          duration: '1:30:00',
        ),
        FileItem(
          path: '/path/to/a_file.mkv',
          name: 'A File.mkv',
          audioTracks: [],
          subtitleTracks: [],
          exportStatus: 'failed',
          fileSize: 100000000, // 100 MB
          duration: '0:45:00',
        ),
        FileItem(
          path: '/path/to/c_file.mkv',
          name: 'C File.mkv',
          audioTracks: [],
          subtitleTracks: [],
          exportStatus: '', // pending
          fileSize: 300000000, // 300 MB
          duration: '2:15:00',
        ),
      ];
    });

    test('Sort by name ascending', () {
      final sorted = List<FileItem>.from(testFiles);
      sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      expect(sorted[0].name, 'A File.mkv');
      expect(sorted[1].name, 'B File.mkv');
      expect(sorted[2].name, 'C File.mkv');
    });

    test('Sort by name descending', () {
      final sorted = List<FileItem>.from(testFiles);
      sorted.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));

      expect(sorted[0].name, 'C File.mkv');
      expect(sorted[1].name, 'B File.mkv');
      expect(sorted[2].name, 'A File.mkv');
    });

    test('Sort by size ascending', () {
      final sorted = List<FileItem>.from(testFiles);
      sorted.sort((a, b) {
        final sizeA = a.fileSize ?? 0;
        final sizeB = b.fileSize ?? 0;
        return sizeA.compareTo(sizeB);
      });

      expect(sorted[0].fileSize, 100000000);
      expect(sorted[1].fileSize, 200000000);
      expect(sorted[2].fileSize, 300000000);
    });

    test('Sort by size descending', () {
      final sorted = List<FileItem>.from(testFiles);
      sorted.sort((a, b) {
        final sizeA = a.fileSize ?? 0;
        final sizeB = b.fileSize ?? 0;
        return sizeB.compareTo(sizeA);
      });

      expect(sorted[0].fileSize, 300000000);
      expect(sorted[1].fileSize, 200000000);
      expect(sorted[2].fileSize, 100000000);
    });

    test('Sort by duration ascending', () {
      int parseDuration(String duration) {
        final parts = duration.split(':');
        if (parts.length == 3) {
          final hours = int.parse(parts[0]);
          final minutes = int.parse(parts[1]);
          final seconds = double.parse(parts[2]).round();
          return hours * 3600 + minutes * 60 + seconds;
        }
        return 0;
      }

      final sorted = List<FileItem>.from(testFiles);
      sorted.sort((a, b) {
        final durationA = parseDuration(a.duration ?? '0:00:00');
        final durationB = parseDuration(b.duration ?? '0:00:00');
        return durationA.compareTo(durationB);
      });

      expect(sorted[0].duration, '0:45:00');
      expect(sorted[1].duration, '1:30:00');
      expect(sorted[2].duration, '2:15:00');
    });

    test('Sort by status ascending', () {
      final sorted = List<FileItem>.from(testFiles);
      sorted.sort((a, b) {
        final statusA = a.exportStatus.isEmpty ? 'pending' : a.exportStatus;
        final statusB = b.exportStatus.isEmpty ? 'pending' : b.exportStatus;
        return statusA.compareTo(statusB);
      });

      expect(sorted[0].exportStatus, 'completed');
      expect(sorted[1].exportStatus, 'failed');
      expect(sorted[2].exportStatus, ''); // pending
    });

    test('Duration parsing handles various formats', () {
      int parseDuration(String duration) {
        try {
          final parts = duration.split(':');
          if (parts.length == 3) {
            final hours = int.parse(parts[0]);
            final minutes = int.parse(parts[1]);
            final seconds = double.parse(parts[2]).round();
            return hours * 3600 + minutes * 60 + seconds;
          }
        } catch (e) {
          // Return 0 if parsing fails
        }
        return 0;
      }

      expect(parseDuration('1:30:00'), 5400); // 1.5 hours
      expect(parseDuration('0:45:00'), 2700); // 45 minutes
      expect(parseDuration('2:15:30'), 8130); // 2 hours 15 min 30 sec
      expect(parseDuration('invalid'), 0);
      expect(parseDuration(''), 0);
    });

    test('Sort handles null values gracefully', () {
      final filesWithNulls = [
        FileItem(
          path: '/path/to/file1.mkv',
          audioTracks: [],
          subtitleTracks: [],
          fileSize: null,
          duration: null,
        ),
        FileItem(
          path: '/path/to/file2.mkv',
          audioTracks: [],
          subtitleTracks: [],
          fileSize: 100000,
          duration: '1:00:00',
        ),
      ];

      // Should not throw
      filesWithNulls.sort((a, b) {
        final sizeA = a.fileSize ?? 0;
        final sizeB = b.fileSize ?? 0;
        return sizeA.compareTo(sizeB);
      });

      expect(filesWithNulls[0].fileSize, null);
      expect(filesWithNulls[1].fileSize, 100000);
    });
  });
}

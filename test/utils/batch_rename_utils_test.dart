import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/utils/rename_utils.dart';

void main() {
  group('RenameUtils.applyPatternBatch', () {
    test('generates unique names with index padding', () {
      final originals = [
        'C:/vids/fileA.mkv',
        'C:/vids/fileB.mkv',
        'C:/vids/fileC.mkv',
      ];
      final results = RenameUtils.applyPatternBatch(
        pattern: '{name}-{index:2}',
        originalPaths: originals,
        startIndex: 1,
      );

      expect(results.length, 3);
      expect(results[0].proposedName, 'fileA-01.mkv');
      expect(results[1].proposedName, 'fileB-02.mkv');
      expect(results[2].proposedName, 'fileC-03.mkv');
    });

    test('resolves collisions with numeric suffix', () {
      final originals = [
        'C:/vids/ep1.mkv',
        'C:/vids/ep1.mkv', // same base name; pattern keeps {name}
      ];
      final results = RenameUtils.applyPatternBatch(
        pattern: '{name}',
        originalPaths: originals,
        conflictStrategy: RenameUtils.conflictSuffix,
      );

      expect(results[0].proposedName, 'ep1.mkv');
      expect(results[1].proposedName, 'ep1-1.mkv');
      expect(results[1].conflictResolved, isTrue);
    });

    test('can skip on conflict', () {
      final originals = [
        'C:/vids/dup.mkv',
        'C:/vids/dup.mkv',
      ];
      final results = RenameUtils.applyPatternBatch(
        pattern: '{name}',
        originalPaths: originals,
        conflictStrategy: RenameUtils.conflictSkip,
      );

      expect(results[0].skipped, isFalse);
      expect(results[1].skipped, isTrue);
      expect(results[1].reason, contains('Skipped'));
    });
  });
}

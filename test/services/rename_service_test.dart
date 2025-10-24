import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/services/rename_service.dart';
import 'package:ffmpeg_filter_app/utils/rename_utils.dart';

void main() {
  group('RenameService', () {
    test('planBatchRenames returns mapping and conflict counts', () {
      final paths = [
        'C:/v/ep1.mkv',
        'C:/v/ep1.mkv', // duplicate basename; pattern keeps {name}
        'C:/v/ep2.mkv',
      ];

      final plan = RenameService.planBatchRenames(
        pattern: '{name}',
        paths: paths,
      );

      expect(plan.results.length, 3);
      expect(plan.renameMapping.containsKey('C:/v/ep1.mkv'), isTrue);
      // One of the duplicates will be resolved with suffix
      expect(plan.resolvedConflicts, greaterThanOrEqualTo(1));
      expect(plan.skippedItems, 0);
    });

    test('applyFindReplace replaces text in proposed names', () {
      final paths = ['C:/v/MyVideo.mkv', 'C:/v/MyMovie.mkv'];
      
      final plan = RenameService.planBatchRenames(
        pattern: '{name}',
        paths: paths,
      );

      final updated = RenameService.applyFindReplace(
        plan,
        findText: 'My',
        replaceText: 'Our',
      );

      expect(updated.results[0].proposedName, contains('OurVideo'));
      expect(updated.results[1].proposedName, contains('OurMovie'));
    });

    test('applyFindReplace with regex works correctly', () {
      final paths = ['C:/v/Video123.mkv', 'C:/v/Video456.mkv'];
      
      final plan = RenameService.planBatchRenames(
        pattern: '{name}',
        paths: paths,
      );

      final updated = RenameService.applyFindReplace(
        plan,
        findText: r'\d+',
        replaceText: 'XXX',
        useRegex: true,
      );

      expect(updated.results[0].proposedName, contains('VideoXXX'));
      expect(updated.results[1].proposedName, contains('VideoXXX'));
    });

    test('applyFindReplace case insensitive works', () {
      final paths = ['C:/v/MyVideo.mkv'];
      
      final plan = RenameService.planBatchRenames(
        pattern: '{name}',
        paths: paths,
      );

      final updated = RenameService.applyFindReplace(
        plan,
        findText: 'my',
        replaceText: 'Your',
        caseSensitive: false,
      );

      expect(updated.results[0].proposedName, contains('YourVideo'));
    });

    test('exportToCsv generates valid CSV', () {
      final paths = ['C:/v/file1.mkv', 'C:/v/file2.mkv'];
      
      final plan = RenameService.planBatchRenames(
        pattern: '{name}',
        paths: paths,
      );

      final csv = RenameService.exportToCsv(plan);

      expect(csv, contains('Original Name,Proposed Name,Status'));
      expect(csv, contains('file1.mkv'));
      expect(csv, contains('file2.mkv'));
    });

    test('exportToMarkdown generates valid Markdown', () {
      final paths = ['C:/v/file1.mkv', 'C:/v/file2.mkv'];
      
      final plan = RenameService.planBatchRenames(
        pattern: '{name}',
        paths: paths,
      );

      final markdown = RenameService.exportToMarkdown(plan);

      expect(markdown, contains('# Batch Rename Preview'));
      expect(markdown, contains('## Summary'));
      expect(markdown, contains('Total files:'));
      expect(markdown, contains('| Original Name | Proposed Name | Status |'));
      expect(markdown, contains('file1.mkv'));
      expect(markdown, contains('file2.mkv'));
    });

    test('applyTransformation trimSpaces removes leading/trailing spaces', () {
      // Create a mock result with spaces
      final results = [
        BatchRenameResult(
          originalPath: 'C:/v/file.mkv',
          proposedName: '  spaced.mkv  ',
          conflictResolved: false,
          skipped: false,
        ),
      ];

      final plan = BatchRenamePlan(
        results: results,
        renameMapping: {},
        resolvedConflicts: 0,
        skippedItems: 0,
      );

      final updated = RenameService.applyTransformation(
        plan,
        RenameTransformation.trimSpaces,
      );

      expect(updated.results[0].proposedName, equals('spaced.mkv'));
    });

    test('applyTransformation normalizeSpaces removes extra spaces', () {
      final results = [
        BatchRenameResult(
          originalPath: 'C:/v/file.mkv',
          proposedName: 'my   video   file.mkv',
          conflictResolved: false,
          skipped: false,
        ),
      ];

      final plan = BatchRenamePlan(
        results: results,
        renameMapping: {},
        resolvedConflicts: 0,
        skippedItems: 0,
      );

      final updated = RenameService.applyTransformation(
        plan,
        RenameTransformation.normalizeSpaces,
      );

      expect(updated.results[0].proposedName, equals('my video file.mkv'));
    });

    test('applyTransformation dashesToUnderscores converts dashes', () {
      final results = [
        BatchRenameResult(
          originalPath: 'C:/v/file.mkv',
          proposedName: 'my-video-file.mkv',
          conflictResolved: false,
          skipped: false,
        ),
      ];

      final plan = BatchRenamePlan(
        results: results,
        renameMapping: {},
        resolvedConflicts: 0,
        skippedItems: 0,
      );

      final updated = RenameService.applyTransformation(
        plan,
        RenameTransformation.dashesToUnderscores,
      );

      expect(updated.results[0].proposedName, equals('my_video_file.mkv'));
    });

    test('applyTransformation uppercase converts to uppercase', () {
      final results = [
        BatchRenameResult(
          originalPath: 'C:/v/file.mkv',
          proposedName: 'myfile.mkv',
          conflictResolved: false,
          skipped: false,
        ),
      ];

      final plan = BatchRenamePlan(
        results: results,
        renameMapping: {},
        resolvedConflicts: 0,
        skippedItems: 0,
      );

      final updated = RenameService.applyTransformation(
        plan,
        RenameTransformation.uppercase,
      );

      expect(updated.results[0].proposedName, equals('MYFILE.MKV'));
    });

    test('applyTransformation titleCase converts to title case', () {
      final results = [
        BatchRenameResult(
          originalPath: 'C:/v/file.mkv',
          proposedName: 'my video file.mkv',
          conflictResolved: false,
          skipped: false,
        ),
      ];

      final plan = BatchRenamePlan(
        results: results,
        renameMapping: {},
        resolvedConflicts: 0,
        skippedItems: 0,
      );

      final updated = RenameService.applyTransformation(
        plan,
        RenameTransformation.titleCase,
      );

      expect(updated.results[0].proposedName, equals('My Video File.mkv'));
    });
  });
}

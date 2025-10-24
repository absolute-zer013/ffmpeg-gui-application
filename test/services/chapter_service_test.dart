import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/chapter.dart';
import 'package:ffmpeg_filter_app/services/chapter_service.dart';

void main() {
  group('Chapter', () {
    test('creates chapter with required fields', () {
      final chapter = Chapter(
        id: 0,
        startTime: 0.0,
        endTime: 60.0,
        title: 'Chapter 1',
      );

      expect(chapter.id, equals(0));
      expect(chapter.startTime, equals(0.0));
      expect(chapter.endTime, equals(60.0));
      expect(chapter.title, equals('Chapter 1'));
    });

    test('copyWith creates modified copy', () {
      final chapter = Chapter(
        id: 0,
        startTime: 0.0,
        endTime: 60.0,
        title: 'Chapter 1',
      );

      final modified = chapter.copyWith(title: 'Modified');

      expect(modified.id, equals(0));
      expect(modified.title, equals('Modified'));
      expect(modified.startTime, equals(0.0));
    });

    test('toJson and fromJson round trip', () {
      final chapter = Chapter(
        id: 1,
        startTime: 120.5,
        endTime: 180.75,
        title: 'Test Chapter',
      );

      final json = chapter.toJson();
      final reconstructed = Chapter.fromJson(json);

      expect(reconstructed, equals(chapter));
    });

    test('formatTime formats seconds correctly', () {
      expect(Chapter.formatTime(0), equals('00:00:00'));
      expect(Chapter.formatTime(61), equals('00:01:01'));
      expect(Chapter.formatTime(3661), equals('01:01:01'));
      expect(Chapter.formatTime(7384), equals('02:03:04'));
    });

    test('parseTime parses time string correctly', () {
      expect(Chapter.parseTime('00:00:00'), equals(0.0));
      expect(Chapter.parseTime('00:01:01'), equals(61.0));
      expect(Chapter.parseTime('01:01:01'), equals(3661.0));
      expect(Chapter.parseTime('02:03:04'), equals(7384.0));
    });

    test('parseTime throws on invalid format', () {
      expect(
        () => Chapter.parseTime('invalid'),
        throwsFormatException,
      );
    });

    test('formattedStartTime returns formatted string', () {
      final chapter = Chapter(
        id: 0,
        startTime: 125.0,
        endTime: 250.0,
        title: 'Test',
      );

      expect(chapter.formattedStartTime, equals('00:02:05'));
    });

    test('formattedEndTime returns formatted string', () {
      final chapter = Chapter(
        id: 0,
        startTime: 125.0,
        endTime: 250.0,
        title: 'Test',
      );

      expect(chapter.formattedEndTime, equals('00:04:10'));
    });

    test('equality works correctly', () {
      final chapter1 = Chapter(
        id: 0,
        startTime: 0.0,
        endTime: 60.0,
        title: 'Chapter 1',
      );

      final chapter2 = Chapter(
        id: 0,
        startTime: 0.0,
        endTime: 60.0,
        title: 'Chapter 1',
      );

      final chapter3 = Chapter(
        id: 1,
        startTime: 0.0,
        endTime: 60.0,
        title: 'Chapter 1',
      );

      expect(chapter1, equals(chapter2));
      expect(chapter1, isNot(equals(chapter3)));
    });
  });

  group('ChapterService', () {
    test('generateMetadataFile creates valid metadata', () {
      final chapters = [
        Chapter(id: 0, startTime: 0.0, endTime: 60.0, title: 'Chapter 1'),
        Chapter(id: 1, startTime: 60.0, endTime: 120.0, title: 'Chapter 2'),
      ];

      final metadata = ChapterService.generateMetadataFile(chapters);

      expect(metadata, contains(';FFMETADATA1'));
      expect(metadata, contains('[CHAPTER]'));
      expect(metadata, contains('START=0'));
      expect(metadata, contains('END=60000'));
      expect(metadata, contains('title=Chapter 1'));
      expect(metadata, contains('START=60000'));
      expect(metadata, contains('END=120000'));
      expect(metadata, contains('title=Chapter 2'));
    });

    test('validateChapters accepts valid chapters', () {
      final chapters = [
        Chapter(id: 0, startTime: 0.0, endTime: 60.0, title: 'Chapter 1'),
        Chapter(id: 1, startTime: 60.0, endTime: 120.0, title: 'Chapter 2'),
      ];

      expect(ChapterService.validateChapters(chapters), isTrue);
    });

    test('validateChapters rejects overlapping chapters', () {
      final chapters = [
        Chapter(id: 0, startTime: 0.0, endTime: 70.0, title: 'Chapter 1'),
        Chapter(id: 1, startTime: 60.0, endTime: 120.0, title: 'Chapter 2'),
      ];

      expect(ChapterService.validateChapters(chapters), isFalse);
    });

    test('validateChapters rejects invalid time range', () {
      final chapters = [
        Chapter(id: 0, startTime: 60.0, endTime: 30.0, title: 'Chapter 1'),
      ];

      expect(ChapterService.validateChapters(chapters), isFalse);
    });

    test('validateChapters rejects negative start time', () {
      final chapters = [
        Chapter(id: 0, startTime: -10.0, endTime: 30.0, title: 'Chapter 1'),
      ];

      expect(ChapterService.validateChapters(chapters), isFalse);
    });

    test('validateChapters accepts empty list', () {
      expect(ChapterService.validateChapters([]), isTrue);
    });

    test('sortChapters sorts by start time and reassigns IDs', () {
      final chapters = [
        Chapter(id: 0, startTime: 60.0, endTime: 120.0, title: 'Chapter 2'),
        Chapter(id: 1, startTime: 0.0, endTime: 60.0, title: 'Chapter 1'),
      ];

      final sorted = ChapterService.sortChapters(chapters);

      expect(sorted[0].id, equals(0));
      expect(sorted[0].startTime, equals(0.0));
      expect(sorted[1].id, equals(1));
      expect(sorted[1].startTime, equals(60.0));
    });

    test('removeChapter removes chapter and reassigns IDs', () {
      final chapters = [
        Chapter(id: 0, startTime: 0.0, endTime: 60.0, title: 'Chapter 1'),
        Chapter(id: 1, startTime: 60.0, endTime: 120.0, title: 'Chapter 2'),
        Chapter(id: 2, startTime: 120.0, endTime: 180.0, title: 'Chapter 3'),
      ];

      final updated = ChapterService.removeChapter(chapters, 1);

      expect(updated.length, equals(2));
      expect(updated[0].title, equals('Chapter 1'));
      expect(updated[1].title, equals('Chapter 3'));
      expect(updated[1].id, equals(1));
    });

    test('addChapter adds and sorts chapters', () {
      final chapters = [
        Chapter(id: 0, startTime: 0.0, endTime: 60.0, title: 'Chapter 1'),
        Chapter(id: 1, startTime: 120.0, endTime: 180.0, title: 'Chapter 3'),
      ];

      final newChapter = Chapter(
        id: -1,
        startTime: 60.0,
        endTime: 120.0,
        title: 'Chapter 2',
      );

      final updated = ChapterService.addChapter(chapters, newChapter);

      expect(updated.length, equals(3));
      expect(updated[1].title, equals('Chapter 2'));
      expect(updated[1].id, equals(1));
      expect(updated[2].id, equals(2));
    });

    test('updateChapter updates and resorts', () {
      final chapters = [
        Chapter(id: 0, startTime: 0.0, endTime: 60.0, title: 'Chapter 1'),
        Chapter(id: 1, startTime: 60.0, endTime: 120.0, title: 'Chapter 2'),
      ];

      final updated = chapters[0].copyWith(title: 'Updated Chapter 1');
      final result = ChapterService.updateChapter(chapters, updated);

      expect(result[0].title, equals('Updated Chapter 1'));
      expect(result.length, equals(2));
    });
  });
}

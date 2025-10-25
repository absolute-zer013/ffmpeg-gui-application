import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/chapter.dart';

void main() {
  group('Chapter Model', () {
    test('creates chapter with all fields', () {
      final chapter = Chapter(
        id: 0,
        startTime: 0.0,
        endTime: 120.0,
        title: 'Introduction',
      );

      expect(chapter.id, equals(0));
      expect(chapter.startTime, equals(0.0));
      expect(chapter.endTime, equals(120.0));
      expect(chapter.title, equals('Introduction'));
    });

    test('formatTime correctly formats seconds', () {
      expect(Chapter.formatTime(0), equals('00:00:00'));
      expect(Chapter.formatTime(90), equals('00:01:30'));
      expect(Chapter.formatTime(3665), equals('01:01:05'));
    });

    test('parseTime correctly parses time string', () {
      expect(Chapter.parseTime('00:00:00'), equals(0.0));
      expect(Chapter.parseTime('00:01:30'), equals(90.0));
      expect(Chapter.parseTime('01:01:05'), equals(3665.0));
    });

    test('formattedStartTime returns correct format', () {
      final chapter = Chapter(
        id: 0,
        startTime: 90.0,
        endTime: 180.0,
        title: 'Test',
      );

      expect(chapter.formattedStartTime, equals('00:01:30'));
    });

    test('toJson and fromJson work correctly', () {
      final chapter = Chapter(
        id: 1,
        startTime: 120.0,
        endTime: 240.0,
        title: 'Chapter 1',
      );

      final json = chapter.toJson();
      final restored = Chapter.fromJson(json);

      expect(restored.id, equals(chapter.id));
      expect(restored.startTime, equals(chapter.startTime));
      expect(restored.endTime, equals(chapter.endTime));
      expect(restored.title, equals(chapter.title));
    });
  });
}

import 'dart:io';
import 'dart:convert';
import '../models/chapter.dart';

/// Service for managing chapter markers in video files
class ChapterService {
  /// Parses chapters from a video file using ffprobe
  static Future<List<Chapter>> parseChapters(String filePath) async {
    try {
      final result = await Process.run(
        'ffprobe',
        [
          '-v',
          'error',
          '-print_format',
          'json',
          '-show_chapters',
          filePath,
        ],
      );

      if (result.exitCode != 0) {
        throw Exception('ffprobe failed: ${result.stderr}');
      }

      final jsonOutput = jsonDecode(result.stdout.toString());
      final chaptersJson = jsonOutput['chapters'] as List?;

      if (chaptersJson == null || chaptersJson.isEmpty) {
        return [];
      }

      final chapters = <Chapter>[];
      for (int i = 0; i < chaptersJson.length; i++) {
        final chapterData = chaptersJson[i] as Map<String, dynamic>;

        final startTime = double.tryParse(
              chapterData['start_time']?.toString() ?? '0',
            ) ??
            0.0;

        final endTime = double.tryParse(
              chapterData['end_time']?.toString() ?? '0',
            ) ??
            0.0;

        final tags = chapterData['tags'] as Map<String, dynamic>?;
        final title = tags?['title']?.toString() ?? 'Chapter ${i + 1}';

        chapters.add(Chapter(
          id: i,
          startTime: startTime,
          endTime: endTime,
          title: title,
        ));
      }

      return chapters;
    } catch (e) {
      throw Exception('Failed to parse chapters: $e');
    }
  }

  /// Generates FFmpeg metadata file content for chapters
  static String generateMetadataFile(List<Chapter> chapters) {
    final buffer = StringBuffer();
    buffer.writeln(';FFMETADATA1');

    for (final chapter in chapters) {
      buffer.writeln('[CHAPTER]');
      buffer.writeln('TIMEBASE=1/1000');
      buffer.writeln('START=${(chapter.startTime * 1000).toInt()}');
      buffer.writeln('END=${(chapter.endTime * 1000).toInt()}');
      buffer.writeln('title=${chapter.title}');
    }

    return buffer.toString();
  }

  /// Writes chapters to a video file using FFmpeg metadata
  static Future<void> writeChapters(
    String inputPath,
    String outputPath,
    List<Chapter> chapters,
  ) async {
    // Create temporary metadata file
    final tempDir = Directory.systemTemp.createTempSync('chapters_');
    final metadataFile = File('${tempDir.path}/metadata.txt');

    try {
      // Write metadata
      final metadata = generateMetadataFile(chapters);
      await metadataFile.writeAsString(metadata);

      // Run FFmpeg to write chapters
      final result = await Process.run(
        'ffmpeg',
        [
          '-i',
          inputPath,
          '-i',
          metadataFile.path,
          '-map_metadata',
          '1',
          '-codec',
          'copy',
          outputPath,
        ],
      );

      if (result.exitCode != 0) {
        throw Exception('FFmpeg failed: ${result.stderr}');
      }
    } finally {
      // Clean up temp file
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {
        // Ignore cleanup errors
      }
    }
  }

  /// Validates chapter list for consistency
  static bool validateChapters(List<Chapter> chapters) {
    if (chapters.isEmpty) {
      return true;
    }

    // Check for overlapping chapters
    for (int i = 0; i < chapters.length - 1; i++) {
      if (chapters[i].endTime > chapters[i + 1].startTime) {
        return false;
      }
    }

    // Check that all chapters have valid time ranges
    for (final chapter in chapters) {
      if (chapter.startTime >= chapter.endTime) {
        return false;
      }
      if (chapter.startTime < 0) {
        return false;
      }
    }

    return true;
  }

  /// Sorts chapters by start time
  static List<Chapter> sortChapters(List<Chapter> chapters) {
    final sorted = List<Chapter>.from(chapters);
    sorted.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Reassign IDs after sorting
    return sorted
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(id: entry.key))
        .toList();
  }

  /// Removes a chapter from the list
  static List<Chapter> removeChapter(List<Chapter> chapters, int id) {
    final filtered = chapters.where((c) => c.id != id).toList();
    // Reassign IDs
    return filtered
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(id: entry.key))
        .toList();
  }

  /// Adds a new chapter to the list
  static List<Chapter> addChapter(
    List<Chapter> chapters,
    Chapter newChapter,
  ) {
    final updated = List<Chapter>.from(chapters);
    updated.add(newChapter.copyWith(id: chapters.length));
    return sortChapters(updated);
  }

  /// Updates an existing chapter
  static List<Chapter> updateChapter(
    List<Chapter> chapters,
    Chapter updatedChapter,
  ) {
    final updated = chapters
        .map((c) => c.id == updatedChapter.id ? updatedChapter : c)
        .toList();
    return sortChapters(updated);
  }
}

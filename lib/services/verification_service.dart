import 'dart:convert';
import 'dart:io';

/// Result of a verification check
class VerificationResult {
  final bool passed;
  final String message;
  final Map<String, dynamic>? details;

  VerificationResult({
    required this.passed,
    required this.message,
    this.details,
  });
}

/// Service for verifying exported files
class VerificationService {
  /// Verify an exported file using FFprobe
  static Future<VerificationResult> verifyFile({
    required String filePath,
    required int expectedVideoStreams,
    required int expectedAudioStreams,
    required int expectedSubtitleStreams,
  }) async {
    try {
      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        return VerificationResult(
          passed: false,
          message: 'File not found: $filePath',
        );
      }

      // Use FFprobe to analyze the file
      final result = await Process.run('ffprobe', [
        '-v',
        'error',
        '-show_entries',
        'stream=index,codec_type,codec_name',
        '-of',
        'json',
        filePath,
      ]);

      if (result.exitCode != 0) {
        return VerificationResult(
          passed: false,
          message: 'FFprobe failed: ${result.stderr}',
        );
      }

      // Parse the JSON output
      final jsonOutput = jsonDecode(result.stdout as String);
      final streams = jsonOutput['streams'] as List<dynamic>;

      // Count streams by type
      int videoCount = 0;
      int audioCount = 0;
      int subtitleCount = 0;
      final List<String> errors = [];

      for (final stream in streams) {
        final codecType = stream['codec_type'] as String;
        final codecName = stream['codec_name'] as String?;

        switch (codecType) {
          case 'video':
            videoCount++;
            // Check for codec errors
            if (codecName == null || codecName.isEmpty) {
              errors.add('Video stream has no codec');
            }
            break;
          case 'audio':
            audioCount++;
            if (codecName == null || codecName.isEmpty) {
              errors.add('Audio stream has no codec');
            }
            break;
          case 'subtitle':
            subtitleCount++;
            break;
        }
      }

      // Verify stream counts match expected
      final streamCountMatch = videoCount == expectedVideoStreams &&
          audioCount == expectedAudioStreams &&
          subtitleCount == expectedSubtitleStreams;

      if (!streamCountMatch) {
        errors.add(
            'Stream count mismatch: Expected V:$expectedVideoStreams A:$expectedAudioStreams S:$expectedSubtitleStreams, '
            'Found V:$videoCount A:$audioCount S:$subtitleCount');
      }

      // Check file integrity
      final integrityResult = await _checkFileIntegrity(filePath);
      if (!integrityResult.passed) {
        errors.add(integrityResult.message);
      }

      // Generate result
      final passed = errors.isEmpty && streamCountMatch;
      final message = passed
          ? 'File verified successfully: V:$videoCount A:$audioCount S:$subtitleCount'
          : 'Verification failed: ${errors.join(', ')}';

      return VerificationResult(
        passed: passed,
        message: message,
        details: {
          'videoStreams': videoCount,
          'audioStreams': audioCount,
          'subtitleStreams': subtitleCount,
          'expectedVideoStreams': expectedVideoStreams,
          'expectedAudioStreams': expectedAudioStreams,
          'expectedSubtitleStreams': expectedSubtitleStreams,
          'errors': errors,
        },
      );
    } catch (e) {
      return VerificationResult(
        passed: false,
        message: 'Verification error: $e',
      );
    }
  }

  /// Check file integrity by attempting to decode a small portion
  static Future<VerificationResult> _checkFileIntegrity(String filePath) async {
    try {
      // Try to read a few frames from the file to check for corruption
      final result = await Process.run('ffmpeg', [
        '-v',
        'error',
        '-i',
        filePath,
        '-t',
        '1', // Just check first second
        '-f',
        'null',
        '-',
      ]);

      // FFmpeg returns 0 if file is readable without errors
      if (result.exitCode != 0) {
        final stderr = result.stderr as String;
        return VerificationResult(
          passed: false,
          message: 'File corruption detected: $stderr',
        );
      }

      return VerificationResult(
        passed: true,
        message: 'File integrity check passed',
      );
    } catch (e) {
      return VerificationResult(
        passed: false,
        message: 'Integrity check error: $e',
      );
    }
  }

  /// Generate a verification report for multiple files
  static String generateVerificationReport(
      List<VerificationResult> results, List<String> filePaths) {
    final buffer = StringBuffer();
    buffer.writeln('=== Verification Report ===');
    buffer.writeln('Files verified: ${results.length}');
    buffer.writeln('');

    int passedCount = 0;
    int failedCount = 0;

    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      final fileName = filePaths[i].split(Platform.pathSeparator).last;

      if (result.passed) {
        passedCount++;
        buffer.writeln('✓ $fileName - ${result.message}');
      } else {
        failedCount++;
        buffer.writeln('✗ $fileName - ${result.message}');
      }

      if (result.details != null) {
        final details = result.details!;
        if (details['errors'] != null &&
            (details['errors'] as List).isNotEmpty) {
          for (final error in details['errors'] as List) {
            buffer.writeln('  - $error');
          }
        }
      }
      buffer.writeln('');
    }

    buffer.writeln('Summary:');
    buffer.writeln('  Passed: $passedCount');
    buffer.writeln('  Failed: $failedCount');

    return buffer.toString();
  }
}

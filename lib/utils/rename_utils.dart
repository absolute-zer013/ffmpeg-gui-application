import 'dart:io';
import 'package:path/path.dart' as path;

/// Utility class for applying rename patterns to filenames
class RenameUtils {
  /// Apply a rename pattern to a file with variable substitution
  /// 
  /// Supported variables:
  /// - {name} - Original filename without extension
  /// - {ext} - File extension (e.g., mkv)
  /// - {date} - Current date (YYYY-MM-DD)
  /// - {time} - Current time (HH-MM-SS)
  /// - {year} - Current year
  /// - {month} - Current month (01-12)
  /// - {day} - Current day (01-31)
  /// - {index} - File index in batch (requires index parameter)
  /// - {episode} - Episode number (requires episode parameter)
  /// - {season} - Season number (requires season parameter)
  /// 
  /// Format modifiers:
  /// - {variable:N} - Pad with zeros to N digits (e.g., {index:3} = 001)
  static String applyPattern(
    String pattern,
    String originalPath, {
    int? index,
    int? episode,
    int? season,
    int? year,
  }) {
    // Get filename without extension
    final filename = path.basenameWithoutExtension(originalPath);
    final extension = path.extension(originalPath).replaceFirst('.', '');

    // Get current date/time
    final now = DateTime.now();
    final currentYear = year ?? now.year;
    final currentMonth = now.month;
    final currentDay = now.day;

    // Start with the pattern
    String result = pattern;

    // Replace all variables
    result = _replaceVariable(result, 'name', filename);
    result = _replaceVariable(result, 'ext', extension);
    result = _replaceVariable(
        result, 'date', '${now.year}-${_pad(now.month)}-${_pad(now.day)}');
    result = _replaceVariable(
        result, 'time', '${_pad(now.hour)}-${_pad(now.minute)}-${_pad(now.second)}');
    result = _replaceVariable(result, 'year', currentYear.toString());
    result = _replaceVariable(result, 'month', _pad(currentMonth));
    result = _replaceVariable(result, 'day', _pad(currentDay));

    // Replace optional variables with padding support
    if (index != null) {
      result = _replaceVariableWithPadding(result, 'index', index);
    }
    if (episode != null) {
      result = _replaceVariableWithPadding(result, 'episode', episode);
    }
    if (season != null) {
      result = _replaceVariableWithPadding(result, 'season', season);
    }

    // Clean up any remaining unreplaced variables (remove them)
    result = result.replaceAll(RegExp(r'\{[^}]+\}'), '');

    // Clean up multiple spaces
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Add extension back if not already included
    if (!result.endsWith('.$extension')) {
      result = '$result.$extension';
    }

    return result;
  }

  /// Replace a variable in the pattern
  static String _replaceVariable(String pattern, String variable, String value) {
    // Replace {variable} with value
    return pattern.replaceAll('{$variable}', value);
  }

  /// Replace a variable with optional padding
  static String _replaceVariableWithPadding(
      String pattern, String variable, int value) {
    // Check for padding format {variable:N}
    final paddingRegex = RegExp('{$variable:(\\d+)}');
    final match = paddingRegex.firstMatch(pattern);

    if (match != null) {
      final padding = int.parse(match.group(1)!);
      final paddedValue = value.toString().padLeft(padding, '0');
      return pattern.replaceAll(match.group(0)!, paddedValue);
    }

    // No padding specified, just replace
    return pattern.replaceAll('{$variable}', value.toString());
  }

  /// Pad a number to 2 digits
  static String _pad(int value) {
    return value.toString().padLeft(2, '0');
  }

  /// Validate a pattern for syntax errors
  /// Returns null if valid, error message if invalid
  static String? validatePattern(String pattern) {
    if (pattern.trim().isEmpty) {
      return 'Pattern cannot be empty';
    }

    // Check for unmatched braces
    int openBraces = 0;
    for (int i = 0; i < pattern.length; i++) {
      if (pattern[i] == '{') {
        openBraces++;
      } else if (pattern[i] == '}') {
        openBraces--;
        if (openBraces < 0) {
          return 'Unmatched closing brace at position $i';
        }
      }
    }

    if (openBraces > 0) {
      return 'Unmatched opening brace';
    }

    // Check for invalid characters in filename
    final invalidChars = ['<', '>', ':', '"', '/', '\\', '|', '?', '*'];
    for (final char in invalidChars) {
      if (pattern.contains(char)) {
        return 'Pattern contains invalid character: $char';
      }
    }

    return null;
  }

  /// Extract variables used in a pattern
  static List<String> extractVariables(String pattern) {
    final regex = RegExp(r'\{([^}:]+)(?::\d+)?\}');
    final matches = regex.allMatches(pattern);
    return matches.map((m) => m.group(1)!).toList();
  }

  /// Generate preview of renamed file
  static String generatePreview(
    String pattern,
    String originalPath, {
    int? index,
    int? episode,
    int? season,
    int? year,
  }) {
    try {
      return applyPattern(
        pattern,
        originalPath,
        index: index,
        episode: episode,
        season: season,
        year: year,
      );
    } catch (e) {
      return 'Error: $e';
    }
  }
}

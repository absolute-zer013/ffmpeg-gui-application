import 'package:path/path.dart' as path;

/// Result for a single item in a batch rename operation
class BatchRenameResult {
  final String originalPath;
  final String proposedName; // filename only (not a path)
  final bool skipped;
  final bool conflictResolved;
  final String? reason; // set if skipped or error handled

  BatchRenameResult({
    required this.originalPath,
    required this.proposedName,
    this.skipped = false,
    this.conflictResolved = false,
    this.reason,
  });
}

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
    result = _replaceVariable(result, 'time',
        '${_pad(now.hour)}-${_pad(now.minute)}-${_pad(now.second)}');
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

    // Remove dangling separators at the end (e.g., trailing '-' or '_' or '.')
    result = result.replaceAll(RegExp(r'[\-_.]+$'), '').trim();

    // Add extension back if not already included
    if (!result.endsWith('.$extension')) {
      result = '$result.$extension';
    }

    return result;
  }

  /// Replace a variable in the pattern
  static String _replaceVariable(
      String pattern, String variable, String value) {
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

    // Check for invalid characters in the literal output (ignore variables)
    final literal = pattern.replaceAll(RegExp(r'\{[^}]+\}'), '');
    final invalidChars = ['<', '>', ':', '"', '/', '\\', '|', '?', '*'];
    for (final char in invalidChars) {
      if (literal.contains(char)) {
        return 'Pattern contains invalid character: $char';
      }
    }

    // Check for unknown variables
    final validVariables = {
      'name',
      'ext',
      'date',
      'time',
      'year',
      'month',
      'day',
      'index',
      'episode',
      'season'
    };
    final variables = extractVariables(pattern);
    for (final variable in variables) {
      if (!validVariables.contains(variable)) {
        return 'Unknown variable: {$variable}';
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

  /// Strategy to handle filename collisions during batch rename
  /// - error: throw on conflict
  /// - suffix: append -1, -2, ... before the extension to make unique (default)
  /// - skip: mark result as skipped and continue
  static const String conflictError = 'error';
  static const String conflictSuffix = 'suffix';
  static const String conflictSkip = 'skip';

  /// Apply a rename pattern to many files at once.
  ///
  /// Inputs:
  /// - pattern: rename pattern supporting the same variables as [applyPattern]
  /// - originalPaths: absolute paths (used to extract base filename/ext)
  /// - startIndex: starting value for {index} when present
  /// - episodeStart: starting value for {episode} when present; auto-increments per file
  /// - season: value for {season} when present (constant for the batch)
  /// - existingNames: optional set of filenames already present in destination directory
  /// - conflictStrategy: one of [conflictError, conflictSuffix, conflictSkip]
  ///
  /// Output:
  /// - List of [BatchRenameResult] with unique, safe filenames (no path)
  static List<BatchRenameResult> applyPatternBatch({
    required String pattern,
    required List<String> originalPaths,
    int startIndex = 1,
    int? episodeStart,
    int? season,
    int? year,
    Set<String>? existingNames,
    String conflictStrategy = conflictSuffix,
  }) {
    // Validate pattern early
    final error = validatePattern(pattern);
    if (error != null) {
      throw ArgumentError('Invalid pattern: $error');
    }

    final results = <BatchRenameResult>[];
    final usedNames = <String>{
      ...?(existingNames)
    }; // track collisions within batch

    for (int i = 0; i < originalPaths.length; i++) {
      final original = originalPaths[i];
      final index = startIndex + i;
      final episode = episodeStart != null ? (episodeStart + i) : null;

      var candidate = applyPattern(
        pattern,
        original,
        index: index,
        episode: episode,
        season: season,
        year: year,
      );

      final baseName = path.basename(candidate);

      if (!usedNames.contains(baseName)) {
        usedNames.add(baseName);
        results.add(BatchRenameResult(
          originalPath: original,
          proposedName: baseName,
        ));
        continue;
      }

      // Handle conflict
      switch (conflictStrategy) {
        case conflictError:
          results.add(BatchRenameResult(
            originalPath: original,
            proposedName: baseName,
            skipped: true,
            reason: 'Conflict with existing filename: $baseName',
          ));
          break;
        case conflictSkip:
          results.add(BatchRenameResult(
            originalPath: original,
            proposedName: baseName,
            skipped: true,
            reason: 'Skipped due to conflict: $baseName',
          ));
          break;
        case conflictSuffix:
        default:
          final unique = _dedupeWithSuffix(baseName, usedNames);
          usedNames.add(unique);
          results.add(BatchRenameResult(
            originalPath: original,
            proposedName: unique,
            conflictResolved: true,
          ));
      }
    }

    return results;
  }

  /// Generate a unique filename by appending -1, -2, ... before the extension.
  static String _dedupeWithSuffix(String fileName, Set<String> alreadyUsed) {
    if (!alreadyUsed.contains(fileName)) return fileName;

    final ext = path.extension(fileName);
    final name = fileName.substring(0, fileName.length - ext.length);
    int counter = 1;
    while (true) {
      final candidate = '$name-$counter$ext';
      if (!alreadyUsed.contains(candidate)) {
        return candidate;
      }
      counter++;
    }
  }
}

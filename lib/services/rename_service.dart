import 'package:ffmpeg_filter_app/utils/rename_utils.dart';

/// A small service that plans batch renames using RenameUtils and summarizes
/// conflicts so the UI can present a preview before executing any filesystem
/// operations.
class RenameService {
  /// Plan batch renames for a list of absolute file paths.
  ///
  /// Inputs:
  /// - pattern: rename pattern (e.g., "{name} - S{season:2}E{episode:2}")
  /// - paths: list of absolute source file paths
  /// - startIndex: starting index for {index}
  /// - episodeStart: starting episode for {episode} (auto-increments)
  /// - season/year: optional constants used by variables
  /// - existingNames: names already present in the destination directory
  /// - conflictStrategy: how to resolve duplicates (see RenameUtils constants)
  ///
  /// Returns a [BatchRenamePlan] that includes per-file results and a count of
  /// conflicts that were resolved or skipped.
  static BatchRenamePlan planBatchRenames({
    required String pattern,
    required List<String> paths,
    int startIndex = 1,
    int? episodeStart,
    int? season,
    int? year,
    Set<String>? existingNames,
    String conflictStrategy = RenameUtils.conflictSuffix,
  }) {
    final results = RenameUtils.applyPatternBatch(
      pattern: pattern,
      originalPaths: paths,
      startIndex: startIndex,
      episodeStart: episodeStart,
      season: season,
      year: year,
      existingNames: existingNames,
      conflictStrategy: conflictStrategy,
    );

    final mapping = <String, String>{};
    int resolved = 0;
    int skipped = 0;

    for (final r in results) {
      if (r.skipped) {
        skipped++;
        continue;
      }
      if (r.conflictResolved) {
        resolved++;
      }
      mapping[r.originalPath] = r.proposedName;
    }

    return BatchRenamePlan(
      results: results,
      renameMapping: mapping,
      resolvedConflicts: resolved,
      skippedItems: skipped,
    );
  }

  /// Applies global find/replace to proposed names
  /// 
  /// [plan] - The original batch rename plan
  /// [findText] - Text to find
  /// [replaceText] - Text to replace with
  /// [useRegex] - Whether to use regex matching
  /// [caseSensitive] - Whether the search is case-sensitive
  static BatchRenamePlan applyFindReplace(
    BatchRenamePlan plan, {
    required String findText,
    required String replaceText,
    bool useRegex = false,
    bool caseSensitive = true,
  }) {
    final updatedResults = plan.results.map((result) {
      if (result.skipped) return result;

      String newName = result.proposedName;

      if (useRegex) {
        try {
          final regex = RegExp(
            findText,
            caseSensitive: caseSensitive,
          );
          newName = newName.replaceAll(regex, replaceText);
        } catch (e) {
          // Invalid regex, skip replacement
          return result;
        }
      } else {
        if (caseSensitive) {
          newName = newName.replaceAll(findText, replaceText);
        } else {
          final pattern = RegExp(RegExp.escape(findText), caseSensitive: false);
          newName = newName.replaceAll(pattern, replaceText);
        }
      }

      return BatchRenameResult(
        originalPath: result.originalPath,
        proposedName: newName,
        conflictResolved: result.conflictResolved,
        skipped: result.skipped,
      );
    }).toList();

    return _rebuildPlan(updatedResults);
  }

  /// Exports the rename plan to CSV format
  static String exportToCsv(BatchRenamePlan plan) {
    final buffer = StringBuffer();
    buffer.writeln('Original Name,Proposed Name,Status');

    for (final result in plan.results) {
      final originalName = _extractFileName(result.originalPath);
      final status = result.skipped
          ? 'Skipped'
          : result.conflictResolved
              ? 'Conflict Resolved'
              : 'OK';

      // Escape quotes in CSV
      final escapedOriginal = originalName.replaceAll('"', '""');
      final escapedProposed = result.proposedName.replaceAll('"', '""');

      buffer.writeln('"$escapedOriginal","$escapedProposed","$status"');
    }

    return buffer.toString();
  }

  /// Exports the rename plan to Markdown format
  static String exportToMarkdown(BatchRenamePlan plan) {
    final buffer = StringBuffer();
    buffer.writeln('# Batch Rename Preview');
    buffer.writeln();
    buffer.writeln('## Summary');
    buffer.writeln('- Total files: ${plan.results.length}');
    buffer.writeln('- Resolved conflicts: ${plan.resolvedConflicts}');
    buffer.writeln('- Skipped items: ${plan.skippedItems}');
    buffer.writeln();
    buffer.writeln('## Rename Plan');
    buffer.writeln();
    buffer.writeln('| Original Name | Proposed Name | Status |');
    buffer.writeln('|---------------|---------------|--------|');

    for (final result in plan.results) {
      final originalName = _extractFileName(result.originalPath);
      final status = result.skipped
          ? 'Skipped'
          : result.conflictResolved
              ? 'Conflict Resolved'
              : 'OK';

      buffer.writeln('| $originalName | ${result.proposedName} | $status |');
    }

    return buffer.toString();
  }

  /// Applies transformations to rename plan
  /// 
  /// [transformation] - Type of transformation to apply
  static BatchRenamePlan applyTransformation(
    BatchRenamePlan plan,
    RenameTransformation transformation,
  ) {
    final updatedResults = plan.results.map((result) {
      if (result.skipped) return result;

      String newName = result.proposedName;

      switch (transformation) {
        case RenameTransformation.trimSpaces:
          newName = newName.trim();
          break;
        case RenameTransformation.normalizeSpaces:
          newName = newName.replaceAll(RegExp(r'\s+'), ' ');
          break;
        case RenameTransformation.dashesToUnderscores:
          newName = newName.replaceAll('-', '_');
          break;
        case RenameTransformation.underscoresToDashes:
          newName = newName.replaceAll('_', '-');
          break;
        case RenameTransformation.uppercase:
          newName = newName.toUpperCase();
          break;
        case RenameTransformation.lowercase:
          newName = newName.toLowerCase();
          break;
        case RenameTransformation.titleCase:
          newName = _toTitleCase(newName);
          break;
      }

      return BatchRenameResult(
        originalPath: result.originalPath,
        proposedName: newName,
        conflictResolved: result.conflictResolved,
        skipped: result.skipped,
      );
    }).toList();

    return _rebuildPlan(updatedResults);
  }

  /// Rebuilds a BatchRenamePlan from updated results
  static BatchRenamePlan _rebuildPlan(List<BatchRenameResult> results) {
    final mapping = <String, String>{};
    int resolved = 0;
    int skipped = 0;

    for (final r in results) {
      if (r.skipped) {
        skipped++;
        continue;
      }
      if (r.conflictResolved) {
        resolved++;
      }
      mapping[r.originalPath] = r.proposedName;
    }

    return BatchRenamePlan(
      results: results,
      renameMapping: mapping,
      resolvedConflicts: resolved,
      skippedItems: skipped,
    );
  }

  /// Extracts filename from full path
  static String _extractFileName(String path) {
    final lastSeparator = path.lastIndexOf(RegExp(r'[/\\]'));
    return lastSeparator >= 0 ? path.substring(lastSeparator + 1) : path;
  }

  /// Converts string to title case
  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

/// Transformation types for batch rename
enum RenameTransformation {
  trimSpaces,
  normalizeSpaces,
  dashesToUnderscores,
  underscoresToDashes,
  uppercase,
  lowercase,
  titleCase,
}

/// Summary of a planned batch rename operation.
class BatchRenamePlan {
  final List<BatchRenameResult> results;

  /// Map of original absolute path -> proposed filename (no directory)
  final Map<String, String> renameMapping;
  final int resolvedConflicts;
  final int skippedItems;

  BatchRenamePlan({
    required this.results,
    required this.renameMapping,
    required this.resolvedConflicts,
    required this.skippedItems,
  });
}

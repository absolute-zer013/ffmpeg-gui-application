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

import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/services/rename_service.dart';

void main() {
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
}

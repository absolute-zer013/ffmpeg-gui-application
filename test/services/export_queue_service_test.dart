import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/services/export_queue_service.dart';
import 'package:ffmpeg_filter_app/models/export_queue_item.dart';
import 'package:ffmpeg_filter_app/models/file_item.dart';
import 'package:ffmpeg_filter_app/models/multi_profile_export_config.dart';
import 'package:ffmpeg_filter_app/models/export_profile.dart';

void main() {
  group('ExportQueueService', () {
    late ExportQueueService service;
    late FileItem fileItem1;
    late FileItem fileItem2;
    late FileItem fileItem3;

    setUp(() {
      service = ExportQueueService();
      fileItem1 = FileItem(
        path: '/path/to/video1.mkv',
        audioTracks: [],
        subtitleTracks: [],
      );
      fileItem2 = FileItem(
        path: '/path/to/video2.mkv',
        audioTracks: [],
        subtitleTracks: [],
      );
      fileItem3 = FileItem(
        path: '/path/to/video3.mkv',
        audioTracks: [],
        subtitleTracks: [],
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('ExportQueueService initializes with empty queue', () {
      expect(service.queue, isEmpty);
    });

    test('addToQueue adds item to queue', () {
      service.addToQueue(fileItem1);

      expect(service.queue.length, equals(1));
      expect(service.queue.first.fileItem, equals(fileItem1));
    });

    test('addToQueue with priority sorts correctly', () {
      service.addToQueue(fileItem1, priority: 1);
      service.addToQueue(fileItem2, priority: 10);
      service.addToQueue(fileItem3, priority: 5);

      expect(service.queue.length, equals(3));
      expect(service.queue[0].fileItem, equals(fileItem2));
      expect(service.queue[1].fileItem, equals(fileItem3));
      expect(service.queue[2].fileItem, equals(fileItem1));
    });

    test('addAllToQueue adds multiple items', () {
      service.addAllToQueue([fileItem1, fileItem2, fileItem3]);

      expect(service.queue.length, equals(3));
    });

    test('removeFromQueue removes item by id', () {
      service.addToQueue(fileItem1);
      service.addToQueue(fileItem2);

      final id = service.queue.first.id;
      service.removeFromQueue(id);

      expect(service.queue.length, equals(1));
      expect(service.queue.first.fileItem, equals(fileItem2));
    });

    test('clearQueue removes all items', () {
      service.addAllToQueue([fileItem1, fileItem2, fileItem3]);
      service.clearQueue();

      expect(service.queue, isEmpty);
    });

    test('updateStatus changes item status', () {
      service.addToQueue(fileItem1);
      final id = service.queue.first.id;

      service.updateStatus(id, QueueItemStatus.processing);

      expect(service.queue.first.status, equals(QueueItemStatus.processing));
    });

    test('pauseItem pauses processing item', () {
      service.addToQueue(fileItem1);
      final id = service.queue.first.id;

      service.startItem(id);
      service.pauseItem(id);

      expect(service.queue.first.status, equals(QueueItemStatus.paused));
    });

    test('resumeItem resumes paused item', () {
      service.addToQueue(fileItem1);
      final id = service.queue.first.id;

      service.pauseItem(id);
      service.resumeItem(id);

      expect(service.queue.first.status, equals(QueueItemStatus.pending));
    });

    test('startItem marks item as processing with timestamp', () {
      service.addToQueue(fileItem1);
      final id = service.queue.first.id;

      service.startItem(id);

      expect(service.queue.first.status, equals(QueueItemStatus.processing));
      expect(service.queue.first.startedAt, isNotNull);
    });

    test('completeItem marks item as completed with timestamp', () {
      service.addToQueue(fileItem1);
      final id = service.queue.first.id;

      service.completeItem(id);

      expect(service.queue.first.status, equals(QueueItemStatus.completed));
      expect(service.queue.first.completedAt, isNotNull);
    });

    test('completeItem with error marks item as failed', () {
      service.addToQueue(fileItem1);
      final id = service.queue.first.id;

      service.completeItem(id, error: 'Test error');

      expect(service.queue.first.status, equals(QueueItemStatus.failed));
      expect(service.queue.first.error, equals('Test error'));
    });

    test('cancelItem marks item as cancelled', () {
      service.addToQueue(fileItem1);
      final id = service.queue.first.id;

      service.cancelItem(id);

      expect(service.queue.first.status, equals(QueueItemStatus.cancelled));
      expect(service.queue.first.completedAt, isNotNull);
    });

    test('setPriority changes item priority and resorts', () {
      service.addToQueue(fileItem1, priority: 1);
      service.addToQueue(fileItem2, priority: 5);

      final id = service.queue.last.id;
      service.setPriority(id, 10);

      expect(service.queue.first.priority, equals(10));
    });

    test('moveUp moves item up in queue', () {
      service.addAllToQueue([fileItem1, fileItem2, fileItem3]);

      final secondId = service.queue[1].id;
      service.moveUp(secondId);

      expect(service.queue[0].id, equals(secondId));
    });

    test('moveDown moves item down in queue', () {
      service.addAllToQueue([fileItem1, fileItem2, fileItem3]);

      final firstId = service.queue[0].id;
      service.moveDown(firstId);

      expect(service.queue[1].id, equals(firstId));
    });

    test('reorder changes item position', () {
      service.addAllToQueue([fileItem1, fileItem2, fileItem3]);

      final firstItem = service.queue[0].fileItem;
      service.reorder(0, 2);

      expect(service.queue[1].fileItem, equals(firstItem));
    });

    test('getNextPendingItem returns first pending item', () {
      service.addAllToQueue([fileItem1, fileItem2, fileItem3]);
      service.updateStatus(service.queue[0].id, QueueItemStatus.completed);

      final next = service.getNextPendingItem();

      expect(next, isNotNull);
      expect(next!.status, equals(QueueItemStatus.pending));
    });

    test('getPendingItems returns all pending items', () {
      service.addAllToQueue([fileItem1, fileItem2, fileItem3]);
      service.updateStatus(service.queue[0].id, QueueItemStatus.completed);

      final pending = service.getPendingItems();

      expect(pending.length, equals(2));
    });

    test('getProcessingItems returns all processing items', () {
      service.addAllToQueue([fileItem1, fileItem2, fileItem3]);
      service.startItem(service.queue[0].id);
      service.startItem(service.queue[1].id);

      final processing = service.getProcessingItems();

      expect(processing.length, equals(2));
    });

    test('getCompletedItems returns all completed items', () {
      service.addAllToQueue([fileItem1, fileItem2, fileItem3]);
      service.completeItem(service.queue[0].id);

      final completed = service.getCompletedItems();

      expect(completed.length, equals(1));
    });

    test('hasActiveItems returns true when items are active', () {
      service.addToQueue(fileItem1);

      expect(service.hasActiveItems, isTrue);
    });

    test('hasActiveItems returns false when no items are active', () {
      service.addToQueue(fileItem1);
      service.completeItem(service.queue[0].id);

      expect(service.hasActiveItems, isFalse);
    });

    test('queueStream emits updates on changes', () async {
      final stream = service.queueStream;
      final streamFuture = stream.first;

      service.addToQueue(fileItem1);

      final emittedQueue = await streamFuture;
      expect(emittedQueue.length, equals(1));
    });

    test('addMultiProfileExport adds multiple items for each profile', () {
      final profile1 = ExportProfile(name: 'HD', removeEnglishAudio: true);
      final profile2 = ExportProfile(name: 'SD', removeEnglishAudio: false);
      
      final config = MultiProfileExportConfig(
        profiles: [profile1, profile2],
        suffixStrategy: FilenameSuffixStrategy.profileName,
      );

      service.addMultiProfileExport(fileItem1, config);

      expect(service.queue.length, equals(2));
      expect(service.queue[0].fileItem, equals(fileItem1));
      expect(service.queue[1].fileItem, equals(fileItem1));
    });

    test('addMultiProfileExport respects priority', () {
      final profile1 = ExportProfile(name: 'HD', removeEnglishAudio: true);
      final profile2 = ExportProfile(name: 'SD', removeEnglishAudio: false);
      
      final config = MultiProfileExportConfig(
        profiles: [profile1, profile2],
      );

      service.addToQueue(fileItem2, priority: 1);
      service.addMultiProfileExport(fileItem1, config, priority: 10);

      expect(service.queue.length, equals(3));
      // High priority items should be first
      expect(service.queue[0].priority, equals(10));
      expect(service.queue[1].priority, equals(10));
      expect(service.queue[2].priority, equals(1));
    });

    test('addMultiProfileExport with three profiles creates three items', () {
      final profile1 = ExportProfile(name: 'HD', removeEnglishAudio: true);
      final profile2 = ExportProfile(name: 'SD', removeEnglishAudio: false);
      final profile3 = ExportProfile(name: 'Mobile', removeEnglishAudio: true);
      
      final config = MultiProfileExportConfig(
        profiles: [profile1, profile2, profile3],
      );

      service.addMultiProfileExport(fileItem1, config);

      expect(service.queue.length, equals(3));
    });
  });
}

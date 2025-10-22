import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/export_queue_item.dart';
import 'package:ffmpeg_filter_app/models/file_item.dart';

void main() {
  group('ExportQueueItem', () {
    late FileItem fileItem;

    setUp(() {
      fileItem = FileItem(
        path: '/path/to/video.mkv',
        audioTracks: [],
        subtitleTracks: [],
      );
    });

    test('ExportQueueItem initializes with default values', () {
      final queueItem = ExportQueueItem(
        id: '123',
        fileItem: fileItem,
      );

      expect(queueItem.id, equals('123'));
      expect(queueItem.fileItem, equals(fileItem));
      expect(queueItem.status, equals(QueueItemStatus.pending));
      expect(queueItem.priority, equals(0));
      expect(queueItem.addedAt, isNotNull);
      expect(queueItem.startedAt, isNull);
      expect(queueItem.completedAt, isNull);
      expect(queueItem.error, isNull);
    });

    test('ExportQueueItem can be initialized with custom values', () {
      final addedAt = DateTime.now();
      final queueItem = ExportQueueItem(
        id: '456',
        fileItem: fileItem,
        status: QueueItemStatus.processing,
        priority: 10,
        addedAt: addedAt,
      );

      expect(queueItem.status, equals(QueueItemStatus.processing));
      expect(queueItem.priority, equals(10));
      expect(queueItem.addedAt, equals(addedAt));
    });

    test('ExportQueueItem can be copied with updated fields', () {
      final queueItem = ExportQueueItem(
        id: '789',
        fileItem: fileItem,
      );

      final updated = queueItem.copyWith(
        status: QueueItemStatus.completed,
        priority: 5,
      );

      expect(updated.id, equals('789'));
      expect(updated.fileItem, equals(fileItem));
      expect(updated.status, equals(QueueItemStatus.completed));
      expect(updated.priority, equals(5));
      expect(queueItem.status, equals(QueueItemStatus.pending));
      expect(queueItem.priority, equals(0));
    });

    test('ExportQueueItem can be serialized to JSON', () {
      final now = DateTime.now();
      final queueItem = ExportQueueItem(
        id: '111',
        fileItem: fileItem,
        status: QueueItemStatus.processing,
        priority: 3,
        addedAt: now,
      );

      final json = queueItem.toJson();

      expect(json['id'], equals('111'));
      expect(json['status'], equals('processing'));
      expect(json['priority'], equals(3));
      expect(json['addedAt'], equals(now.toIso8601String()));
    });

    test('ExportQueueItem can be deserialized from JSON', () {
      final now = DateTime.now();
      final json = {
        'id': '222',
        'status': 'completed',
        'priority': 7,
        'addedAt': now.toIso8601String(),
      };

      final queueItem = ExportQueueItem.fromJson(json, fileItem);

      expect(queueItem.id, equals('222'));
      expect(queueItem.fileItem, equals(fileItem));
      expect(queueItem.status, equals(QueueItemStatus.completed));
      expect(queueItem.priority, equals(7));
      expect(queueItem.addedAt, equals(now));
    });

    test('QueueItemStatus enum has expected values', () {
      expect(QueueItemStatus.values, contains(QueueItemStatus.pending));
      expect(QueueItemStatus.values, contains(QueueItemStatus.processing));
      expect(QueueItemStatus.values, contains(QueueItemStatus.paused));
      expect(QueueItemStatus.values, contains(QueueItemStatus.completed));
      expect(QueueItemStatus.values, contains(QueueItemStatus.failed));
      expect(QueueItemStatus.values, contains(QueueItemStatus.cancelled));
    });

    test('ExportQueueItem handles optional timestamps', () {
      final queueItem = ExportQueueItem(
        id: '333',
        fileItem: fileItem,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      final json = queueItem.toJson();
      expect(json['startedAt'], isNotNull);
      expect(json['completedAt'], isNotNull);

      final recreated = ExportQueueItem.fromJson(json, fileItem);
      expect(recreated.startedAt, isNotNull);
      expect(recreated.completedAt, isNotNull);
    });

    test('ExportQueueItem handles error field', () {
      final queueItem = ExportQueueItem(
        id: '444',
        fileItem: fileItem,
        status: QueueItemStatus.failed,
        error: 'File not found',
      );

      expect(queueItem.error, equals('File not found'));

      final json = queueItem.toJson();
      expect(json['error'], equals('File not found'));

      final recreated = ExportQueueItem.fromJson(json, fileItem);
      expect(recreated.error, equals('File not found'));
    });
  });
}

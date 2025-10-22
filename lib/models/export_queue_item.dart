import 'file_item.dart';

/// Status of an item in the export queue
enum QueueItemStatus {
  pending,
  processing,
  paused,
  completed,
  failed,
  cancelled,
}

/// Represents an item in the export queue
class ExportQueueItem {
  final String id;
  final FileItem fileItem;
  QueueItemStatus status;
  int priority;
  DateTime addedAt;
  DateTime? startedAt;
  DateTime? completedAt;
  String? error;

  ExportQueueItem({
    required this.id,
    required this.fileItem,
    this.status = QueueItemStatus.pending,
    this.priority = 0,
    DateTime? addedAt,
    this.startedAt,
    this.completedAt,
    this.error,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Creates a copy of this queue item with updated fields
  ExportQueueItem copyWith({
    QueueItemStatus? status,
    int? priority,
    DateTime? addedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? error,
  }) {
    return ExportQueueItem(
      id: id,
      fileItem: fileItem,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      addedAt: addedAt ?? this.addedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      error: error ?? this.error,
    );
  }

  /// Converts the queue item to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.name,
      'priority': priority,
      'addedAt': addedAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'error': error,
      // Note: FileItem is not serialized, needs to be handled separately
    };
  }

  /// Creates a queue item from a JSON map
  static ExportQueueItem fromJson(
      Map<String, dynamic> json, FileItem fileItem) {
    return ExportQueueItem(
      id: json['id'] as String,
      fileItem: fileItem,
      status: QueueItemStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => QueueItemStatus.pending,
      ),
      priority: json['priority'] as int? ?? 0,
      addedAt: DateTime.parse(json['addedAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      error: json['error'] as String?,
    );
  }
}

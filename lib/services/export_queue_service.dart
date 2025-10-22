import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/export_queue_item.dart';
import '../models/file_item.dart';

/// Service for managing the export queue
class ExportQueueService {
  static const String _queueKey = 'export_queue';

  final List<ExportQueueItem> _queue = [];
  final StreamController<List<ExportQueueItem>> _queueController =
      StreamController<List<ExportQueueItem>>.broadcast();

  /// Stream of queue updates
  Stream<List<ExportQueueItem>> get queueStream => _queueController.stream;

  /// Current queue items
  List<ExportQueueItem> get queue => List.unmodifiable(_queue);

  /// Disposes resources
  void dispose() {
    _queueController.close();
  }

  /// Adds an item to the queue
  void addToQueue(FileItem fileItem, {int priority = 0}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final queueItem = ExportQueueItem(
      id: id,
      fileItem: fileItem,
      priority: priority,
    );

    _queue.add(queueItem);
    _sortQueue();
    _notifyListeners();
  }

  /// Adds multiple items to the queue
  void addAllToQueue(List<FileItem> fileItems, {int priority = 0}) {
    for (final fileItem in fileItems) {
      addToQueue(fileItem, priority: priority);
    }
  }

  /// Removes an item from the queue
  void removeFromQueue(String id) {
    _queue.removeWhere((item) => item.id == id);
    _notifyListeners();
  }

  /// Clears all items from the queue
  void clearQueue() {
    _queue.clear();
    _notifyListeners();
  }

  /// Updates the status of a queue item
  void updateStatus(String id, QueueItemStatus status) {
    final index = _queue.indexWhere((item) => item.id == id);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(status: status);
      _notifyListeners();
    }
  }

  /// Pauses a processing item
  void pauseItem(String id) {
    updateStatus(id, QueueItemStatus.paused);
  }

  /// Resumes a paused item
  void resumeItem(String id) {
    updateStatus(id, QueueItemStatus.pending);
  }

  /// Marks an item as started
  void startItem(String id) {
    final index = _queue.indexWhere((item) => item.id == id);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(
        status: QueueItemStatus.processing,
        startedAt: DateTime.now(),
      );
      _notifyListeners();
    }
  }

  /// Marks an item as completed
  void completeItem(String id, {String? error}) {
    final index = _queue.indexWhere((item) => item.id == id);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(
        status: error != null ? QueueItemStatus.failed : QueueItemStatus.completed,
        completedAt: DateTime.now(),
        error: error,
      );
      _notifyListeners();
    }
  }

  /// Cancels an item
  void cancelItem(String id) {
    final index = _queue.indexWhere((item) => item.id == id);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(
        status: QueueItemStatus.cancelled,
        completedAt: DateTime.now(),
      );
      _notifyListeners();
    }
  }

  /// Changes the priority of an item
  void setPriority(String id, int priority) {
    final index = _queue.indexWhere((item) => item.id == id);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(priority: priority);
      _sortQueue();
      _notifyListeners();
    }
  }

  /// Moves an item up in the queue (higher priority)
  void moveUp(String id) {
    final index = _queue.indexWhere((item) => item.id == id);
    if (index > 0) {
      final item = _queue.removeAt(index);
      _queue.insert(index - 1, item);
      _notifyListeners();
    }
  }

  /// Moves an item down in the queue (lower priority)
  void moveDown(String id) {
    final index = _queue.indexWhere((item) => item.id == id);
    if (index != -1 && index < _queue.length - 1) {
      final item = _queue.removeAt(index);
      _queue.insert(index + 1, item);
      _notifyListeners();
    }
  }

  /// Reorders queue items by moving an item to a new position
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);
    _notifyListeners();
  }

  /// Sorts the queue by priority (higher priority first)
  void _sortQueue() {
    _queue.sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// Gets the next pending item from the queue
  ExportQueueItem? getNextPendingItem() {
    return _queue.firstWhere(
      (item) => item.status == QueueItemStatus.pending,
      orElse: () => _queue.first, // Return first item if none pending
    );
  }

  /// Gets all pending items
  List<ExportQueueItem> getPendingItems() {
    return _queue.where((item) => item.status == QueueItemStatus.pending).toList();
  }

  /// Gets all processing items
  List<ExportQueueItem> getProcessingItems() {
    return _queue.where((item) => item.status == QueueItemStatus.processing).toList();
  }

  /// Gets all completed items
  List<ExportQueueItem> getCompletedItems() {
    return _queue.where((item) => item.status == QueueItemStatus.completed).toList();
  }

  /// Checks if the queue has any pending or processing items
  bool get hasActiveItems {
    return _queue.any((item) =>
        item.status == QueueItemStatus.pending ||
        item.status == QueueItemStatus.processing);
  }

  /// Notifies listeners of queue changes
  void _notifyListeners() {
    _queueController.add(List.unmodifiable(_queue));
  }

  /// Saves the queue state to preferences (without file data)
  Future<void> saveQueueState() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = _queue.map((item) => item.toJson()).toList();
    await prefs.setString(_queueKey, jsonEncode(queueJson));
  }

  /// Clears saved queue state
  Future<void> clearSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }
}

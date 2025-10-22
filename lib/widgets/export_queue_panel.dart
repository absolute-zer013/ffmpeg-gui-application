import 'package:flutter/material.dart';
import '../models/export_queue_item.dart';
import '../services/export_queue_service.dart';

/// Widget for displaying and managing the export queue
class ExportQueuePanel extends StatelessWidget {
  final ExportQueueService queueService;
  final bool isExporting;
  final VoidCallback? onPauseItem;
  final VoidCallback? onResumeItem;
  final VoidCallback? onCancelItem;

  const ExportQueuePanel({
    super.key,
    required this.queueService,
    this.isExporting = false,
    this.onPauseItem,
    this.onResumeItem,
    this.onCancelItem,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ExportQueueItem>>(
      stream: queueService.queueStream,
      initialData: queueService.queue,
      builder: (context, snapshot) {
        final queue = snapshot.data ?? [];

        if (queue.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.queue_outlined,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Queue is empty',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.queue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Export Queue (${queue.length} items)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (queue.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => queueService.clearQueue(),
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Clear All'),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: queue.length,
                  onReorder: (oldIndex, newIndex) {
                    queueService.reorder(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final item = queue[index];
                    return _buildQueueItem(context, item, index);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQueueItem(
      BuildContext context, ExportQueueItem item, int index) {
    final statusColor = _getStatusColor(item.status);
    final statusIcon = _getStatusIcon(item.status);

    return Card(
      key: ValueKey(item.id),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
            const SizedBox(width: 8),
            Icon(statusIcon, color: statusColor),
          ],
        ),
        title: Text(
          item.fileItem.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(_getStatusText(item)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.status == QueueItemStatus.processing)
              IconButton(
                icon: const Icon(Icons.pause),
                onPressed: () {
                  queueService.pauseItem(item.id);
                  onPauseItem?.call();
                },
                tooltip: 'Pause',
              ),
            if (item.status == QueueItemStatus.paused)
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () {
                  queueService.resumeItem(item.id);
                  onResumeItem?.call();
                },
                tooltip: 'Resume',
              ),
            if (item.status == QueueItemStatus.pending ||
                item.status == QueueItemStatus.processing)
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () {
                  queueService.cancelItem(item.id);
                  onCancelItem?.call();
                },
                tooltip: 'Cancel',
              ),
            if (item.status == QueueItemStatus.completed ||
                item.status == QueueItemStatus.failed ||
                item.status == QueueItemStatus.cancelled)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => queueService.removeFromQueue(item.id),
                tooltip: 'Remove',
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleMenuAction(value, item),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'moveUp',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_upward),
                      SizedBox(width: 8),
                      Text('Move Up'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'moveDown',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_downward),
                      SizedBox(width: 8),
                      Text('Move Down'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete),
                      SizedBox(width: 8),
                      Text('Remove'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, ExportQueueItem item) {
    switch (action) {
      case 'moveUp':
        queueService.moveUp(item.id);
        break;
      case 'moveDown':
        queueService.moveDown(item.id);
        break;
      case 'remove':
        queueService.removeFromQueue(item.id);
        break;
    }
  }

  Color _getStatusColor(QueueItemStatus status) {
    switch (status) {
      case QueueItemStatus.pending:
        return Colors.grey;
      case QueueItemStatus.processing:
        return Colors.blue;
      case QueueItemStatus.paused:
        return Colors.orange;
      case QueueItemStatus.completed:
        return Colors.green;
      case QueueItemStatus.failed:
        return Colors.red;
      case QueueItemStatus.cancelled:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(QueueItemStatus status) {
    switch (status) {
      case QueueItemStatus.pending:
        return Icons.pending;
      case QueueItemStatus.processing:
        return Icons.hourglass_empty;
      case QueueItemStatus.paused:
        return Icons.pause_circle;
      case QueueItemStatus.completed:
        return Icons.check_circle;
      case QueueItemStatus.failed:
        return Icons.error;
      case QueueItemStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(ExportQueueItem item) {
    switch (item.status) {
      case QueueItemStatus.pending:
        return 'Waiting...';
      case QueueItemStatus.processing:
        final progress = item.fileItem.exportProgress;
        return 'Processing (${(progress * 100).toStringAsFixed(0)}%)';
      case QueueItemStatus.paused:
        return 'Paused';
      case QueueItemStatus.completed:
        return 'Completed';
      case QueueItemStatus.failed:
        return 'Failed: ${item.error ?? "Unknown error"}';
      case QueueItemStatus.cancelled:
        return 'Cancelled';
    }
  }
}

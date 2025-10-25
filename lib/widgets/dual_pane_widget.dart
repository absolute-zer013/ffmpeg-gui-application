import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/dual_pane_mode.dart';
import '../models/file_item.dart';
import 'file_preview_dialog.dart';

/// Widget that displays dual pane mode with split screen layout.
class DualPaneWidget extends StatefulWidget {
  final DualPaneMode mode;
  final FileItem? leftFile;
  final FileItem? rightFile;
  final ValueChanged<DualPaneMode> onModeChanged;

  const DualPaneWidget({
    super.key,
    required this.mode,
    this.leftFile,
    this.rightFile,
    required this.onModeChanged,
  });

  @override
  State<DualPaneWidget> createState() => _DualPaneWidgetState();
}

class _DualPaneWidgetState extends State<DualPaneWidget> {
  late double _dividerPosition;

  @override
  void initState() {
    super.initState();
    _dividerPosition = widget.mode.dividerPosition;
  }

  @override
  void didUpdateWidget(DualPaneWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode.dividerPosition != oldWidget.mode.dividerPosition) {
      _dividerPosition = widget.mode.dividerPosition;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.mode.enabled) {
      return const SizedBox.shrink();
    }

    final isHorizontal =
        widget.mode.orientation == DualPaneOrientation.horizontal;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize =
            isHorizontal ? constraints.maxWidth : constraints.maxHeight;
        final pane1Size = maxSize * _dividerPosition;
        final pane2Size = maxSize * (1 - _dividerPosition);

        return Flex(
          direction: isHorizontal ? Axis.horizontal : Axis.vertical,
          children: [
            SizedBox(
              width: isHorizontal ? pane1Size : null,
              height: isHorizontal ? null : pane1Size,
              child: _buildPane(widget.leftFile, 'Left Pane'),
            ),
            MouseRegion(
              cursor: isHorizontal
                  ? SystemMouseCursors.resizeColumn
                  : SystemMouseCursors.resizeRow,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    if (isHorizontal) {
                      _dividerPosition =
                          (_dividerPosition * maxSize + details.delta.dx) /
                              maxSize;
                    } else {
                      _dividerPosition =
                          (_dividerPosition * maxSize + details.delta.dy) /
                              maxSize;
                    }
                    _dividerPosition = _dividerPosition.clamp(0.2, 0.8);
                  });
                },
                onPanEnd: (_) {
                  widget.onModeChanged(
                      widget.mode.copyWith(dividerPosition: _dividerPosition));
                },
                child: Container(
                  width: isHorizontal ? 8 : null,
                  height: isHorizontal ? null : 8,
                  color: Theme.of(context).dividerColor,
                  child: Center(
                    child: Container(
                      width: isHorizontal ? 2 : 40,
                      height: isHorizontal ? 40 : 2,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: isHorizontal ? pane2Size : null,
              height: isHorizontal ? null : pane2Size,
              child: _buildPane(widget.rightFile, 'Right Pane'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPane(FileItem? file, String paneName) {
    if (file == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No file selected for $paneName',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.5),
                  ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    file.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: () => _showFullFilePreview(file),
                  tooltip: 'View details',
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection('File Information', [
                    _buildInfoRow('Size', _formatFileSize(file.fileSize ?? 0)),
                    _buildInfoRow('Duration', file.duration ?? 'Unknown'),
                    _buildInfoRow(
                        'Format', p.extension(file.path).toUpperCase()),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection('Video Tracks', [
                    _buildInfoRow('Count', '${file.videoTracks.length}'),
                    ...file.videoTracks.map((track) => _buildInfoRow(
                          'Video ${track.position + 1}',
                          '${track.codec} (${track.language})',
                        )),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection('Audio Tracks', [
                    _buildInfoRow('Count', '${file.audioTracks.length}'),
                    ...file.audioTracks.map((track) => _buildInfoRow(
                          'Audio ${track.position + 1}',
                          '${track.codec} - ${track.title ?? track.language}',
                        )),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection('Subtitle Tracks', [
                    _buildInfoRow('Count', '${file.subtitleTracks.length}'),
                    ...file.subtitleTracks.map((track) => _buildInfoRow(
                          'Subtitle ${track.position + 1}',
                          '${track.codec} - ${track.title ?? track.language}',
                        )),
                  ]),
                ],
              ),
            ),
          ),
          // Differences toggle
          if (widget.mode.showDifferences)
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.compare_arrows, size: 16),
                  SizedBox(width: 8),
                  Text('Differences highlighted'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _showFullFilePreview(FileItem file) {
    showDialog(
      context: context,
      builder: (context) => FilePreviewDialog(fileItem: file),
    );
  }
}

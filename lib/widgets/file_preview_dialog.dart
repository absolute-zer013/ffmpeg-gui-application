import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../models/file_item.dart';
import '../utils/file_utils.dart';

/// Dialog for previewing file information before export
///
/// Shows detailed information about the video file including:
/// - File size and duration
/// - Video, audio, and subtitle tracks
/// - Codec information
/// - Metadata
class FilePreviewDialog extends StatelessWidget {
  final FileItem fileItem;

  const FilePreviewDialog({
    super.key,
    required this.fileItem,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 600,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'File Preview',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fileItem.name,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFileInfo(context),
                    const SizedBox(height: 16),
                    _buildVideoTracksSection(context),
                    const SizedBox(height: 16),
                    _buildAudioTracksSection(context),
                    const SizedBox(height: 16),
                    _buildSubtitleTracksSection(context),
                    if (fileItem.fileMetadata != null) ...[
                      const SizedBox(height: 16),
                      _buildMetadataSection(context),
                    ],
                  ],
                ),
              ),
            ),

            // Footer with action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openFileLocation(context),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Open Location'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfo(BuildContext context) {
    final file = File(fileItem.path);
    final fileExists = file.existsSync();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Path', fileItem.path),
            // Removed duplicate name row to avoid duplicating file name in UI (header already shows name)
            if (fileItem.fileSize != null)
              _buildInfoRow('Size', FileUtils.formatBytes(fileItem.fileSize!)),
            if (fileItem.duration != null)
              _buildInfoRow('Duration', fileItem.duration!),
            _buildInfoRow(
                'Format', path.extension(fileItem.path).toUpperCase()),
            _buildInfoRow('Status', fileExists ? 'Available' : 'Not Found',
                valueColor: fileExists ? Colors.green : Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTracksSection(BuildContext context) {
    if (fileItem.videoTracks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Video Tracks (${fileItem.videoTracks.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...fileItem.videoTracks.map((track) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Track ${track.position + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      if (track.codec != null)
                        _buildInfoRow('Codec', track.codec!),
                      if (track.width != null && track.height != null)
                        _buildInfoRow(
                            'Resolution', '${track.width}x${track.height}'),
                      if (track.description.isNotEmpty)
                        _buildInfoRow('Description', track.description),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioTracksSection(BuildContext context) {
    if (fileItem.audioTracks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audio Tracks (${fileItem.audioTracks.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...fileItem.audioTracks.map((track) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Track ${track.position + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          if (fileItem.selectedAudio.contains(track.position))
                            const Chip(
                              label: Text('Selected',
                                  style: TextStyle(fontSize: 11)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          if (fileItem.defaultAudio == track.position)
                            const Chip(
                              label: Text('Default',
                                  style: TextStyle(fontSize: 11)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildInfoRow('Language', track.language),
                      if (track.codec != null)
                        _buildInfoRow('Codec', track.codec!),
                      if (track.channels != null)
                        _buildInfoRow('Channels', track.channels.toString()),
                      if (track.description.isNotEmpty)
                        _buildInfoRow('Description', track.description),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitleTracksSection(BuildContext context) {
    if (fileItem.subtitleTracks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subtitle Tracks (${fileItem.subtitleTracks.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...fileItem.subtitleTracks.map((track) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Track ${track.position + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          if (fileItem.selectedSubtitles
                              .contains(track.position))
                            const Chip(
                              label: Text('Selected',
                                  style: TextStyle(fontSize: 11)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          if (fileItem.defaultSubtitle == track.position)
                            const Chip(
                              label: Text('Default',
                                  style: TextStyle(fontSize: 11)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildInfoRow('Language', track.language),
                      if (track.codec != null)
                        _buildInfoRow('Codec', track.codec!),
                      if (track.description.isNotEmpty)
                        _buildInfoRow('Description', track.description),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    final metadata = fileItem.fileMetadata!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metadata',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (metadata.title != null) _buildInfoRow('Title', metadata.title!),
            if (metadata.artist != null)
              _buildInfoRow('Artist', metadata.artist!),
            if (metadata.album != null) _buildInfoRow('Album', metadata.album!),
            if (metadata.date != null) _buildInfoRow('Date', metadata.date!),
            if (metadata.genre != null) _buildInfoRow('Genre', metadata.genre!),
            if (metadata.comment != null)
              _buildInfoRow('Comment', metadata.comment!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  void _openFileLocation(BuildContext context) async {
    try {
      final directory = path.dirname(fileItem.path);
      if (Platform.isWindows) {
        await Process.run('explorer', [directory]);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open location: $e')),
        );
      }
    }
  }
}

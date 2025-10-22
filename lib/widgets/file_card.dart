import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../models/quality_preset.dart';
import '../utils/file_utils.dart';
import 'metadata_editor_dialog.dart';
import 'codec_settings_dialog.dart';
import 'file_preview_dialog.dart';

/// Widget for displaying a file card with track selections
class FileCard extends StatelessWidget {
  final FileItem item;
  final VoidCallback onChanged;

  const FileCard({
    super.key,
    required this.item,
    required this.onChanged,
  });

  void _showMetadataEditor(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MetadataEditorDialog(item: item),
    );

    if (result == true) {
      onChanged();
    }
  }

  void _showQualitySettings(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => CodecSettingsDialog(
        initialVideoCodec: null,
        initialQualityPreset: item.qualityPreset,
        isVideoTrack: true,
      ),
    );

    if (result != null) {
      item.qualityPreset = result['qualityPreset'] as QualityPreset?;
      onChanged();
    }
  }

  void _showPreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => FilePreviewDialog(fileItem: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusIcon = item.exportStatus == 'completed'
        ? const Icon(Icons.check_circle, color: Colors.green)
        : item.exportStatus == 'failed'
            ? const Icon(Icons.error, color: Colors.red)
            : item.exportStatus == 'processing'
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : item.exportStatus == 'cancelled'
                    ? const Icon(Icons.cancel, color: Colors.orange)
                    : const Icon(Icons.pending, color: Colors.grey);

    return Card(
      child: ExpansionTile(
        initiallyExpanded: item.isExpanded,
        onExpansionChanged: (expanded) {
          item.isExpanded = expanded;
          onChanged();
        },
        leading: statusIcon,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.qualityPreset != null)
              Chip(
                label: Text(item.qualityPreset!.name,
                    style: const TextStyle(fontSize: 11)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showPreview(context),
              tooltip: 'Preview',
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () => _showQualitySettings(context),
              tooltip: 'Quality Settings',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showMetadataEditor(context),
              tooltip: 'Edit Metadata',
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(text: item.outputName),
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  labelText: 'Output filename',
                ),
                onChanged: (value) {
                  item.outputName = value;
                  onChanged();
                },
              ),
            ),
            if (item.exportProgress > 0 && item.exportProgress < 1) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: LinearProgressIndicator(value: item.exportProgress),
              ),
              const SizedBox(width: 8),
              Text('${(item.exportProgress * 100).toInt()}%'),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${item.name} ${item.fileSize != null ? "• ${FileUtils.formatBytes(item.fileSize!)}" : ""} ${item.duration != null ? "• ${item.duration}" : ""}'),
            if (item.verificationPassed != null)
              Row(
                children: [
                  Icon(
                    item.verificationPassed! ? Icons.verified : Icons.warning,
                    size: 16,
                    color:
                        item.verificationPassed! ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.verificationMessage ?? 'Verification completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: item.verificationPassed!
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video
                if (item.videoTracks.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Video',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        for (final track in item.videoTracks)
                          CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(track.description,
                                style: const TextStyle(fontSize: 12)),
                            value: item.selectedVideo.contains(track.position),
                            onChanged: (value) {
                              if (value == true) {
                                item.selectedVideo.add(track.position);
                              } else {
                                item.selectedVideo.remove(track.position);
                              }
                              onChanged();
                            },
                          ),
                      ],
                    ),
                  ),
                if (item.videoTracks.isNotEmpty) const SizedBox(width: 16),
                // Audio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Audio',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      if (item.audioTracks.isEmpty) const Text('No audio'),
                      for (final track in item.audioTracks)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(track.description,
                              style: const TextStyle(fontSize: 12)),
                          value: item.selectedAudio.contains(track.position),
                          onChanged: (value) {
                            if (value == true) {
                              item.selectedAudio.add(track.position);
                            } else {
                              item.selectedAudio.remove(track.position);
                            }
                            onChanged();
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Subtitles
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Subtitles',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      if (item.subtitleTracks.isEmpty)
                        const Text('No subtitles'),
                      for (final track in item.subtitleTracks)
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(track.description,
                                    style: const TextStyle(fontSize: 12)),
                                value: item.selectedSubtitles
                                    .contains(track.position),
                                onChanged: (value) {
                                  if (value == true) {
                                    item.selectedSubtitles.add(track.position);
                                    item.defaultSubtitle ??= track.position;
                                  } else {
                                    item.selectedSubtitles
                                        .remove(track.position);
                                    if (item.defaultSubtitle ==
                                        track.position) {
                                      item.defaultSubtitle =
                                          item.selectedSubtitles.isNotEmpty
                                              ? item.selectedSubtitles.first
                                              : null;
                                    }
                                  }
                                  onChanged();
                                },
                              ),
                            ),
                            Checkbox(
                              value: item.defaultSubtitle == track.position,
                              onChanged: (value) {
                                if (value == true) {
                                  item.selectedSubtitles.add(track.position);
                                  item.defaultSubtitle = track.position;
                                } else {
                                  if (item.defaultSubtitle == track.position) {
                                    item.defaultSubtitle = null;
                                  }
                                }
                                onChanged();
                              },
                            ),
                            const Text('Default',
                                style: TextStyle(fontSize: 10)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

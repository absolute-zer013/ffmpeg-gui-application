import 'package:flutter/material.dart';
import '../models/file_item.dart';
// Quality presets no longer edited via the video dialog here.
import '../models/codec_options.dart';
import '../utils/file_utils.dart';
import 'metadata_editor_dialog.dart';
import 'codec_settings_dialog.dart';
import 'file_preview_dialog.dart';

/// Widget for displaying a file card with track selections
class FileCard extends StatelessWidget {
  final FileItem item;
  final VoidCallback onChanged;
  final String? outputFormat; // Container format for codec filtering
  final bool autoFixEnabled; // If true, filter incompatible codecs

  const FileCard({
    super.key,
    required this.item,
    required this.onChanged,
    this.outputFormat,
    this.autoFixEnabled = false,
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

  void _showVideoCodecSettings(BuildContext context) async {
    // Fetch the current video codec settings for the first video track (if any)
    VideoCodec? savedCodec;
    if (item.videoTracks.isNotEmpty) {
      final firstTrackIdx = item.videoTracks.first.streamIndex;
      final saved = item.codecSettings[firstTrackIdx];
      if (saved != null) {
        savedCodec = saved.videoCodec;
      }
    }

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => CodecSettingsDialog(
        initialVideoCodec: savedCodec,
        isVideoTrack: true,
        outputFormat: outputFormat,
        autoFixEnabled: autoFixEnabled,
      ),
    );

    if (result != null) {
      final settings = result['codecSettings'] as CodecConversionSettings?;
      if (settings?.videoCodec != null) {
        for (final track in item.videoTracks) {
          item.codecSettings[track.streamIndex] = CodecConversionSettings(
            videoCodec: settings!.videoCodec,
          );
        }
        onChanged();
      }
    }
  }

  void _showAudioCodecSettings(BuildContext context) async {
    // Fetch the current audio codec settings for the first audio track (if any)
    AudioCodec? savedCodec;
    int? savedBitrate;
    int? savedChannels;
    int? savedSampleRate;
    if (item.audioTracks.isNotEmpty) {
      final firstTrackIdx = item.audioTracks.first.streamIndex;
      final saved = item.codecSettings[firstTrackIdx];
      if (saved != null) {
        savedCodec = saved.audioCodec;
        savedBitrate = saved.audioBitrate;
        savedChannels = saved.audioChannels;
        savedSampleRate = saved.audioSampleRate;
      }
    }

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => CodecSettingsDialog(
        initialAudioCodec: savedCodec,
        initialAudioBitrate: savedBitrate,
        initialAudioChannels: savedChannels,
        initialAudioSampleRate: savedSampleRate,
        isVideoTrack: false,
        showBatchOptions: false,
        outputFormat: outputFormat,
        autoFixEnabled: autoFixEnabled,
      ),
    );

    if (result != null) {
      final settings = result['codecSettings'] as CodecConversionSettings?;
      if (settings != null) {
        // Apply to all audio tracks in this file
        for (final track in item.audioTracks) {
          item.codecSettings[track.streamIndex] = CodecConversionSettings(
            audioCodec: settings.audioCodec,
            audioBitrate: settings.audioBitrate,
            audioChannels: settings.audioChannels,
            audioSampleRate: settings.audioSampleRate,
          );
        }
        onChanged();
      }
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
              icon: const Icon(Icons.video_settings),
              onPressed: () => _showVideoCodecSettings(context),
              tooltip: 'Video Codec',
            ),
            IconButton(
              icon: const Icon(Icons.audio_file),
              onPressed: () => _showAudioCodecSettings(context),
              tooltip: 'Audio Codec',
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
                        Column(
                          children: [
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
                            if (item.selectedSubtitles.contains(track.position))
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                                child: Row(
                                  children: [
                                    const Text('Format: ', style: TextStyle(fontSize: 11)),
                                    DropdownButton<SubtitleFormat>(
                                      value: item.codecSettings[track.streamIndex]
                                              ?.subtitleFormat ??
                                          SubtitleFormat.copy,
                                      isDense: true,
                                      style: const TextStyle(fontSize: 11),
                                      onChanged: (newFormat) {
                                        if (newFormat != null) {
                                          final currentSettings =
                                              item.codecSettings[track.streamIndex] ??
                                                  CodecConversionSettings();
                                          item.codecSettings[track.streamIndex] =
                                              currentSettings.copyWith(
                                                  subtitleFormat: newFormat);
                                          onChanged();
                                        }
                                      },
                                      items: SubtitleFormat.values
                                          .map((format) => DropdownMenuItem(
                                                value: format,
                                                child: Tooltip(
                                                  message: format.description,
                                                  child: Text(format.displayName),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
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

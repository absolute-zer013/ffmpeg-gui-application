import 'package:flutter/material.dart';
import '../models/file_item.dart';
// Quality presets no longer edited via the video dialog here.
import '../models/codec_options.dart';
import '../utils/file_utils.dart';
import 'metadata_editor_dialog.dart';
import 'codec_settings_dialog.dart';
import 'file_preview_dialog.dart';
import 'trim_settings_dialog.dart';
import 'resolution_settings_dialog.dart';
import 'sync_offset_dialog.dart';

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

  void _showTrimSettings(BuildContext context) async {
    final result = await showDialog<TrimSettings>(
      context: context,
      builder: (context) => TrimSettingsDialog(
        initialSettings: item.trimSettings,
        fileDuration: item.duration,
      ),
    );

    if (result != null) {
      item.trimSettings = result;
      onChanged();
    }
  }

  void _showResolutionSettings(BuildContext context) async {
    // Extract original width/height from video tracks
    int? width;
    int? height;
    if (item.videoTracks.isNotEmpty) {
      final firstVideo = item.videoTracks.first;
      // Parse resolution from codec info if available (e.g., "1920x1080")
      final codec = firstVideo.codec ?? '';
      final resMatch = RegExp(r'(\d+)x(\d+)').firstMatch(codec);
      if (resMatch != null) {
        width = int.tryParse(resMatch.group(1)!);
        height = int.tryParse(resMatch.group(2)!);
      }
    }

    final result = await showDialog<ResolutionSettings>(
      context: context,
      builder: (context) => ResolutionSettingsDialog(
        initialSettings: item.resolutionSettings,
        originalWidth: width,
        originalHeight: height,
      ),
    );

    if (result != null) {
      item.resolutionSettings = result;
      onChanged();
    }
  }

  void _showSyncOffsets(BuildContext context) async {
    final result = await showDialog<List<SyncOffset>>(
      context: context,
      builder: (context) => SyncOffsetDialog(
        audioTracks: item.audioTracks,
        subtitleTracks: item.subtitleTracks,
        initialOffsets: item.syncOffsets,
      ),
    );

    if (result != null) {
      item.syncOffsets = result;
      onChanged();
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
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
            // New Tier 2 feature indicators
            if (item.trimSettings?.enabled == true)
              Tooltip(
                message: item.trimSettings.toString(),
                child: const Chip(
                  label: Icon(Icons.content_cut, size: 14),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            if (item.resolutionSettings?.enabled == true)
              Tooltip(
                message: item.resolutionSettings.toString(),
                child: const Chip(
                  label: Icon(Icons.aspect_ratio, size: 14),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            if (item.syncOffsets != null && item.syncOffsets!.isNotEmpty)
              Tooltip(
                message: '${item.syncOffsets!.length} sync offset(s)',
                child: const Chip(
                  label: Icon(Icons.sync, size: 14),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More options',
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'preview',
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Preview'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'trim',
                  child: ListTile(
                    leading: Icon(Icons.content_cut),
                    title: Text('Trim/Cut'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'resolution',
                  child: ListTile(
                    leading: Icon(Icons.aspect_ratio),
                    title: Text('Resolution/Framerate'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'sync',
                  child: ListTile(
                    leading: Icon(Icons.sync),
                    title: Text('Audio/Subtitle Sync'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'video',
                  child: ListTile(
                    leading: Icon(Icons.video_settings),
                    title: Text('Video Codec'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'audio',
                  child: ListTile(
                    leading: Icon(Icons.audio_file),
                    title: Text('Audio Codec'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'metadata',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit Metadata'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'preview':
                    _showPreview(context);
                    break;
                  case 'trim':
                    _showTrimSettings(context);
                    break;
                  case 'resolution':
                    _showResolutionSettings(context);
                    break;
                  case 'sync':
                    _showSyncOffsets(context);
                    break;
                  case 'video':
                    _showVideoCodecSettings(context);
                    break;
                  case 'audio':
                    _showAudioCodecSettings(context);
                    break;
                  case 'metadata':
                    _showMetadataEditor(context);
                    break;
                }
              },
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
              if (item.estimatedTimeRemaining != null) ...[
                const SizedBox(width: 8),
                Text(
                  'ETA: ${_formatDuration(item.estimatedTimeRemaining!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
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

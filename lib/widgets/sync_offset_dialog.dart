import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sync_offset.dart';
import '../models/track.dart';

/// Dialog for configuring audio/subtitle sync offsets (Feature #17)
class SyncOffsetDialog extends StatefulWidget {
  final List<Track> audioTracks;
  final List<Track> subtitleTracks;
  final List<SyncOffset>? initialOffsets;

  const SyncOffsetDialog({
    super.key,
    required this.audioTracks,
    required this.subtitleTracks,
    this.initialOffsets,
  });

  @override
  State<SyncOffsetDialog> createState() => _SyncOffsetDialogState();
}

class _SyncOffsetDialogState extends State<SyncOffsetDialog> {
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, int> _offsets = {}; // streamIndex -> offsetMs

  @override
  void initState() {
    super.initState();

    // Initialize controllers for all tracks
    for (final track in [...widget.audioTracks, ...widget.subtitleTracks]) {
      _controllers[track.streamIndex] = TextEditingController();
      _offsets[track.streamIndex] = 0;
    }

    // Load initial offsets if provided
    if (widget.initialOffsets != null) {
      for (final offset in widget.initialOffsets!) {
        if (_controllers.containsKey(offset.streamIndex)) {
          _controllers[offset.streamIndex]!.text = offset.offsetMs.toString();
          _offsets[offset.streamIndex] = offset.offsetMs;
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateOffset(int streamIndex, String value) {
    setState(() {
      _offsets[streamIndex] = int.tryParse(value) ?? 0;
    });
  }

  String _formatOffset(int offsetMs) {
    if (offsetMs == 0) return '0ms';
    final absMs = offsetMs.abs();
    final seconds = (absMs / 1000).floor();
    final ms = absMs % 1000;
    final sign = offsetMs >= 0 ? '+' : '-';

    if (seconds > 0) {
      return '$sign${seconds}s ${ms}ms';
    } else {
      return '$sign${ms}ms';
    }
  }

  List<SyncOffset> _buildOffsets() {
    final offsets = <SyncOffset>[];

    for (final track in widget.audioTracks) {
      final offsetMs = _offsets[track.streamIndex] ?? 0;
      if (offsetMs != 0) {
        offsets.add(SyncOffset(
          streamIndex: track.streamIndex,
          offsetMs: offsetMs,
          streamType: 'audio',
          trackDescription: track.title ?? 'Audio #${track.position}',
        ));
      }
    }

    for (final track in widget.subtitleTracks) {
      final offsetMs = _offsets[track.streamIndex] ?? 0;
      if (offsetMs != 0) {
        offsets.add(SyncOffset(
          streamIndex: track.streamIndex,
          offsetMs: offsetMs,
          streamType: 'subtitle',
          trackDescription: track.title ?? 'Subtitle #${track.position}',
        ));
      }
    }

    return offsets;
  }

  Widget _buildTrackOffset(Track track, String type) {
    final streamIndex = track.streamIndex;
    final controller = _controllers[streamIndex]!;
    final currentOffset = _offsets[streamIndex] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  type == 'audio' ? Icons.audiotrack : Icons.subtitles,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    track.title ?? '$type #${track.position}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (track.language.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Language: ${track.language}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Offset (milliseconds)',
                      hintText: '0',
                      helperText: 'Positive = delay, Negative = advance',
                      border: OutlineInputBorder(),
                      isDense: true,
                      suffixText: 'ms',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(signed: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                    ],
                    onChanged: (value) => _updateOffset(streamIndex, value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preview:',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatOffset(currentOffset),
                        style: TextStyle(
                          fontSize: 14,
                          color: currentOffset == 0
                              ? Colors.grey
                              : (currentOffset > 0
                                  ? Colors.orange
                                  : Colors.blue),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    controller.text = (currentOffset - 100).toString();
                    _updateOffset(streamIndex, controller.text);
                  },
                  icon: const Icon(Icons.remove, size: 16),
                  label: const Text('100ms'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () {
                    controller.text = (currentOffset + 100).toString();
                    _updateOffset(streamIndex, controller.text);
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('100ms'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: currentOffset != 0
                      ? () {
                          controller.clear();
                          _updateOffset(streamIndex, '0');
                        }
                      : null,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAudio = widget.audioTracks.isNotEmpty;
    final hasSubtitles = widget.subtitleTracks.isNotEmpty;

    return AlertDialog(
      title: const Text('Audio/Subtitle Sync'),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adjust timing offsets for out-of-sync tracks. '
                'Positive values delay the track, negative values advance it.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (hasAudio) ...[
                const Text(
                  'Audio Tracks',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...widget.audioTracks.map((track) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildTrackOffset(track, 'audio'),
                    )),
              ],
              if (hasAudio && hasSubtitles) const SizedBox(height: 16),
              if (hasSubtitles) ...[
                const Text(
                  'Subtitle Tracks',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...widget.subtitleTracks.map((track) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildTrackOffset(track, 'subtitle'),
                    )),
              ],
              if (!hasAudio && !hasSubtitles) ...[
                const Center(
                  child: Text(
                    'No audio or subtitle tracks available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final offsets = _buildOffsets();
            Navigator.of(context).pop(offsets);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

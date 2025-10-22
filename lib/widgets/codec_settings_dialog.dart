import 'package:flutter/material.dart';
import '../models/codec_options.dart';
import '../models/quality_preset.dart';

/// Dialog for selecting codec conversion options
class CodecSettingsDialog extends StatefulWidget {
  final VideoCodec? initialVideoCodec;
  final AudioCodec? initialAudioCodec;
  final int? initialAudioBitrate;
  final int? initialAudioChannels;
  final int? initialAudioSampleRate;
  final QualityPreset? initialQualityPreset;
  final bool isVideoTrack;
  final bool showBatchOptions;
  final int? fileCount;

  const CodecSettingsDialog({
    super.key,
    this.initialVideoCodec,
    this.initialAudioCodec,
    this.initialAudioBitrate,
    this.initialAudioChannels,
    this.initialAudioSampleRate,
    this.initialQualityPreset,
    this.isVideoTrack = false,
    this.showBatchOptions = false,
    this.fileCount,
  });

  @override
  State<CodecSettingsDialog> createState() => _CodecSettingsDialogState();
}

class _CodecSettingsDialogState extends State<CodecSettingsDialog> {
  late VideoCodec? _selectedVideoCodec;
  late AudioCodec? _selectedAudioCodec;
  late int? _audioBitrate;
  late int? _audioChannels;
  late int? _audioSampleRate;
  late QualityPreset? _qualityPreset;

  @override
  void initState() {
    super.initState();
    _selectedVideoCodec = widget.initialVideoCodec ?? VideoCodec.copy;
    _selectedAudioCodec = widget.initialAudioCodec ?? AudioCodec.copy;
    _audioBitrate = widget.initialAudioBitrate;
    _audioChannels = widget.initialAudioChannels;
    _audioSampleRate = widget.initialAudioSampleRate;
    _qualityPreset = widget.initialQualityPreset;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.showBatchOptions
        ? 'Batch ${widget.isVideoTrack ? 'Video' : 'Audio'} Codec Settings (${widget.fileCount ?? 0} files)'
        : (widget.isVideoTrack
            ? 'Video Codec Settings'
            : 'Audio Codec Settings');

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isVideoTrack) ...[
              const Text(
                'Video Codec',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Two-column side-by-side Video Codec options using Table, responsive to screen width
              Builder(builder: (context) {
                final isNarrow = MediaQuery.of(context).size.width < 520;
                final colCount = isNarrow ? 1 : 2;
                final videoCodecTiles = <Widget>[
                  for (final codec in VideoCodec.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 8),
                      child: RadioListTile<VideoCodec>(
                        title: Text(codec.displayName),
                        subtitle: Text(
                          codec.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        value: codec,
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                        // ignore: deprecated_member_use
                        groupValue: _selectedVideoCodec,
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          setState(() {
                            _selectedVideoCodec = value;
                          });
                        },
                      ),
                    ),
                ];

                final rows = <TableRow>[];
                for (var i = 0; i < videoCodecTiles.length; i += colCount) {
                  final rowChildren = <Widget>[];
                  for (var j = 0; j < colCount; j++) {
                    final idx = i + j;
                    rowChildren.add(
                      idx < videoCodecTiles.length
                          ? videoCodecTiles[idx]
                          : const SizedBox.shrink(),
                    );
                  }
                  rows.add(TableRow(children: rowChildren));
                }

                return Table(
                  columnWidths: {
                    for (var c = 0; c < colCount; c++)
                      c: const FlexColumnWidth(1),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: rows,
                );
              }),
              const Divider(),
              const SizedBox(height: 8),

              const Text(
                'Audio Quality',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose an audio quality preset for consistent results. It adjusts encoding parameters (CRF, preset speed, audio bitrate).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              // Two-column options using Table (intrinsics-safe for AlertDialog), responsive to screen width
              Builder(builder: (context) {
                final isNarrow = MediaQuery.of(context).size.width < 520;
                final colCount = isNarrow ? 1 : 2;
                // Build all tiles first
                final tiles = <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 8),
                    child: RadioListTile<QualityPreset?>(
                      title: const Text('None'),
                      subtitle: Text(
                        'No audio quality preset applied',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      value: null,
                      visualDensity: VisualDensity.compact,
                      contentPadding: EdgeInsets.zero,
                      // ignore: deprecated_member_use
                      groupValue: _qualityPreset,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        setState(() {
                          _qualityPreset = value;
                        });
                      },
                    ),
                  ),
                  for (final preset in QualityPreset.predefinedPresets)
                    Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 8),
                      child: RadioListTile<QualityPreset?>(
                        title: Text(preset.name),
                        subtitle: Text(
                          [
                            preset.description,
                            if (preset.crf != null) '• CRF ${preset.crf}',
                            if (preset.preset != null)
                              '• preset ${preset.preset}',
                            if (preset.audioBitrate != null)
                              '• ${preset.audioBitrate}k audio',
                          ].join('\n'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        value: preset,
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                        // ignore: deprecated_member_use
                        groupValue: _qualityPreset,
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          setState(() {
                            _qualityPreset = value;
                          });
                        },
                      ),
                    ),
                ];

                // Chunk tiles into rows of colCount
                final rows = <TableRow>[];
                for (var i = 0; i < tiles.length; i += colCount) {
                  final rowChildren = <Widget>[];
                  for (var j = 0; j < colCount; j++) {
                    final idx = i + j;
                    rowChildren.add(
                      idx < tiles.length ? tiles[idx] : const SizedBox.shrink(),
                    );
                  }
                  rows.add(TableRow(children: rowChildren));
                }

                return Table(
                  columnWidths: {
                    for (var c = 0; c < colCount; c++)
                      c: const FlexColumnWidth(1),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: rows,
                );
              }),

              if (_qualityPreset != null) ...[
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_qualityPreset!.crf != null)
                          Text('CRF: ${_qualityPreset!.crf}'),
                        if (_qualityPreset!.preset != null)
                          Text('Preset: ${_qualityPreset!.preset}'),
                        if (_qualityPreset!.audioBitrate != null)
                          Text(
                              'Audio Bitrate: ${_qualityPreset!.audioBitrate}k'),
                      ],
                    ),
                  ),
                ),
              ],
            ] else ...[
              const Text(
                'Audio Codec',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Two-column side-by-side Audio Codec options using Table, responsive to screen width
              Builder(builder: (context) {
                final isNarrow = MediaQuery.of(context).size.width < 520;
                final colCount = isNarrow ? 1 : 2;
                final codecTiles = <Widget>[
                  for (final codec in AudioCodec.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 8),
                      child: RadioListTile<AudioCodec>(
                        title: Text(codec.displayName),
                        subtitle: Text(
                          codec.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        value: codec,
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                        // ignore: deprecated_member_use
                        groupValue: _selectedAudioCodec,
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          setState(() {
                            _selectedAudioCodec = value;
                          });
                        },
                      ),
                    ),
                ];

                final rows = <TableRow>[];
                for (var i = 0; i < codecTiles.length; i += colCount) {
                  final rowChildren = <Widget>[];
                  for (var j = 0; j < colCount; j++) {
                    final idx = i + j;
                    rowChildren.add(
                      idx < codecTiles.length
                          ? codecTiles[idx]
                          : const SizedBox.shrink(),
                    );
                  }
                  rows.add(TableRow(children: rowChildren));
                }

                return Table(
                  columnWidths: {
                    for (var c = 0; c < colCount; c++)
                      c: const FlexColumnWidth(1),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: rows,
                );
              }),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Audio Settings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _audioBitrate?.toString() ?? '',
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Bitrate (kbps)',
                  hintText: 'e.g., 192',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _audioBitrate = int.tryParse(value);
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                // ignore: deprecated_member_use
                value: _audioChannels,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Channels',
                ),
                items: const [
                  DropdownMenuItem<int?>(value: null, child: Text('Auto')),
                  DropdownMenuItem<int?>(value: 1, child: Text('1 (Mono)')),
                  DropdownMenuItem<int?>(value: 2, child: Text('2 (Stereo)')),
                  DropdownMenuItem<int?>(
                      value: 6, child: Text('6 (5.1 Surround)')),
                  DropdownMenuItem<int?>(
                      value: 8, child: Text('8 (7.1 Surround)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _audioChannels = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                // ignore: deprecated_member_use
                value: _audioSampleRate,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Sample Rate (Hz)',
                ),
                items: const [
                  DropdownMenuItem<int?>(value: null, child: Text('Auto')),
                  DropdownMenuItem<int?>(value: 44100, child: Text('44100 Hz')),
                  DropdownMenuItem<int?>(value: 48000, child: Text('48000 Hz')),
                  DropdownMenuItem<int?>(value: 96000, child: Text('96000 Hz')),
                ],
                onChanged: (value) {
                  setState(() {
                    _audioSampleRate = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final settings = CodecConversionSettings(
              videoCodec: widget.isVideoTrack ? _selectedVideoCodec : null,
              audioCodec: !widget.isVideoTrack ? _selectedAudioCodec : null,
              audioBitrate: _audioBitrate,
              audioChannels: _audioChannels,
              audioSampleRate: _audioSampleRate,
            );
            Navigator.pop(context, {
              'codecSettings': settings,
              'qualityPreset': _qualityPreset,
              'applyToAll': widget.showBatchOptions,
            });
          },
          child: Text(widget.showBatchOptions ? 'Apply to All' : 'Apply'),
        ),
      ],
    );
  }
}

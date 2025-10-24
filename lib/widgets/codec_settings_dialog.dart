import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/codec_options.dart';
// FFmpeg capability listing is no longer used in this dialog.
// Quality presets are handled in dedicated menus; not used here.

/// Dialog for selecting codec conversion options
class CodecSettingsDialog extends StatefulWidget {
  final VideoCodec? initialVideoCodec;
  final AudioCodec? initialAudioCodec;
  final int? initialAudioBitrate;
  final int? initialAudioChannels;
  final int? initialAudioSampleRate;
  final bool isVideoTrack;
  final bool showBatchOptions;
  final int? fileCount;
  final String? outputFormat; // e.g., 'mp4', 'webm', 'mkv' for filtering
  final bool
      autoFixEnabled; // if true and container incompatible, hide unsupported codecs

  const CodecSettingsDialog({
    super.key,
    this.initialVideoCodec,
    this.initialAudioCodec,
    this.initialAudioBitrate,
    this.initialAudioChannels,
    this.initialAudioSampleRate,
    this.isVideoTrack = false,
    this.showBatchOptions = false,
    this.fileCount,
    this.outputFormat,
    this.autoFixEnabled = false,
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
  String? _customVideoCodec; // used by Quick AV1 presets to pick encoder lib
  // Advanced video params (used notably for AV1 quick presets)
  int? _videoCrf;
  String?
      _videoPreset; // For libsvtav1 uses numeric string; for libaom-av1 maps to cpu-used
  int? _videoBitrateKbps;
  // Quick AV1 helpers
  String _av1Encoder = 'libsvtav1'; // default recommended
  String _av1Profile = 'Balanced'; // Speed | Balanced | Quality
  bool _av1Touched = false; // user interacted with quick AV1 controls

  @override
  void initState() {
    super.initState();
    _selectedVideoCodec = widget.initialVideoCodec ?? VideoCodec.copy;
    _selectedAudioCodec = widget.initialAudioCodec ?? AudioCodec.copy;
    _audioBitrate = widget.initialAudioBitrate;
    _audioChannels = widget.initialAudioChannels;
    _audioSampleRate = widget.initialAudioSampleRate;
    // Precompute the Balanced defaults so the summary shows proper values on open.
    // Do not mark as touched; we won't set a custom encoder until the user interacts.
    _applyAv1Profile();
  }

  /// Returns true if a video codec is compatible with the output container.
  /// Used to filter codec options when auto-fix is enabled.
  bool _isVideoCodecCompatible(VideoCodec codec) {
    if (!widget.autoFixEnabled || widget.outputFormat == null) {
      return true;
    }
    final fmt = widget.outputFormat!.toLowerCase();
    if (fmt == 'mkv' || fmt == 'mka' || fmt == 'mks') {
      return true; // MKV accepts all
    }

    if (fmt == 'mp4' || fmt == 'm4v' || fmt == 'mov') {
      // MP4 allows: copy, h264, hevc, mpeg4, av1
      const allowed = {'copy', 'h264', 'hevc', 'h265', 'mpeg4', 'av1'};
      return allowed.contains(codec.ffmpegName.toLowerCase());
    } else if (fmt == 'webm') {
      // WebM allows: copy, vp9, av1 (vp8 possible but less common)
      const allowed = {'copy', 'vp9', 'av1'};
      return allowed.contains(codec.ffmpegName.toLowerCase());
    }
    return true;
  }

  /// Returns true if an audio codec is compatible with the output container.
  bool _isAudioCodecCompatible(AudioCodec codec) {
    if (!widget.autoFixEnabled || widget.outputFormat == null) {
      return true;
    }
    final fmt = widget.outputFormat!.toLowerCase();
    if (fmt == 'mkv' || fmt == 'mka' || fmt == 'mks') {
      return true; // MKV accepts all
    }

    if (fmt == 'mp4' || fmt == 'm4v' || fmt == 'mov') {
      // MP4 allows: copy, aac, ac3, eac3, alac, mp3
      const allowed = {'copy', 'aac', 'ac3', 'eac3', 'alac', 'mp3'};
      return allowed.contains(codec.ffmpegName.toLowerCase());
    } else if (fmt == 'webm') {
      // WebM allows: copy, libvorbis, libopus
      const allowed = {'copy', 'libvorbis', 'libopus'};
      return allowed.contains(codec.ffmpegName.toLowerCase());
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVideo = widget.isVideoTrack;
    // Give the dialog a bit more breathing room but keep it responsive
    final dialogWidth = math.min(screenWidth * 0.7, isVideo ? 560.0 : 520.0);
    final title = widget.showBatchOptions
        ? 'Batch ${widget.isVideoTrack ? 'Video' : 'Audio'} Codec Settings (${widget.fileCount ?? 0} files)'
        : (widget.isVideoTrack
            ? 'Video Codec Settings'
            : 'Audio Codec Settings');

    return AlertDialog(
      title: Text(title),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
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
                  // Filter codecs based on container if auto-fix is enabled
                  final filteredCodecs = VideoCodec.values
                      .where((codec) => _isVideoCodecCompatible(codec))
                      .toList();
                  final videoCodecTiles = <Widget>[
                    for (final codec in filteredCodecs)
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
                              // Reset preset when switching codecs to avoid conflicts
                              _videoPreset = null;
                              _videoCrf = null;
                              _videoBitrateKbps = null;
                              _av1Profile = 'Balanced'; // reset AV1 profile
                              _av1Touched = false;
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
                const SizedBox(height: 8),
                // Quick AV1 presets - only show when AV1 codec is selected
                if (_selectedVideoCodec == VideoCodec.av1)
                  ExpansionTile(
                    title: const Text('Quick AV1 presets'),
                    subtitle: const Text(
                        'Set encoder + CRF + preset for good defaults'),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              // ignore: deprecated_member_use
                              value: _av1Encoder,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'AV1 encoder',
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'libsvtav1',
                                    child:
                                        Text('libsvtav1 (fast, good quality)')),
                                DropdownMenuItem(
                                    value: 'libaom-av1',
                                    child:
                                        Text('libaom-av1 (reference encoder)')),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() {
                                  _av1Encoder = v;
                                  _av1Touched = true;
                                  // Re-apply current profile mapping
                                  _applyAv1Profile();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Tooltip(
                            message:
                                'Speed: smaller encode time, smaller quality\nBalanced: recommended for general use\nQuality: better quality, slower encode',
                            child: Icon(Icons.info_outline, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Speed'),
                            selected: _av1Profile == 'Speed',
                            onSelected: (_) {
                              setState(() {
                                _av1Profile = 'Speed';
                                _av1Touched = true;
                                _applyAv1Profile();
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Balanced'),
                            selected: _av1Profile == 'Balanced',
                            onSelected: (_) {
                              setState(() {
                                _av1Profile = 'Balanced';
                                _av1Touched = true;
                                _applyAv1Profile();
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Quality'),
                            selected: _av1Profile == 'Quality',
                            onSelected: (_) {
                              setState(() {
                                _av1Profile = 'Quality';
                                _av1Touched = true;
                                _applyAv1Profile();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Applied: encoder=$_av1Encoder, CRF=${_videoCrf ?? '-'},'
                        ' preset=${_videoPreset ?? '-'}, bitrate=${_videoBitrateKbps ?? '-'}k (0 = constant quality)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                // Generic preset section for non-AV1 codecs (H.264, H.265, VP9)
                if (_selectedVideoCodec != null &&
                    _selectedVideoCodec != VideoCodec.copy &&
                    _selectedVideoCodec != VideoCodec.av1)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Encoding Presets',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Speed'),
                            selected: _videoPreset == 'fast',
                            onSelected: (_) {
                              setState(() {
                                _videoPreset = 'fast';
                                _videoCrf = 28;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Balanced'),
                            selected: _videoPreset == 'medium',
                            onSelected: (_) {
                              setState(() {
                                _videoPreset = 'medium';
                                _videoCrf = 23;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Quality'),
                            selected: _videoPreset == 'slow',
                            onSelected: (_) {
                              setState(() {
                                _videoPreset = 'slow';
                                _videoCrf = 20;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Advanced Settings',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      // CRF field
                      TextFormField(
                        initialValue: _videoCrf?.toString() ?? '',
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'CRF (0-51, lower = better quality)',
                          hintText: '23',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          setState(() {
                            _videoCrf = v.isEmpty ? null : int.tryParse(v);
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      // Preset dropdown for manual selection
                      DropdownButtonFormField<String?>(
                        initialValue: _videoPreset,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText:
                              'Manual Preset (if not using presets above)',
                          hintText: 'Select a preset',
                        ),
                        items: const [
                          DropdownMenuItem<String?>(
                              value: null, child: Text('(no preset)')),
                          DropdownMenuItem(
                              value: 'ultrafast',
                              child:
                                  Text('ultrafast (fastest, lowest quality)')),
                          DropdownMenuItem(value: 'fast', child: Text('fast')),
                          DropdownMenuItem(
                              value: 'medium',
                              child: Text('medium (recommended)')),
                          DropdownMenuItem(value: 'slow', child: Text('slow')),
                          DropdownMenuItem(
                              value: 'veryslow',
                              child: Text('veryslow (slowest, best quality)')),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _videoPreset = v;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Applied: codec=${_selectedVideoCodec?.ffmpegName ?? "?"}, CRF=${_videoCrf ?? "-"}, preset=${_videoPreset ?? "-"}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
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
                  // Filter codecs based on container if auto-fix is enabled
                  final filteredCodecs = AudioCodec.values
                      .where((codec) => _isAudioCodecCompatible(codec))
                      .toList();
                  final codecTiles = <Widget>[
                    for (final codec in filteredCodecs)
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
                    DropdownMenuItem<int?>(
                        value: 44100, child: Text('44100 Hz')),
                    DropdownMenuItem<int?>(
                        value: 48000, child: Text('48000 Hz')),
                    DropdownMenuItem<int?>(
                        value: 96000, child: Text('96000 Hz')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _audioSampleRate = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
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
              customVideoCodec: widget.isVideoTrack ? _customVideoCodec : null,
              videoCrf: widget.isVideoTrack ? _videoCrf : null,
              videoPreset: widget.isVideoTrack ? _videoPreset : null,
              videoBitrateKbps: widget.isVideoTrack ? _videoBitrateKbps : null,
            );
            Navigator.pop(context, {
              'codecSettings': settings,
              'applyToAll': widget.showBatchOptions,
            });
          },
          child: Text(widget.showBatchOptions ? 'Apply to All' : 'Apply'),
        ),
      ],
    );
  }

  void _applyAv1Profile() {
    // Map three profiles to reasonable defaults.
    // CRF lower = better quality. Bitrate 0 enables constant-quality (CQ) style.
    // libsvtav1 preset range ~0 (slowest) to 13 (fastest). We'll use strings.
    // libaom-av1 uses cpu-used 0..8; we'll reuse videoPreset as a string and map to -cpu-used in export.
    switch (_av1Profile) {
      case 'Speed':
        _videoCrf = 36;
        _videoPreset = _av1Encoder == 'libsvtav1' ? '12' : '8';
        _videoBitrateKbps = 0;
        break;
      case 'Quality':
        _videoCrf = 24;
        _videoPreset = _av1Encoder == 'libsvtav1' ? '4' : '4';
        _videoBitrateKbps = 0;
        break;
      case 'Balanced':
      default:
        _videoCrf = 30;
        _videoPreset = _av1Encoder == 'libsvtav1' ? '8' : '6';
        _videoBitrateKbps = 0;
        break;
    }
    // Only set a custom encoder if the user has interacted with the quick AV1 controls.
    if (_av1Touched) {
      _customVideoCodec = _av1Encoder; // reflect AV1 choice
    }
    // Also align curated radio to 'custom' by keeping current selection intact.
  }
}

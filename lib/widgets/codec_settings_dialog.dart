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

  const CodecSettingsDialog({
    super.key,
    this.initialVideoCodec,
    this.initialAudioCodec,
    this.initialAudioBitrate,
    this.initialAudioChannels,
    this.initialAudioSampleRate,
    this.initialQualityPreset,
    this.isVideoTrack = false,
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
    return AlertDialog(
      title: Text(widget.isVideoTrack ? 'Video Codec Settings' : 'Audio Codec Settings'),
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
              ...VideoCodec.values.map((codec) {
                return RadioListTile<VideoCodec>(
                  title: Text(codec.displayName),
                  subtitle: Text(codec.description),
                  value: codec,
                  groupValue: _selectedVideoCodec,
                  onChanged: (value) {
                    setState(() {
                      _selectedVideoCodec = value;
                    });
                  },
                );
              }),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Quality Preset',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<QualityPreset?>(
                value: _qualityPreset,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Select Quality Preset',
                ),
                items: [
                  const DropdownMenuItem<QualityPreset?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...QualityPreset.predefinedPresets.map((preset) {
                    return DropdownMenuItem<QualityPreset?>(
                      value: preset,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(preset.name),
                          Text(
                            preset.description,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _qualityPreset = value;
                  });
                },
              ),
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
                          Text('Audio Bitrate: ${_qualityPreset!.audioBitrate}k'),
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
              ...AudioCodec.values.map((codec) {
                return RadioListTile<AudioCodec>(
                  title: Text(codec.displayName),
                  subtitle: Text(codec.description),
                  value: codec,
                  groupValue: _selectedAudioCodec,
                  onChanged: (value) {
                    setState(() {
                      _selectedAudioCodec = value;
                    });
                  },
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
                value: _audioChannels,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Channels',
                ),
                items: const [
                  DropdownMenuItem<int?>(value: null, child: Text('Auto')),
                  DropdownMenuItem<int?>(value: 1, child: Text('1 (Mono)')),
                  DropdownMenuItem<int?>(value: 2, child: Text('2 (Stereo)')),
                  DropdownMenuItem<int?>(value: 6, child: Text('6 (5.1 Surround)')),
                  DropdownMenuItem<int?>(value: 8, child: Text('8 (7.1 Surround)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _audioChannels = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
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
            });
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

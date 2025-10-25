import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/resolution_settings.dart';

/// Dialog for configuring resolution and framerate settings (Feature #10)
class ResolutionSettingsDialog extends StatefulWidget {
  final ResolutionSettings? initialSettings;
  final int? originalWidth;
  final int? originalHeight;

  const ResolutionSettingsDialog({
    super.key,
    this.initialSettings,
    this.originalWidth,
    this.originalHeight,
  });

  @override
  State<ResolutionSettingsDialog> createState() =>
      _ResolutionSettingsDialogState();
}

class _ResolutionSettingsDialogState extends State<ResolutionSettingsDialog> {
  bool _enabled = false;
  String? _selectedPreset;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  double? _selectedFramerate;
  bool _customResolution = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialSettings?.enabled ?? false;
    _selectedPreset = widget.initialSettings?.presetName;
    _selectedFramerate = widget.initialSettings?.framerate;

    if (widget.initialSettings != null &&
        widget.initialSettings!.presetName == null &&
        (widget.initialSettings!.width != null ||
            widget.initialSettings!.height != null)) {
      _customResolution = true;
    }

    _widthController = TextEditingController(
      text: widget.initialSettings?.width?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: widget.initialSettings?.height?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  double? _estimateSizeMultiplier() {
    if (!_enabled ||
        widget.originalWidth == null ||
        widget.originalHeight == null) {
      return null;
    }

    final settings = _buildSettings();
    return settings.estimateSizeMultiplier(
        widget.originalWidth!, widget.originalHeight!);
  }

  ResolutionSettings _buildSettings() {
    int? width;
    int? height;
    String? presetName;

    if (_customResolution) {
      width = int.tryParse(_widthController.text);
      height = int.tryParse(_heightController.text);
    } else if (_selectedPreset != null) {
      final preset = ResolutionSettings.presets[_selectedPreset];
      width = preset?.width;
      height = preset?.height;
      presetName = preset?.presetName;
    }

    return ResolutionSettings(
      width: width,
      height: height,
      framerate: _selectedFramerate,
      presetName: presetName,
      enabled: _enabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizeMultiplier = _estimateSizeMultiplier();

    return AlertDialog(
      title: const Text('Resolution & Framerate Settings'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text('Enable Resolution/Framerate Change'),
                subtitle: const Text('Downscale video or change framerate'),
                value: _enabled,
                onChanged: (value) {
                  setState(() {
                    _enabled = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_enabled) ...[
                if (widget.originalWidth != null &&
                    widget.originalHeight != null) ...[
                  Text(
                    'Original: ${widget.originalWidth}x${widget.originalHeight}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                ],
                const Text(
                  'Resolution',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Preset')),
                    ButtonSegment(value: true, label: Text('Custom')),
                  ],
                  selected: {_customResolution},
                  onSelectionChanged: (Set<bool> selected) {
                    setState(() {
                      _customResolution = selected.first;
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (!_customResolution) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedPreset,
                    decoration: const InputDecoration(
                      labelText: 'Resolution Preset',
                      border: OutlineInputBorder(),
                    ),
                    items: ResolutionSettings.presets.keys.map((key) {
                      return DropdownMenuItem(value: key, child: Text(key));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPreset = value;
                      });
                    },
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _widthController,
                          decoration: const InputDecoration(
                            labelText: 'Width',
                            hintText: 'e.g., 1920',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('×', style: TextStyle(fontSize: 24)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _heightController,
                          decoration: const InputDecoration(
                            labelText: 'Height',
                            hintText: 'e.g., 1080',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Leave one field empty to maintain aspect ratio',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Framerate',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<double?>(
                  value: _selectedFramerate,
                  decoration: const InputDecoration(
                    labelText: 'Target Framerate',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Keep Original'),
                    ),
                    ...ResolutionSettings.framerateOptions.map((fps) {
                      return DropdownMenuItem(
                        value: fps,
                        child: Text(
                            '${fps.toStringAsFixed(fps == fps.toInt() ? 0 : 2)} fps'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFramerate = value;
                    });
                  },
                ),
                if (sizeMultiplier != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Estimated size: ${(sizeMultiplier * 100).toStringAsFixed(0)}% of original',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
            final settings = _buildSettings();
            Navigator.of(context).pop(settings);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

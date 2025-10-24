import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/trim_settings.dart';

/// Dialog for configuring trim/cut settings (Feature #9)
class TrimSettingsDialog extends StatefulWidget {
  final TrimSettings? initialSettings;
  final String? fileDuration; // HH:MM:SS format

  const TrimSettingsDialog({
    super.key,
    this.initialSettings,
    this.fileDuration,
  });

  @override
  State<TrimSettingsDialog> createState() => _TrimSettingsDialogState();
}

class _TrimSettingsDialogState extends State<TrimSettingsDialog> {
  late TextEditingController _startController;
  late TextEditingController _endController;
  bool _enabled = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialSettings?.enabled ?? false;
    _startController = TextEditingController(
      text: widget.initialSettings?.startTime != null
          ? TrimSettings.formatTime(widget.initialSettings!.startTime!)
          : '',
    );
    _endController = TextEditingController(
      text: widget.initialSettings?.endTime != null
          ? TrimSettings.formatTime(widget.initialSettings!.endTime!)
          : '',
    );
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _validateAndSetError() {
    setState(() {
      if (!_enabled) {
        _errorMessage = null;
        return;
      }

      final startText = _startController.text.trim();
      final endText = _endController.text.trim();

      if (startText.isEmpty && endText.isEmpty) {
        _errorMessage = 'Please specify at least start or end time';
        return;
      }

      final settings = TrimSettings.fromTimeStrings(
        startTimeStr: startText.isNotEmpty ? startText : null,
        endTimeStr: endText.isNotEmpty ? endText : null,
        enabled: true,
      );

      if (!settings.isValid) {
        _errorMessage = 'End time must be after start time';
        return;
      }

      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Trim/Cut Settings'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Enable Trim/Cut'),
              subtitle: const Text('Export only a portion of the file'),
              value: _enabled,
              onChanged: (value) {
                setState(() {
                  _enabled = value;
                  _validateAndSetError();
                });
              },
            ),
            const SizedBox(height: 16),
            if (_enabled) ...[
              if (widget.fileDuration != null) ...[
                Text(
                  'File Duration: ${widget.fileDuration}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _startController,
                decoration: const InputDecoration(
                  labelText: 'Start Time',
                  hintText: 'HH:MM:SS or MM:SS or SS',
                  helperText: 'Leave empty to start from beginning',
                  prefixIcon: Icon(Icons.play_arrow),
                ),
                keyboardType: TextInputType.text,
                onChanged: (_) => _validateAndSetError(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _endController,
                decoration: const InputDecoration(
                  labelText: 'End Time',
                  hintText: 'HH:MM:SS or MM:SS or SS',
                  helperText: 'Leave empty to go to the end',
                  prefixIcon: Icon(Icons.stop),
                ),
                keyboardType: TextInputType.text,
                onChanged: (_) => _validateAndSetError(),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Time Format Examples:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              const Text(
                '• 1:30:45 (1 hour, 30 minutes, 45 seconds)\n'
                '• 5:30 (5 minutes, 30 seconds)\n'
                '• 90 (90 seconds)',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _errorMessage != null
              ? null
              : () {
                  final settings = TrimSettings.fromTimeStrings(
                    startTimeStr: _startController.text.trim().isNotEmpty
                        ? _startController.text.trim()
                        : null,
                    endTimeStr: _endController.text.trim().isNotEmpty
                        ? _endController.text.trim()
                        : null,
                    enabled: _enabled,
                  );
                  Navigator.of(context).pop(settings);
                },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

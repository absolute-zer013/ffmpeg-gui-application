import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/external_preset.dart';
import '../services/preset_import_service.dart';

/// Dialog for importing presets from external tools.
class PresetImportDialog extends StatefulWidget {
  final Function(ExternalPreset) onPresetSelected;

  const PresetImportDialog({
    super.key,
    required this.onPresetSelected,
  });

  @override
  State<PresetImportDialog> createState() => _PresetImportDialogState();
}

class _PresetImportDialogState extends State<PresetImportDialog> {
  final PresetImportService _importService = PresetImportService();
  List<ExternalPreset>? _presets;
  bool _loading = false;
  String? _error;
  ExternalPreset? _selectedPreset;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.file_download),
                  const SizedBox(width: 8),
                  const Text(
                    'Import Presets',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildContent(),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _selectedPreset != null && !_loading
                        ? () {
                            widget.onPresetSelected(_selectedPreset!);
                            Navigator.of(context).pop();
                          }
                        : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Apply Preset'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading presets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectFile,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_presets == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.upload_file, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Select a preset file to import',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Supported formats: HandBrake JSON (.json)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _selectFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Select File'),
            ),
          ],
        ),
      );
    }

    if (_presets!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'No presets found in file',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectFile,
              child: const Text('Select Another File'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '${_presets!.length} presets found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _selectFile,
              icon: const Icon(Icons.folder_open, size: 16),
              label: const Text('Load Different File'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _presets!.length,
            itemBuilder: (context, index) {
              final preset = _presets![index];
              final isSelected = _selectedPreset == preset;
              
              return Card(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: ListTile(
                  leading: Icon(
                    preset.mapping?.isCompatible == true
                        ? Icons.check_circle
                        : Icons.warning,
                    color: preset.mapping?.isCompatible == true
                        ? Colors.green
                        : Colors.orange,
                  ),
                  title: Text(preset.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (preset.description != null)
                        Text(preset.description!),
                      const SizedBox(height: 4),
                      if (preset.mapping != null)
                        Text(
                          preset.mapping!.getSummary(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (preset.mapping?.warnings.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        ...preset.mapping!.warnings.map(
                          (warning) => Row(
                            children: [
                              const Icon(Icons.warning_amber, size: 12, color: Colors.orange),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  warning,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.orange,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check)
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    setState(() {
                      _selectedPreset = preset;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'xml'],
      dialogTitle: 'Select Preset File',
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final filePath = result.files.single.path;
    if (filePath == null) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _presets = null;
      _selectedPreset = null;
    });

    try {
      final presets = await _importService.importPresetFile(filePath);
      setState(() {
        _presets = presets;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }
}

import 'package:flutter/material.dart';
import '../models/export_profile.dart';
import '../models/multi_profile_export_config.dart';

/// Dialog for configuring multi-profile export (Feature #14)
class MultiProfileExportDialog extends StatefulWidget {
  final List<ExportProfile> availableProfiles;
  final MultiProfileExportConfig? initialConfig;

  const MultiProfileExportDialog({
    super.key,
    required this.availableProfiles,
    this.initialConfig,
  });

  @override
  State<MultiProfileExportDialog> createState() =>
      _MultiProfileExportDialogState();
}

class _MultiProfileExportDialogState extends State<MultiProfileExportDialog> {
  static const int _minimumProfileCount = 2;
  static const String _previewFilename = 'example.mkv';

  late Set<String> _selectedProfileNames;
  late FilenameSuffixStrategy _suffixStrategy;
  late bool _parallel;

  @override
  void initState() {
    super.initState();
    _selectedProfileNames =
        widget.initialConfig?.profiles.map((p) => p.name).toSet() ?? {};
    _suffixStrategy = widget.initialConfig?.suffixStrategy ??
        FilenameSuffixStrategy.profileName;
    _parallel = widget.initialConfig?.parallel ?? false;
  }

  List<ExportProfile> _getSelectedProfiles() {
    return widget.availableProfiles
        .where((p) => _selectedProfileNames.contains(p.name))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final canApply = _selectedProfileNames.length >= _minimumProfileCount;

    return AlertDialog(
      title: const Text('Multi-Profile Export'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export this file with multiple profiles simultaneously. '
                'Each profile will generate a separate output file.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (widget.availableProfiles.isEmpty) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No profiles available. Create profiles first.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  'Select Profiles',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.availableProfiles.length,
                    itemBuilder: (context, index) {
                      final profile = widget.availableProfiles[index];
                      final isSelected =
                          _selectedProfileNames.contains(profile.name);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedProfileNames.add(profile.name);
                            } else {
                              _selectedProfileNames.remove(profile.name);
                            }
                          });
                        },
                        title: Text(profile.name),
                        subtitle: profile.description.isNotEmpty
                            ? Text(
                                profile.description,
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                        secondary: Icon(
                          Icons.folder_special,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                if (!canApply) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Select at least $_minimumProfileCount profiles',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Filename Strategy',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...FilenameSuffixStrategy.values.map((strategy) {
                  return RadioListTile<FilenameSuffixStrategy>(
                    value: strategy,
                    groupValue: _suffixStrategy,
                    onChanged: (value) {
                      setState(() {
                        _suffixStrategy = value!;
                      });
                    },
                    title: Text(strategy.displayName),
                    subtitle: Text(
                      strategy.description,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                SwitchListTile(
                  value: _parallel,
                  onChanged: (value) {
                    setState(() {
                      _parallel = value;
                    });
                  },
                  title: const Text('Parallel Export'),
                  subtitle: const Text(
                    'Export profiles simultaneously (faster but uses more resources)',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedProfileNames.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Preview: ${_selectedProfileNames.length} output file(s)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._getSelectedProfiles().asMap().entries.map((entry) {
                          final config = MultiProfileExportConfig(
                            profiles: [entry.value],
                            suffixStrategy: _suffixStrategy,
                          );
                          final filename = config.generateFilename(
                            _previewFilename,
                            entry.value,
                            entry.key,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $filename',
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        }),
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
          onPressed: canApply
              ? () {
                  final config = MultiProfileExportConfig(
                    profiles: _getSelectedProfiles(),
                    suffixStrategy: _suffixStrategy,
                    parallel: _parallel,
                  );
                  Navigator.of(context).pop(config);
                }
              : null,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

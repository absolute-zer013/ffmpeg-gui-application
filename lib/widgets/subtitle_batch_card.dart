import 'package:flutter/material.dart';
import '../models/file_item.dart';

/// Widget for batch subtitle selection
class SubtitleBatchCard extends StatelessWidget {
  final List<FileItem> files;
  final VoidCallback onChanged;

  const SubtitleBatchCard({
    super.key,
    required this.files,
    required this.onChanged,
  });

  List<String> _getAllSubtitleDescriptions() {
    final descriptions = <String>{};
    for (final file in files) {
      for (final track in file.subtitleTracks) {
        descriptions.add(track.description);
      }
    }
    return descriptions.toList()..sort();
  }

  bool? _subtitleDescriptionTriState(String description) {
    int selectedCount = 0;
    int totalCount = 0;

    for (final file in files) {
      for (final track in file.subtitleTracks) {
        if (track.description == description) {
          totalCount++;
          if (file.selectedSubtitles.contains(track.position)) {
            selectedCount++;
          }
        }
      }
    }

    if (selectedCount == 0) return false;
    if (selectedCount == totalCount) return true;
    return null; // Some selected
  }

  void _toggleSubtitleDescription(String description, bool select) {
    for (final file in files) {
      for (final track in file.subtitleTracks) {
        if (track.description == description) {
          if (select) {
            file.selectedSubtitles.add(track.position);
            file.defaultSubtitle ??= track.position;
          } else {
            file.selectedSubtitles.remove(track.position);
            if (file.defaultSubtitle == track.position) {
              file.defaultSubtitle = file.selectedSubtitles.isNotEmpty
                  ? file.selectedSubtitles.first
                  : null;
            }
          }
        }
      }
    }
    onChanged();
  }

  bool _isSubtitleDescriptionDefault(String description) {
    for (final file in files) {
      for (final track in file.subtitleTracks) {
        if (track.description == description &&
            file.defaultSubtitle == track.position) {
          return true;
        }
      }
    }
    return false;
  }

  void _toggleSubtitleDescriptionDefault(String description, bool setDefault) {
    for (final file in files) {
      for (final track in file.subtitleTracks) {
        if (track.description == description) {
          if (setDefault) {
            file.selectedSubtitles.add(track.position);
            file.defaultSubtitle = track.position;
          } else {
            if (file.defaultSubtitle == track.position) {
              file.defaultSubtitle = null;
            }
          }
        }
      }
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Subtitle Batch',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_getAllSubtitleDescriptions().isEmpty)
                      const Text('No subtitles found'),
                    for (final desc in _getAllSubtitleDescriptions())
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              tristate: true,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(desc,
                                  style: const TextStyle(fontSize: 12)),
                              value: _subtitleDescriptionTriState(desc),
                              onChanged: (val) {
                                final currentState =
                                    _subtitleDescriptionTriState(desc);
                                final select = currentState != true;
                                _toggleSubtitleDescription(desc, select);
                              },
                            ),
                          ),
                          Checkbox(
                            value: _isSubtitleDescriptionDefault(desc),
                            onChanged: (v) {
                              _toggleSubtitleDescriptionDefault(
                                  desc, v ?? false);
                            },
                          ),
                          const Text('Def', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

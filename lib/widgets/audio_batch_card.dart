import 'package:flutter/material.dart';
import '../models/file_item.dart';

/// Widget for batch audio selection
class AudioBatchCard extends StatelessWidget {
  final List<FileItem> files;
  final VoidCallback onChanged;

  const AudioBatchCard({
    super.key,
    required this.files,
    required this.onChanged,
  });

  List<String> _getAllAudioLanguages() {
    final languages = <String>{};
    for (final file in files) {
      for (final track in file.audioTracks) {
        languages.add(track.language);
      }
    }
    return languages.toList()..sort();
  }

  bool? _audioLanguageTriState(String language) {
    int selectedCount = 0;
    int totalCount = 0;

    for (final file in files) {
      for (final track in file.audioTracks) {
        if (track.language == language) {
          totalCount++;
          if (file.selectedAudio.contains(track.position)) {
            selectedCount++;
          }
        }
      }
    }

    if (selectedCount == 0) return false;
    if (selectedCount == totalCount) return true;
    return null; // Some selected
  }

  void _toggleAudioLanguage(String language, bool select) {
    for (final file in files) {
      for (final track in file.audioTracks) {
        if (track.language == language) {
          if (select) {
            file.selectedAudio.add(track.position);
          } else {
            file.selectedAudio.remove(track.position);
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
            Text('Audio Batch', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_getAllAudioLanguages().isEmpty)
                      const Text('No audio languages found'),
                    for (final lang in _getAllAudioLanguages())
                      CheckboxListTile(
                        tristate: true,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(lang),
                        value: _audioLanguageTriState(lang),
                        onChanged: (val) {
                          final currentState = _audioLanguageTriState(lang);
                          final select = currentState != true;
                          _toggleAudioLanguage(lang, select);
                        },
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

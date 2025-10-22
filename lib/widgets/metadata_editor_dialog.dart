import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../models/metadata.dart';

/// Dialog for editing file and track metadata
class MetadataEditorDialog extends StatefulWidget {
  final FileItem item;

  const MetadataEditorDialog({
    super.key,
    required this.item,
  });

  @override
  State<MetadataEditorDialog> createState() => _MetadataEditorDialogState();
}

class _MetadataEditorDialogState extends State<MetadataEditorDialog> {
  late FileMetadata _fileMetadata;
  late Map<int, TrackMetadata> _trackMetadata;

  // Controllers for file metadata
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late TextEditingController _dateController;
  late TextEditingController _commentController;
  late TextEditingController _genreController;

  @override
  void initState() {
    super.initState();

    // Initialize file metadata
    _fileMetadata = widget.item.fileMetadata ?? FileMetadata();
    _trackMetadata = Map.from(widget.item.trackMetadata);

    // Initialize controllers
    _titleController = TextEditingController(text: _fileMetadata.title);
    _artistController = TextEditingController(text: _fileMetadata.artist);
    _albumController = TextEditingController(text: _fileMetadata.album);
    _dateController = TextEditingController(text: _fileMetadata.date);
    _commentController = TextEditingController(text: _fileMetadata.comment);
    _genreController = TextEditingController(text: _fileMetadata.genre);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _dateController.dispose();
    _commentController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  void _saveMetadata() {
    // Update file metadata from controllers
    _fileMetadata.title =
        _titleController.text.isEmpty ? null : _titleController.text;
    _fileMetadata.artist =
        _artistController.text.isEmpty ? null : _artistController.text;
    _fileMetadata.album =
        _albumController.text.isEmpty ? null : _albumController.text;
    _fileMetadata.date =
        _dateController.text.isEmpty ? null : _dateController.text;
    _fileMetadata.comment =
        _commentController.text.isEmpty ? null : _commentController.text;
    _fileMetadata.genre =
        _genreController.text.isEmpty ? null : _genreController.text;

    // Update the file item
    widget.item.fileMetadata = _fileMetadata;
    widget.item.trackMetadata = _trackMetadata;

    Navigator.pop(context, true);
  }

  Widget _buildFileMetadataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('File Metadata', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _artistController,
          decoration: const InputDecoration(
            labelText: 'Artist',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _albumController,
          decoration: const InputDecoration(
            labelText: 'Album',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _dateController,
          decoration: const InputDecoration(
            labelText: 'Date',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _genreController,
          decoration: const InputDecoration(
            labelText: 'Genre',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentController,
          decoration: const InputDecoration(
            labelText: 'Comment',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildTrackMetadataSection() {
    final allTracks = [
      ...widget.item.videoTracks,
      ...widget.item.audioTracks,
      ...widget.item.subtitleTracks,
    ];

    if (allTracks.isEmpty) {
      return const Text('No tracks available');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Track Metadata', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...allTracks.map((track) {
          final streamIndex = track.streamIndex;
          final trackMeta = _trackMetadata[streamIndex] ??
              TrackMetadata(
                language: track.language,
                title: track.title,
              );

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.description,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Language',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          controller: TextEditingController(
                            text: trackMeta.language,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _trackMetadata[streamIndex] = trackMeta.copyWith(
                                language: value.isEmpty ? null : value,
                              );
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          controller: TextEditingController(
                            text: trackMeta.title,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _trackMetadata[streamIndex] = trackMeta.copyWith(
                                title: value.isEmpty ? null : value,
                              );
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit),
                const SizedBox(width: 8),
                Text('Edit Metadata',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildFileMetadataSection(),
                    const SizedBox(height: 24),
                    _buildTrackMetadataSection(),
                  ],
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saveMetadata,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

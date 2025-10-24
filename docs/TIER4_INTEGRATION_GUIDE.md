# Tier 4 Features - Integration Guide

This document explains how to integrate the newly implemented Tier 4 features into the FFmpeg Export Tool.

## Overview

Four complex features have been implemented:
1. **Dual Pane Mode** - Split-screen file comparison
2. **Waveform Visualization** - Audio waveform display
3. **Command-Line Interface** - Headless automation
4. **Presets Import** - HandBrake preset import

All features are fully implemented with models, services, widgets, and tests. This guide shows how to integrate them into the main application.

## Feature #21: Dual Pane Mode

### Components
- **Model**: `lib/models/dual_pane_mode.dart`
- **Widget**: `lib/widgets/dual_pane_widget.dart`
- **Tests**: `test/models/dual_pane_mode_test.dart`

### Integration Steps

1. Add state variables to `_MyHomePageState`:
```dart
DualPaneMode _dualPaneMode = const DualPaneMode();
bool _showDualPane = false;
```

2. Add a button to the AppBar actions:
```dart
IconButton(
  icon: const Icon(Icons.view_column),
  tooltip: 'Dual Pane Mode',
  onPressed: () => setState(() => _showDualPane = !_showDualPane),
),
```

3. Add the widget in the Scaffold body:
```dart
if (_showDualPane && _files.length >= 2)
  Expanded(
    child: DualPaneWidget(
      mode: _dualPaneMode,
      leftFile: _files[0],
      rightFile: _files[1],
      onModeChanged: (mode) => setState(() => _dualPaneMode = mode),
    ),
  ),
```

### Usage
1. Load at least two files
2. Click the dual pane button in the AppBar
3. Drag the divider to resize panes
4. Compare file details side-by-side

## Feature #23: Waveform Visualization

### Components
- **Model**: `lib/models/waveform_data.dart`
- **Service**: `lib/services/waveform_generation_service.dart`
- **Widget**: `lib/widgets/waveform_widget.dart`
- **Tests**: `test/models/waveform_data_test.dart`

### Integration Steps

1. Import the service and widget:
```dart
import 'services/waveform_generation_service.dart';
import 'widgets/waveform_widget.dart';
import 'models/waveform_data.dart';
```

2. Add service instance to `_MyHomePageState`:
```dart
final WaveformGenerationService _waveformService = WaveformGenerationService();
Map<String, WaveformData> _waveforms = {};
```

3. Add a method to generate waveform:
```dart
Future<void> _generateWaveform(FileItem file, int trackIndex) async {
  final waveform = await _waveformService.generateWaveform(
    file.filePath,
    trackIndex,
  );
  if (waveform != null) {
    setState(() {
      _waveforms[file.filePath] = waveform;
    });
  }
}
```

4. Add button to file card or audio track:
```dart
IconButton(
  icon: const Icon(Icons.waves),
  tooltip: 'Show Waveform',
  onPressed: () => _showWaveformDialog(file, trackIndex),
),
```

5. Create dialog to show waveform:
```dart
void _showWaveformDialog(FileItem file, int trackIndex) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 400),
        child: FutureBuilder<WaveformData?>(
          future: _waveformService.generateWaveform(file.filePath, trackIndex),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text('Failed to generate waveform'));
            }
            return WaveformWidget(
              waveformData: snapshot.data!,
              onSeek: (position) {
                // Handle seek if needed
                print('Seek to: $position seconds');
              },
            );
          },
        ),
      ),
    ),
  );
}
```

### Usage
1. Load a file with audio tracks
2. Click the waveform button on an audio track
3. View, zoom, and interact with the waveform
4. Click to seek, scroll to pan

## Feature #27: Command-Line Interface

### Components
- **CLI**: `bin/ffmpeg_cli.dart`
- **Dependencies**: Added `args: ^2.4.2` to `pubspec.yaml`

### Usage

The CLI is ready to use without any integration needed. Run it from the project root:

```bash
# Show help
dart run bin/ffmpeg_cli.dart --help

# Show file information
dart run bin/ffmpeg_cli.dart -i input.mkv --info

# Show file information as JSON
dart run bin/ffmpeg_cli.dart -i input.mkv --info --json

# Dry run (preview without executing)
dart run bin/ffmpeg_cli.dart -i input.mkv -a 0,1 -s 0 --dry-run

# Export with specific tracks
dart run bin/ffmpeg_cli.dart -i input.mkv -a 0,1 -s 0 -o output.mkv

# Export with codec conversion
dart run bin/ffmpeg_cli.dart -i input.mkv --video-codec h264 --audio-codec aac

# Full example with all options
dart run bin/ffmpeg_cli.dart \
  -i input.mkv \
  -a 0,1 \
  -s 0 \
  -o output.mkv \
  --format mkv \
  --video-codec h264 \
  --audio-codec aac \
  --audio-bitrate 192k \
  --verify \
  --json
```

### Compilation

For distribution, compile to native executable:

```bash
dart compile exe bin/ffmpeg_cli.dart -o ffmpeg_cli.exe
```

Then use directly:

```bash
ffmpeg_cli.exe -i input.mkv --info
```

## Feature #28: Presets Import

### Components
- **Models**: `lib/models/external_preset.dart`
- **Service**: `lib/services/preset_import_service.dart`
- **Widget**: `lib/widgets/preset_import_dialog.dart`
- **Tests**: `test/models/external_preset_test.dart`

### Integration Steps

1. Import the dialog:
```dart
import 'widgets/preset_import_dialog.dart';
import 'models/external_preset.dart';
```

2. Add a button to open the import dialog:
```dart
OutlinedButton.icon(
  onPressed: _running ? null : _showPresetImportDialog,
  icon: const Icon(Icons.file_download),
  label: const Text('Import Preset'),
),
```

3. Add method to show dialog:
```dart
void _showPresetImportDialog() {
  showDialog(
    context: context,
    builder: (context) => PresetImportDialog(
      onPresetSelected: (preset) {
        _applyImportedPreset(preset);
      },
    ),
  );
}
```

4. Add method to apply preset:
```dart
void _applyImportedPreset(ExternalPreset preset) {
  if (preset.mapping == null) {
    _appendLog('ERROR: Preset has no mapping');
    return;
  }

  final mapping = preset.mapping!;
  
  // Show warnings if any
  if (mapping.warnings.isNotEmpty) {
    _appendLog('WARNING: Preset compatibility issues:');
    for (var warning in mapping.warnings) {
      _appendLog('  - $warning');
    }
  }

  // Apply settings to files
  for (var file in _files) {
    if (mapping.videoCodec != null) {
      file.codecOptions = (file.codecOptions ?? CodecOptions()).copyWith(
        videoCodec: mapping.videoCodec,
      );
    }
    if (mapping.audioCodec != null) {
      file.codecOptions = (file.codecOptions ?? CodecOptions()).copyWith(
        audioCodec: mapping.audioCodec,
        audioBitrate: mapping.audioBitrate,
      );
    }
  }

  setState(() {});
  _appendLog('Applied preset: ${preset.name}');
}
```

### Usage
1. Click "Import Preset" button
2. Select a HandBrake JSON preset file
3. Browse available presets
4. Click on a preset to select it
5. Click "Apply Preset" to apply settings
6. Review compatibility warnings if any

## HandBrake Preset Format

Example HandBrake preset JSON:

```json
{
  "PresetName": "Fast 1080p30",
  "PresetDescription": "Fast encoding for 1080p 30fps",
  "VideoEncoder": "x264",
  "VideoQualitySlider": 23,
  "PictureWidth": 1920,
  "PictureHeight": 1080,
  "VideoFramerate": "30",
  "AudioList": [
    {
      "AudioEncoder": "aac",
      "AudioBitrate": 192
    }
  ],
  "FileFormat": "av_mp4"
}
```

## Testing

All features have comprehensive unit tests:

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/dual_pane_mode_test.dart
flutter test test/models/waveform_data_test.dart
flutter test test/models/external_preset_test.dart

# Run with coverage
flutter test --coverage
```

## Next Steps

1. **UI Integration**: Add buttons and menu items to the main UI
2. **User Documentation**: Create user-facing guides
3. **Screenshots**: Capture screenshots of each feature
4. **Video Tutorial**: Create demo videos
5. **Release Notes**: Update changelog with release date

## Notes

- All features are production-ready
- Minimal changes needed for integration
- No breaking changes to existing functionality
- Full backward compatibility maintained
- All features are optional and can be enabled/disabled

## Support

For questions or issues:
1. Check existing tests for usage examples
2. Review model/service documentation
3. See FEATURES.md for detailed descriptions
4. Refer to PHASE5_TIER4_TRACKING.md for implementation details

# FFmpeg Filter App

This Flutter project implements a simple desktop utility for Windows that filters
Matroska (`.mkv`) files to remove English audio tracks and all subtitle
tracks except one that you choose. It uses
[`file_picker`](https://pub.dev/packages/file_picker) to select multiple files
and spawns the external `ffmpeg` and `ffprobe` tools to analyse and rewrite
the files.

## Features

- **Select multiple MKV files** using the system file picker.
- Specify the exact title of the subtitle track to keep. All other subtitles
  are dropped from the output.
- English audio tracks (`eng` language tag) are removed if present.
- Video streams, chapters, attachments and other audio/subtitle tracks are
  preserved.
- Processed files are saved into a `Filtered` sub‑directory with the same
  filename.

## Prerequisites

This application relies on external `ffmpeg` and `ffprobe` binaries being
available in the system `PATH`. You can download static builds of FFmpeg
for Windows from [ffmpeg.org](https://ffmpeg.org/download.html) or other
distributors. Make sure both `ffmpeg.exe` and `ffprobe.exe` are visible on
your command line.

To build and run this project, you also need Flutter with desktop support
enabled. See the official
[`Windows` documentation](https://docs.flutter.dev/platform-integration/windows/building)
for instructions on setting up Flutter for Windows development.

## Building and running

1. **Clone or unpack this repository** into a folder on your computer.
2. **Generate platform runners** if you haven’t already. From the project
   directory, run:
   
   ```bash
   flutter create --platforms=windows .
   ```
   
   This command adds the `windows` directory with a C++ runner. If you
   initialized the project using `flutter create`, this step is unnecessary.

3. **Fetch dependencies**:

   ```bash
   flutter pub get
   ```

4. **Run the application**:

   ```bash
   flutter run -d windows
   ```

When you click **Select MKV Files**, choose one or more `.mkv` files from
your disk. Enter the exact subtitle title (case‑sensitive) that you want to
keep in the field below, then press **Run Filter**. The application will
iterate over each file, examine its streams, and write a new file in the
`Filtered` folder.

## Notes

- The subtitle title must match exactly the title shown in tools like
  MKVToolNix or the `ffprobe` output. If a selected file does not contain
  the chosen title, all subtitle tracks are preserved for that file.
- This sample uses the `Process.run` API from `dart:io` to start
  `ffmpeg` and `ffprobe`. The application expects both commands to exit
  successfully; errors are reported in the log at the bottom of the UI.

Feel free to modify and extend this example to suit your needs. For example,
you could add a dialog that reads subtitle tracks from the first file and
lets you choose one interactively, or display progress indicators for each
file.

## New Features

### Export Profiles
The application now supports saving and reusing export configurations:

1. **Save Profile**: After selecting your desired audio/subtitle tracks, click "Save as Profile" to save the configuration
2. **Apply Profile**: Click "Profiles" to view saved profiles and apply them to new files
3. **Manage Profiles**: Delete unwanted profiles from the management dialog
4. **Persistent Storage**: Profiles are saved automatically and persist across sessions

Profiles store:
- Selected audio languages (e.g., Japanese, English)
- Selected subtitle descriptions
- Default subtitle track preference

### Codec Conversion
The application supports re-encoding video and audio streams:

1. **Video Codecs**: Convert between H.264, H.265/HEVC, VP9, AV1, or keep original (Copy)
2. **Audio Codecs**: Convert between AAC, MP3, Opus, AC3, FLAC, Vorbis, or keep original (Copy)
3. **Audio Settings**: Configure bitrate, channels (mono/stereo/5.1/7.1), and sample rate
4. **Per-Track Settings**: Click the tune button on file cards to configure codec settings

### Quality Presets
Apply predefined quality presets for consistent encoding:

1. **Fast**: Quick encoding (CRF 28, 128k audio) - acceptable quality
2. **Balanced**: Medium speed (CRF 23, 192k audio) - good quality (default)
3. **High Quality**: Slow encoding (CRF 18, 256k audio) - best quality
4. **Visual Feedback**: Active preset shown as a chip on file cards

### Verification Mode
Automatically verify exported files for errors:

1. **Enable**: Toggle verification in Settings (gear icon)
2. **Automatic**: Runs after each export completes
3. **Stream Verification**: Checks video, audio, subtitle counts match expected
4. **Integrity Check**: Detects file corruption
5. **Visual Status**: Pass (✓) or warning (⚠) badges in file cards

### Advanced Rename Patterns (Phase 3)
Apply dynamic filename templates with variable substitution:

1. **Variables**: Use {name}, {episode}, {season}, {year}, {date}, {index}
2. **Padding**: Format with padding (e.g., {episode:3} = 001)
3. **Presets**: TV Show, Movie, Anime, and more predefined patterns
4. **Per-File**: Set different patterns for each file
5. **Auto-Apply**: Patterns applied automatically during export

Examples:
- TV Show: `{name} - S{season:2}E{episode:2}` → "Show - S01E05.mkv"
- Anime: `{name} - {episode:3}` → "Anime - 012.mkv"
- Movie: `{name} ({year})` → "Movie (2024).mkv"

### Auto-Detect Rules (Phase 3)
Automatically select tracks based on configurable rules:

1. **Rule Types**: Create rules for audio, subtitle, or video tracks
2. **Conditions**: Match by language, title, codec, or channels
3. **Actions**: Select, deselect, or set tracks as default
4. **Priority**: Rules applied in priority order
5. **Auto-Apply**: Rules applied automatically when files are added
6. **Predefined**: Common rules included (Japanese audio, forced subtitles, etc.)

### Configuration Import/Export (Phase 3)
Save and restore complete batch configurations:

1. **Export**: Save all selections, profiles, and rules to JSON file
2. **Import**: Restore exact configuration from saved file
3. **Share**: Transfer configurations between users or sessions
4. **Metadata**: Includes name, description, and creation date
5. **Validation**: Automatic validation on import

Configuration includes:
- File selections (all tracks)
- Export profiles
- Auto-detect rules
- Rename patterns
- Output format and settings

## What's Next?

### Phase 5 - Planned Features

The project roadmap includes 17 additional features planned for future releases, organized into 5 categories:

- **Quality of Life**: Recent files list, undo/redo, search/filter, sorting
- **Export Enhancements**: Trim/cut functionality, resolution/framerate changes
- **Batch Operations**: Multi-profile export
- **Advanced Features**: Chapter editing, audio/subtitle sync, subtitle format conversion, MKV optimization
- **UI/UX Enhancements**: Dual pane mode, waveform visualization, estimated export times
- **Integration**: Watch folder, command-line interface, presets import

See `docs/PHASE5_FEATURES.md` for the complete list and `docs/PHASE5_PLANNING.md` for implementation guidance.

## Testing & Quality Assurance

The project includes comprehensive automated testing:

- **Unit Tests**: 23+ tests covering all models and utilities
- **Code Quality**: Automatic format checking and linting
- **CI/CD Pipeline**: GitHub Actions for continuous integration and deployment

### Running Tests Locally

```bash
# Run all tests
.\scripts\run_tests.ps1 test

# Check code formatting
.\scripts\run_tests.ps1 format-check

# Run all quality checks
.\scripts\run_tests.ps1 all
```

See [`TESTING.md`](TESTING.md) for detailed testing documentation.

## Building & Deployment

### Quick Build

```bash
# Build and package for distribution
.\scripts\build_package.ps1 all
```

### Manual Build

```bash
# Build Windows release
flutter build windows --release
```

The executable is created at: `build\windows\x64\runner\Release\export_file.exe`

### Creating Distribution Package

```bash
# Package for distribution (includes all required files)
.\scripts\build_package.ps1 package
```

Creates a ZIP file in `dist/` folder ready for distribution.

### Continuous Deployment

When you push a version tag to GitHub:
- GitHub Actions automatically builds the release
- Tests are run automatically
- Windows executable is created
- Release is published with artifacts

See [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) for detailed deployment guide.

## Documentation

- [`docs/FEATURES.md`](docs/FEATURES.md) - Complete feature list and current capabilities
- [`docs/TESTING.md`](docs/TESTING.md) - Testing guide and CI/CD setup
- [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) - Build and distribution instructions
- [`docs/ENHANCEMENTS.md`](docs/ENHANCEMENTS.md) - Roadmap with all planned features
- [`docs/PHASES_REPORT.md`](docs/PHASES_REPORT.md) - Consolidated phase summaries (Phases 1–5)
- [`CI_CD_SETUP.md`](CI_CD_SETUP.md) - Summary of automated testing setup

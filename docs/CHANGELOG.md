# Changelog

All notable changes to the FFmpeg Export Tool are documented in this file.

## [2025-10-25] — Status Update and Logging Improvements

### 🔄 Status Changes
- Dual Pane Mode (#21) and Waveform Visualization (#23) have been removed from the main UI. Both features remain implemented at the module level with tests and can be re-enabled in a future release. Decision was based on user feedback (discoverability, layout overflow) and startup performance considerations.

### 📝 Logging Improvements
- Consolidated logging into a single session log file per run. All exports (successes and failures) append to this log, and logs are always written on failure.
- Improved FFmpeg invocation flags to reduce noise where applicable.

## [Phase 5 - Tier 4] — Complex Features (2025-10-24)

### ✨ New Features

#### Dual Pane Mode (#21)
- Split-screen layout for comparing source and destination files
- Horizontal or vertical orientation with resizable divider
- Detailed track and metadata display in each pane
- File preview and comparison view
- **Benefit:** Easily compare files before and after export

#### Waveform Visualization (#23)
- Visual representation of audio tracks with canvas rendering
- Zoom controls (1x to 10x) for detailed inspection
- Pan/scroll through waveform data
- Click to seek to specific positions
- Automatic silence detection with highlighting
- Peak and RMS amplitude calculation
- Audio extraction and downsampling via FFmpeg
- **Benefit:** Visual audio inspection and quality analysis

#### Command-Line Interface (#27)
- Headless automation without GUI via `bin/ffmpeg_cli.dart`
- Full argument parsing with `args` package
- JSON output mode for scripting and automation
- File information display (`--info` flag)
- Dry-run mode to preview operations (`--dry-run`)
- Track selection via CLI arguments (`-a`, `-s`)
- Codec configuration from command line
- Verification support
- **Benefit:** Automate batch processing and integrate with scripts

#### Presets Import (#28)
- Import HandBrake JSON preset files
- Automatic parameter mapping to FFmpeg
- Codec translation (video and audio)
- Quality settings conversion (CRF, bitrate)
- Resolution and framerate mapping
- Compatibility warnings for unsupported features
- Preview preset details before applying
- **Benefit:** Quickly configure exports using familiar HandBrake presets

### 🧪 Testing
- Added comprehensive unit tests for all models
- DualPaneMode model tests
- WaveformData model tests with silence detection
- ExternalPreset and PresetMapping tests
- Total test count: 35+ new tests

### 📚 Documentation
- Updated README with Tier 4 feature descriptions
- Updated FEATURES.md with detailed feature documentation
- Updated PHASE5_TIER4_TRACKING.md with implementation status
- Added CLI usage examples

### 🔧 Dependencies
- Added `args: ^2.4.2` for command-line argument parsing

## [Phase 5a] — Export Stability & Codec Enhancements (2025-10-24)

### ✨ New Features

#### Two-Stage Export Pipeline
- Split export into Stage 1 (fast remux/copy) and Stage 2 (optional re-encoding)
- Independent progress tracking for each stage
- Separate logging for diagnosis
- Timing breakdown: Stage 1 duration, Stage 2 duration, total duration
- **Benefit:** Better progress visibility, faster when only demuxing

#### Auto-Fix Codec Compatibility
- Automatic detection and transcoding of incompatible codec+container combinations
- Pre-flight compatibility check before export
- Compatibility rules:
  - **MP4:** H.264, HEVC, MPEG-4, AV1 video; AAC, AC3, ALAC, MP3 audio
  - **WebM:** VP9, AV1 video; Opus, Vorbis audio
  - **MKV:** All codecs supported
- Auto-drop unsupported subtitle tracks
- User warnings in export summary if auto-fix applied
- Toggle in Settings (default: ON)
- **Benefit:** Never encounter "incompatible format" errors

#### Dynamic Codec Filtering
- Hide incompatible codecs from UI dropdown when auto-fix enabled
- Only filter when auto-fix ON; show all when OFF or MKV selected
- Real-time updates based on output format and auto-fix state
- **Benefit:** Cleaner UI, only see usable codec options

#### Codec Preset System for All Codecs
- Quick preset chips (Speed/Balanced/Quality) for H.264, H.265, VP9, and AV1
- **Speed:** preset=fast, CRF=28 (~4x realtime)
- **Balanced:** preset=medium, CRF=23 (~2x realtime) — **Recommended**
- **Quality:** preset=slow, CRF=20 (~1x realtime)
- Manual preset dropdown for advanced users
- CRF field (0-51) for fine-tuning
- Applied settings summary at dialog bottom
- Smooth codec switching with automatic preset reset
- **Benefit:** Consistent UX across all codecs; quick quality selection

#### Comprehensive Export Logging
- Per-file log files created alongside output (e.g., `output.mkv.log`)
- Log contents:
  - FFmpeg commands for both stages
  - stdout and stderr output
  - Progress lines from FFmpeg
  - Timing information
  - Export status (Success/Failure/Cancelled)
  - File size before/after
  - Auto-fix details if applied
- Logs preserved on failure for easy diagnostics
- **Benefit:** Easy debugging, shareable for support

#### Cancellation Handling
- Proper detection of user cancellations (exit codes: -1, 130, 255, Windows codes)
- User-friendly message: "Cancelled by user" instead of "Export failed"
- Distinct from actual errors in logs and UI
- Cancellation badges in file cards and export summary
- **Benefit:** Clear indication that cancellation was intentional

#### Export Summary with Encoding Details
- Enhanced pre-export summary showing what will be applied
- Per-file details: input, output, estimated size
- Video codec section: codec name, CRF, preset, bitrate
- Audio codec section per track: codec name, bitrate, channels, sample rate
- Quality preset summary
- Container format info (MP4, MKV, WebM)
- Auto-fix warnings with codec mappings
- **Benefit:** Confidence before export, catch mistakes early

### 🐛 Bug Fixes
- Fixed UI error when selecting video codecs other than AV1
- Fixed dropdown error when switching between codecs with mismatched presets
- Fixed codec settings persistence when reopening dialog
- Proper braces in if statements (lint fixes)

### 📝 Documentation
- Added comprehensive Phase 5a feature documentation
- Updated ENHANCEMENTS.md with 7 new features (#31-#37)
- Updated PHASE5_TRACKING_ISSUE.md with recently implemented section
- Created PHASE5A_SUMMARY.md with detailed feature breakdown

---

## [Phase 4] — UI Polish (2025-10-24)

### ✨ New Features

#### File Preview
- Built-in file information viewer with comprehensive details
- Display file metadata: path, size, duration, format
- Show all video/audio/subtitle tracks with details
- Selected and default track indicators
- Track metadata display
- "Open Location" button to access file directory
- Responsive dialog with scrollable content

#### Export Queue Management
- Pause/resume/reorder export queue
- Drag-and-drop reordering
- Cancel individual queue items
- Status indicators with color coding (pending, processing, paused, completed, failed, cancelled)
- Move up/down and priority management
- Queue persistence support
- Clear queue and remove individual items
- Real-time progress updates

#### Better Notifications
- Desktop notifications when exports complete
- Windows Toast API integration
- Enhanced in-app SnackBar notifications
- Notification statistics: success/failed/cancelled counts, duration
- Configurable via Settings dialog
- Different notification types: success (✓), error (✗), warning (⚠)

#### Batch Codec/Quality Apply
- Apply codec settings to multiple files at once
- Batch video quality preset application
- Batch audio codec settings application
- "Apply to All" mode in CodecSettingsDialog
- File count display in batch mode
- Respects dialog settings across all loaded files

---

## [Phase 3] — Batch Power / Automation (2025-10)

### ✨ New Features

#### Advanced Rename Patterns
- Dynamic filename templates with variable substitution
- Variables: {name}, {episode}, {season}, {year}, {date}, {index}, {ext}
- Variable padding support (e.g., {episode:3} = 001)
- Predefined patterns: TV Show, Movie, Anime, Indexed, With Date
- Per-file custom patterns
- Pattern validation with error checking
- Comprehensive pattern documentation

#### Auto-Detect Rules
- Automatically select tracks based on configurable rules
- Rule types: audio, subtitle, video
- Conditions: language, title, codec, channels
- Actions: select, deselect, set default
- Priority-based rule ordering
- Enable/disable individual rules
- Auto-apply when files added
- Predefined rules for common scenarios (Japanese audio, forced subtitles, etc.)

#### Configuration Import/Export
- Save entire batch setups to JSON files for reuse
- Export: Save all selections, profiles, and rules
- Import: Restore exact configuration from saved file
- Share configurations between users/sessions
- Configuration metadata (name, description, creation date)
- Automatic validation on import
- Default configuration directory management

---

## [Phase 2] — Advanced Export (2025-10)

### ✨ New Features

#### Codec Conversion
- Re-encode video streams to different codecs
- Video codecs: H.264, H.265/HEVC, VP9, AV1, Copy (no re-encoding)
- Re-encode audio streams to different codecs
- Audio codecs: AAC, MP3, Opus, AC3, FLAC, Vorbis, Copy
- Per-track codec settings via dialog
- Configure audio bitrate (kbps)
- Set audio channels (Mono, Stereo, 5.1, 7.1, Auto)
- Adjust audio sample rate (44100, 48000, 96000 Hz, Auto)
- Automatic copy mode when no conversion specified

#### Quality/CRF Presets
- Predefined quality presets for video encoding
- Fast preset: CRF 28, fast encoding, acceptable quality
- Balanced preset: CRF 23, medium encoding, good quality
- High Quality preset: CRF 18, slow encoding, best quality
- Automatic audio bitrate settings per preset
- Visual display of active preset in file card
- Presets apply FFmpeg CRF and preset parameters

#### Verification Mode
- Automatic verification of exported files
- Check stream counts match expected (video, audio, subtitles)
- Detect file corruption using FFmpeg integrity check
- Visual verification status badges in file cards
- Pass/fail indicators with detailed messages
- Toggle verification on/off in settings
- Verification report logged for each file

---

## [Phase 1] — Core Enhancements (2025-10)

### ✨ New Features

#### Export Profiles/Templates
- Save common export configurations for reuse
- Create profiles with audio/subtitle selections
- Save profiles to persistent storage (SharedPreferences)
- Apply profiles to new files
- Profile management dialog: view, apply, delete
- Show active profile name in UI
- Predefined profiles for common workflows

#### Video Stream Selection
- Choose specific video tracks (for files with multiple video streams)
- Extend Track model to include video tracks
- Update FFprobe detection for video streams
- Video track selection UI in FileCard
- Handle video stream mapping in FFmpegExportService
- Display video codec and resolution information
- Include video track statistics in export summary

#### Metadata Editor
- Edit file metadata: title, artist, album, date, genre, comment
- Edit track-level metadata: language, title
- JSON format metadata extraction from FFprobe
- MetadataEditorDialog widget for editing
- Edit button integrated in FileCard
- Write metadata back using `-metadata` parameters
- Support for file-level and track-level metadata

---

## [Original Features] — Phase 0

### ✨ Core Functionality

- **Multi-file selection** using system file picker
- **Audio track filtering** by language (remove English audio)
- **Subtitle track filtering** (keep selected, remove others)
- **Drag & drop support** for video files
- **Progress tracking** during export
- **Cancellation support** with proper cleanup
- **Output directory selection** with memory of last used path
- **Export summary** with file statistics
- **Success notifications** with detailed counts
- **Batch processing** with sequential/parallel options
- **Settings/Preferences** dialog
- **File information display** (tracks, codecs, duration)

### Platform Support
- **Windows** (primary, fully tested)
- **Linux** (experimental; works with CachyOS)
- **macOS** (build support available)

### Dependencies
- **Flutter 3.35.2+** (desktop support)
- **FFmpeg 4.0+** and **FFprobe** (external; must be in PATH)
- **Dart SDK 3.4.0+**
- **flutter_lints 3.0.0+**
- **shared_preferences 2.2.2+** (configuration storage)
- **file_picker 10.3.3+** (file selection)
- **desktop_drop 0.4.4+** (drag & drop)
- **path 1.8.3+** (path handling)

---

## Migration Guide

### From Original to Phase 1+
- Existing profiles automatically migrated
- Auto-detect rules applied to legacy setups
- Configuration import/export available for new setups

### For Low-Resource CPU Systems
Recommended settings:
- Video Codec: AV1, Encoder: libsvtav1, Preset: Balanced
- Audio Codec: Opus, Bitrate: 128 kbps
- Output Format: MKV
- Auto-Fix: ON
- Expected: 30-40 min per 1hr video, very good quality

---

## Known Limitations

- **No real-time video playback** preview (requires video_player setup)
- **CLI not yet implemented** (Feature #27 in backlog)
- **Watch folder not yet implemented** (Feature #26 in backlog)
- **Trim/cut not yet implemented** (Feature #9 in backlog)
- **Waveform visualization not yet implemented** (Feature #23 in backlog)

---

## Roadmap (Phase 5b Backlog)

### Planned Features (17 remaining)
- **Quality of Life:** Recent files, Undo/Redo, Search/Filter, Sorting
- **Export:** Trim/Cut, Resolution/Framerate changes
- **Advanced:** Chapter editing, Audio/Subtitle sync, Subtitle conversion, MKV optimization
- **UI:** Dual pane mode, Waveform visualization, Estimated export times
- **Integration:** Watch folder, CLI, Preset import

See `docs/ENHANCEMENTS.md` for detailed feature specifications.

---

## Contributing

This is an active project with regular enhancements. Contributions welcome!
See `docs/ENHANCEMENTS.md` for roadmap and `README.md` for setup instructions.

---

## License

[Specify your license here, e.g., MIT, GPL-3.0, etc.]

---

## Acknowledgments

- Built with [Flutter](https://flutter.dev) for cross-platform desktop support
- Powered by [FFmpeg](https://ffmpeg.org) for media processing
- Uses [file_picker](https://pub.dev/packages/file_picker), [shared_preferences](https://pub.dev/packages/shared_preferences), [desktop_drop](https://pub.dev/packages/desktop_drop)

---

## Changelog Format

This changelog follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) conventions.
Version numbering follows semantic versioning (MAJOR.MINOR.PATCH).

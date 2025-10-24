# Enhancement Features Roadmap

This document contains suggested features that can be added to the FFmpeg Export Tool in the future.

## Quality of Life Improvements

### 1. Recent Files List
Quick access to recently processed files for repeat operations.

**Implementation:**
- Store recent file paths in SharedPreferences
- Add "Recent Files" menu/dropdown
- Limit to last 10-20 files

### 2. Export Profiles/Templates ✅ **IMPLEMENTED**
Save common export configurations (audio/subtitle selections) and apply to new files.

**Implementation:**
- ✅ Create `models/export_profile.dart` with profile data model
- ✅ Create `services/profile_service.dart` for save/load/delete profiles
- ✅ Add profile management UI with "Save as Profile" and "Profiles" buttons
- ✅ Store profiles in JSON format via SharedPreferences
- ✅ Profile management dialog for viewing, applying, and deleting profiles
- ✅ Shows active profile name in UI

### 3. Undo/Redo
Reverse recent selection changes.

**Implementation:**
- Implement command pattern for state changes
- Maintain history stack of operations
- Add Ctrl+Z / Ctrl+Y keyboard shortcuts

### 4. Search/Filter
Search through file list or filter by status/size/duration.

**Implementation:**
- Add search TextField in file list header
- Filter files by name, status, size range, duration
- Show filtered count

### 5. Sorting Options
Sort files by name, size, duration, or status.

**Implementation:**
- Add sort dropdown (Name, Size, Duration, Status)
- Add ascending/descending toggle
- Remember sort preference

---

## Export Enhancements

### 6. Video Stream Selection ✅ **IMPLEMENTED**
Choose specific video tracks (useful for files with multiple video streams).

**Implementation:**
- ✅ Extend `Track` model to include video tracks with type enum
- ✅ Update `FFprobeService.probeFile()` to detect video streams
- ✅ Add video track selection UI in `FileCard`
- ✅ Update `FFmpegExportService` to handle video stream mapping
- ✅ Display video codec and resolution information
- ✅ Update export summary to include video track statistics

### 7. Codec Conversion ✅ **IMPLEMENTED**
Re-encode audio/video (e.g., convert HEVC to H.264, AC3 to AAC).

**Implementation:**
- ✅ Create `models/codec_options.dart` with VideoCodec and AudioCodec enums
- ✅ Create CodecConversionSettings model for per-track codec settings
- ✅ Add codec selection dropdowns per track type in CodecSettingsDialog
- ✅ Replace `-c copy` with specific codec parameters in FFmpegExportService
- ✅ Add quality/bitrate settings for audio (bitrate, channels, sample rate)
- ✅ Support multiple codecs: H.264, H.265, VP9, AV1 for video; AAC, MP3, Opus, AC3, FLAC for audio

### 8. Quality Presets ✅ **IMPLEMENTED**
CRF/bitrate settings for re-encoding.

**Implementation:**
- ✅ Create `models/quality_preset.dart` with QualityPreset class
- ✅ Add preset selector (Fast, Balanced, High Quality) in codec settings dialog
- ✅ Map presets to FFmpeg parameters (-crf, -preset, -bitrate)
- ✅ Show active preset as chip in file card
- ✅ Predefined presets with CRF values: Fast (28), Balanced (23), High Quality (18)
- ✅ Support for custom audio bitrates per preset

### 9. Trim/Cut Functionality
Set start/end timestamps to export only portions of files.

**Implementation:**
- Add start/end time inputs (HH:MM:SS format)
- Use FFmpeg `-ss` and `-to` parameters
- Show timeline slider for visual selection
- Update duration calculation

### 10. Resolution/Framerate Changes
Downscale or change framerate during export.

**Implementation:**
- Add resolution presets (4K, 1080p, 720p, 480p, Custom)
- Add framerate selector (24, 30, 60 fps, etc.)
- Use FFmpeg scale filter and fps parameter
- Show output size estimate

---

## Batch Operations

### 11. Batch Rename Patterns ✅ **IMPLEMENTED**
More advanced templates with regex support.

**Implementation:**
- ✅ Create `models/rename_pattern.dart` with pattern model and predefined patterns
- ✅ Create `utils/rename_utils.dart` for pattern parsing and variable substitution
- ✅ Update `FileItem` to include rename pattern fields
- ✅ Integrate pattern application in `FFmpegExportService`
- ✅ Support variables: {name}, {episode}, {season}, {year}, {date}, {index}, {ext}
- ✅ Variable padding support (e.g., {episode:3} = 001)
- ✅ Pattern validation with error checking
- ✅ Predefined patterns for TV shows, movies, anime
- ✅ Add comprehensive unit tests

### 12. Auto-Detect Patterns ✅ **IMPLEMENTED**
Automatically select tracks based on rules (e.g., "always include Japanese audio").

**Implementation:**
- ✅ Create `models/auto_detect_rule.dart` with rule model and enums
- ✅ Create `services/rule_service.dart` for rule evaluation and application
- ✅ Support rule types: audio, subtitle, video
- ✅ Support conditions: language, title, codec, channels
- ✅ Support actions: select, deselect, set default
- ✅ Priority-based rule ordering
- ✅ Enable/disable individual rules
- ✅ Apply rules automatically when files are added
- ✅ Predefined rules for common scenarios
- ✅ Add comprehensive unit tests

### 13. Import/Export Configurations ✅ **IMPLEMENTED**
Save entire batch setups to JSON files for reuse.

**Implementation:**
- ✅ Create `models/batch_configuration.dart` with full configuration model
- ✅ Create `services/config_service.dart` for import/export operations
- ✅ Export configuration to JSON with all selections and settings
- ✅ Import configuration to restore exact setup
- ✅ Include file selections, profiles, rules, and preferences
- ✅ Configuration metadata (name, description, date, version)
- ✅ Configuration validation on import
- ✅ Default configuration directory management
- ✅ Add comprehensive unit tests

### 14. Multi-Profile Export
Export each file with multiple different configurations at once.

**Implementation:**
- Select multiple profiles per file
- Queue exports for each profile
- Generate output with profile name suffix
- Show progress for all profile exports

---

## Advanced Features

### 15. Chapter Editing
View, edit, or remove chapter markers.

**Implementation:**
- Parse chapters from FFprobe
- Show chapter list with timestamps and titles
- Allow edit/delete/reorder chapters
- Write chapters back with FFmpeg metadata

### 16. Metadata Editor ✅ **IMPLEMENTED**
Edit file metadata, track titles, languages.

**Implementation:**
- ✅ Create `models/metadata.dart` with FileMetadata and TrackMetadata classes
- ✅ Update `FileItem` to include metadata fields
- ✅ Update `FFprobeService` to extract metadata using JSON format
- ✅ Create `MetadataEditorDialog` widget for editing
- ✅ Integrate edit button in `FileCard` widget
- ✅ Update `FFmpegExportService` to write metadata using `-metadata` parameters
- ✅ Support for file-level metadata: title, artist, album, date, genre, comment
- ✅ Support for track-level metadata: language, title

### 17. Audio/Subtitle Sync
Adjust timing offsets for out-of-sync tracks.

**Implementation:**
- Add offset input per audio/subtitle track (milliseconds)
- Use FFmpeg `-itsoffset` parameter
- Preview sync with built-in player
- Auto-detect sync issues

### 18. Subtitle Format Conversion
Convert between ASS/SRT/SUP formats.

**Implementation:**
- Detect subtitle format from codec
- Add target format selector
- Use FFmpeg subtitle conversion
- Preserve styling where possible

### 19. MKV Optimization
Reorder streams, optimize header compression.

**Implementation:**
- Run mkvpropedit for header optimization
- Reorder streams by type (video, audio, subs)
- Remove unnecessary metadata
- Show file size savings

### 20. Verification Mode ✅ **IMPLEMENTED**
Check exported files for errors after completion.

**Implementation:**
- ✅ Create `services/verification_service.dart` for file verification
- ✅ Run FFprobe on exported files to verify stream counts
- ✅ Verify stream counts match expected (video, audio, subtitle)
- ✅ Check for corruption/errors using FFmpeg integrity check
- ✅ Generate verification report with pass/fail status
- ✅ Mark files with issues in UI with verification badge
- ✅ Add verification toggle in settings dialog
- ✅ Display verification status in file card subtitle

---

## UI/UX Enhancements

### 21. Dual Pane Mode
Show source vs destination comparison.

**Implementation:**
- Split screen layout
- Left pane: source file details
- Right pane: output file preview
- Show differences in tracks/metadata

### 22. File Preview ✅ **IMPLEMENTED**
Built-in file information viewer to preview files before export.

**Implementation:**
- ✅ Created `FilePreviewDialog` widget for comprehensive file information display
- ✅ Displays file details: path, size, duration, format, availability status
- ✅ Shows video track information: codec, resolution
- ✅ Shows audio track information: language, codec, channels, selected/default status
- ✅ Shows subtitle track information: language, codec, selected/default status
- ✅ Displays file and track metadata when available
- ✅ Visual indicators for selected and default tracks
- ✅ "Open Location" button to open file directory in Windows Explorer
- ✅ Integrated preview button in file cards (info icon)
- ✅ Responsive dialog with scrollable content
- ✅ Comprehensive widget tests (12 test cases) covering:
  - File information display
  - Video/audio/subtitle track sections
  - Metadata display
  - Selected/default track indicators
  - Dialog navigation and closing
  - Edge cases (missing tracks, empty metadata)

**Note:** This implementation provides detailed file information viewing. For actual video playback, the video_player package would need to be added, which requires platform-specific setup and is beyond the scope of this implementation.

### 23. Waveform Visualization
Visual representation of audio tracks.

**Implementation:**
- Generate waveform from audio stream
- Show waveform for each audio track
- Click to jump to position
- Useful for detecting silence/issues

### 24. Export Queue Management ✅ **IMPLEMENTED**
Pause/resume/reorder export queue.

**Implementation:**
- ✅ Created `ExportQueueItem` model with status tracking
- ✅ Created `ExportQueueService` for queue management with stream-based updates
- ✅ Created `ExportQueuePanel` widget for queue visualization
- ✅ Drag-and-drop reordering with ReorderableListView
- ✅ Pause/resume/cancel individual queue items
- ✅ Move up/down and priority management
- ✅ Status indicators with color coding (pending, processing, paused, completed, failed, cancelled)
- ✅ Queue persistence support with JSON serialization
- ✅ Real-time progress updates in queue display
- ✅ Clear queue and remove individual items
- ✅ Comprehensive unit tests (25+ test cases) covering:
  - Queue item creation and serialization
  - Adding, removing, and clearing items
  - Status updates and lifecycle management
  - Priority-based sorting and reordering
  - Pause/resume/cancel operations
  - Stream-based notifications

### 25. Estimated Export Times
Show time remaining based on file size and system performance.

**Implementation:**
- Track export speed (MB/s or fps)
- Calculate ETA for current file
- Show total ETA for all pending files
- Learn from historical performance

---

## Integration Features

### 26. Watch Folder
Automatically process files added to a specific folder.

**Implementation:**
- Select watch folder path
- Monitor folder with FileSystemWatcher
- Auto-add files matching criteria
- Option to auto-export with default profile

### 27. Command-Line Interface
Automate exports via CLI.

**Implementation:**
- Create CLI entry point separate from GUI
- Accept arguments for file paths, selections, output
- Support batch files/scripts
- Output JSON results for scripting

### 28. Presets Import
Import HandBrake or other tool presets.

**Implementation:**
- Parse HandBrake JSON/XML presets
- Map HandBrake settings to FFmpeg parameters
- Show compatibility warnings
- Convert and save as native profiles

### 29. Better Notifications ✅ **IMPLEMENTED**
Desktop notifications when exports complete.

**Implementation:**
- ✅ Created `NotificationService` for managing notifications
- ✅ Windows desktop notifications using PowerShell and Windows Toast API
- ✅ Enhanced in-app SnackBar notifications with detailed statistics
- ✅ Notification includes: success/failed/cancelled counts and duration
- ✅ Configurable via Settings dialog (enable/disable desktop notifications)
- ✅ Different notification types: success (✓), error (✗), warning (⚠)
- ✅ Graceful fallback for non-Windows platforms
- ✅ Comprehensive unit tests for notification formatting and logic

---

### 30. Batch Codecs Apply ✅ **IMPLEMENTED**
Apply selected video/audio codec settings to multiple files at once.

**Implementation:**
- ✅ Extended `CodecSettingsDialog` with batch mode support and "Apply to All" option
- ✅ Added batch toolbar actions in the batch panel: Video Codec and Audio Codec Settings buttons
- ✅ Created `_showBatchVideoCodecDialog` and `_showBatchAudioCodecDialog` methods in main.dart
- ✅ Batch apply respects the dialog settings and applies to all loaded files
- ✅ Added comprehensive widget tests for batch codec dialog functionality
- ✅ Visual feedback with file count display in batch mode dialog title

### 31. Two-Stage Export Pipeline ✅ **IMPLEMENTED** (Phase 5)
Stage 1: Fast muxer/remux (copies streams). Stage 2: Optional re-encoding for quality/codec changes.

**Implementation:**
- ✅ Split export into two distinct stages in `FFmpegExportService`
- ✅ Stage 1: Remux with muxer auto-detection based on output format (libx264 → mp4box, libx265 → hevc_mp42cf, etc.)
- ✅ Stage 2: Re-encode triggered only when codec conversion or quality preset specified
- ✅ Independent stdout/stderr capture for each stage
- ✅ Progress tracking for both stages (Stage 1 remux, Stage 2 encode)
- ✅ Per-file logging with both stage commands and output
- ✅ Timing breakdown: Stage 1 duration, Stage 2 duration, total duration

### 32. Auto-Fix Codec Compatibility ✅ **IMPLEMENTED** (Phase 5)
Automatically transcode incompatible codecs when output format is MP4 or WebM.

**Implementation:**
- ✅ Created `_getCompatibilityIssues()` method in `FFmpegExportService`
- ✅ Automatic codec detection: MP4 (H.264/HEVC/MPEG-4/AV1 video; AAC/AC3/ALAC/MP3 audio), WebM (VP9/AV1 video; Opus/Vorbis audio), MKV (all)
- ✅ Auto-transcode to compatible codec when incompatible codec + incompatible container selected
- ✅ Auto-drop subtitle tracks if unsupported by container
- ✅ Preflight compatibility check before export with user-visible warnings
- ✅ When auto-fix enabled, incompatible codecs hidden from UI dropdown
- ✅ Logged in export summary for transparency

### 33. Dynamic Codec Filtering ✅ **IMPLEMENTED** (Phase 5)
When auto-fix enabled and MP4/WebM format selected, hide incompatible codecs from codec settings UI.

**Implementation:**
- ✅ Added `_isVideoCodecCompatible()` and `_isAudioCodecCompatible()` methods in `CodecSettingsDialog`
- ✅ Filter video codec list: `VideoCodec.values.where((codec) => _isVideoCodecCompatible(codec))`
- ✅ Filter audio codec list: `AudioCodec.values.where((codec) => _isAudioCodecCompatible(codec))`
- ✅ Display rules: MP4 (H.264, HEVC, MPEG-4, AV1), WebM (VP9, AV1), MKV (all)
- ✅ Parameters passed from main.dart: `outputFormat` and `autoFixEnabled`
- ✅ Only filters when auto-fix is ON; shows all codecs when auto-fix OFF or MKV format
- ✅ Prevents user confusion by hiding unusable codec options

### 34. Codec Preset System for All Codecs ✅ **IMPLEMENTED** (Phase 5)
Quick preset chips (Speed/Balanced/Quality) for H.264, H.265, VP9, and AV1 encoders.

**Implementation:**
- ✅ Added "Encoding Presets" section in codec settings dialog for H.264/H.265/VP9
- ✅ Speed preset: preset=fast, CRF=28 (~4x realtime)
- ✅ Balanced preset: preset=medium, CRF=23 (~2x realtime) - Recommended
- ✅ Quality preset: preset=slow, CRF=20 (~1x realtime)
- ✅ Quick chip selection with automatic CRF value population
- ✅ Manual preset dropdown for advanced users (ultrafast, fast, medium, slow, veryslow)
- ✅ CRF adjustment field (0-51 range, lower = better quality)
- ✅ Applied settings summary showing codec, CRF, and preset at bottom
- ✅ AV1: Encoder choice (libsvtav1 vs libaom-av1) + profile presets with `-cpu-used` mapping
- ✅ Smooth codec switching resets presets to avoid conflicts

### 35. Comprehensive Export Logging ✅ **IMPLEMENTED** (Phase 5)
Per-file detailed logs with commands, stdout/stderr, timing, and progress for debugging and verification.

**Implementation:**
- ✅ Per-file logs created in `logs/` directory next to output file (e.g., `output.mkv.log`)
- ✅ Log contains: Stage 1 FFmpeg command, Stage 1 stdout/stderr, Stage 2 FFmpeg command (if applicable), Stage 2 stdout/stderr
- ✅ Progress lines logged as they arrive (both `-progress` stdout and stderr `time=` fallback)
- ✅ Timing info: Stage 1 duration, Stage 2 duration, total duration
- ✅ Status: Success, Failure (error message), or Cancelled by user
- ✅ Compatibility issues logged in summary if auto-fix applied
- ✅ File size before/after for compression ratio reference
- ✅ All logs preserve for diagnostics even on failure

### 36. Cancellation Handling ✅ **IMPLEMENTED** (Phase 5)
Proper exit code mapping for cancellation; displays user-friendly message instead of error.

**Implementation:**
- ✅ Map exit codes to cancellation: -1, 130 (SIGINT), 255, 3221225786 (Windows CTRL+C), -1073741510 (Windows termination)
- ✅ Display message: "Cancelled by user" instead of "Export failed"
- ✅ Log status shows "Cancelled" in export summary
- ✅ Distinguish user cancellation from actual errors
- ✅ UI shows cancellation status clearly in file card and export summary

### 37. Export Summary with Encoding Details ✅ **IMPLEMENTED** (Phase 5)
Export summary dialog displays video/audio codec selections, CRF, presets, and bitrate details for verification before export.

**Implementation:**
- ✅ Enhanced `generateExportSummary()` in FFmpegExportService
- ✅ Per-file section with: input file, output file, estimated output size
- ✅ Video codec section (if re-encoding): codec name, CRF value, preset, bitrate
- ✅ Audio codec section per track: codec name, bitrate (kbps), channels, sample rate
- ✅ Quality preset summary: Fast (CRF 28), Balanced (CRF 23), Quality (CRF 20)
- ✅ Container format info: MP4, MKV, WebM (shows what will be used)
- ✅ Auto-fix compatibility warnings: lists codecs that will be auto-transcoded
- ✅ Total file count and cumulative statistics (total removed audio/subs, etc.)
- ✅ Clear, formatted output for user review before proceeding



## Implementation Priority Suggestions

### **Phase 1 - Core Enhancements** ✅ **COMPLETED**
1. ✅ Export Profiles (Feature #2) - **COMPLETED**
2. ✅ Video Stream Selection (Feature #6) - **COMPLETED**
3. ✅ Metadata Editor (Feature #16) - **COMPLETED**

### **Phase 2 - Advanced Export** ✅ **COMPLETED**
4. ✅ Codec Conversion (Feature #7) - **COMPLETED**
5. ✅ Quality/CRF Presets (Feature #8) - **COMPLETED**
6. ✅ Verification Mode (Feature #20) - **COMPLETED**

### **Phase 3 - Batch Power** ✅ **COMPLETED** (Automation)
7. ✅ Advanced Rename Patterns (Feature #11) - **COMPLETED**
8. ✅ Auto-Detect Rules (Feature #12) - **COMPLETED**
9. ✅ Configuration Import/Export (Feature #13) - **COMPLETED**

### **Phase 4 - UI Polish** (User Experience) ✅ **COMPLETED**
10. ✅ File Preview (Feature #22) - **COMPLETED**
11. ✅ Export Queue Management (Feature #24) - **COMPLETED**
12. ✅ Better Notifications (Feature #29) - **COMPLETED**
13. ✅ Batch Codec/Quality Apply (Feature #30) - **COMPLETED**

### **Phase 5a - Export Stability & Codec Enhancements** (Post-Phase 4) ✅ **COMPLETED**
14. ✅ Two-Stage Export Pipeline (Feature #31) - **COMPLETED**
15. ✅ Auto-Fix Codec Compatibility (Feature #32) - **COMPLETED**
16. ✅ Dynamic Codec Filtering (Feature #33) - **COMPLETED**
17. ✅ Codec Preset System for All Codecs (Feature #34) - **COMPLETED**
18. ✅ Comprehensive Export Logging (Feature #35) - **COMPLETED**
19. ✅ Cancellation Handling (Feature #36) - **COMPLETED**
20. ✅ Export Summary with Encoding Details (Feature #37) - **COMPLETED**

---

### **Phase 5b - Consolidated Backlog** (All Remaining Planned Features)

**Status:** Planning phase - features documented but not yet scheduled for implementation  
**Total Features:** 17 across 5 categories  
**Documentation:**
- Tracking issue: `docs/issues/PHASE5_TRACKING_ISSUE.md`
- Planning guide: `docs/PHASE5_PLANNING.md` (detailed implementation guidance)
- Feature reference: `docs/PHASE5_FEATURES.md` (quick lookup table)
- Phase summary: `docs/PHASES_REPORT.md` (Phase 5 section)

The remaining planned features are grouped into a single phase for clarity and scheduling. Items are organized by category; numbering aligns with the roadmap above.

- Quality of Life
  1. Recent Files List (Feature #1)
  2. Undo/Redo (Feature #3)
  3. Search/Filter (Feature #4)
  4. Sorting Options (Feature #5)

- Export Enhancements
  5. Trim/Cut Functionality (Feature #9)
  6. Resolution/Framerate Changes (Feature #10)

- Batch Operations
  7. Multi-Profile Export (Feature #14)

- Advanced Features
  8. Chapter Editing (Feature #15)
  9. Audio/Subtitle Sync (Feature #17)
  10. Subtitle Format Conversion (Feature #18)
  11. MKV Optimization (Feature #19)

- UI/UX Enhancements
  12. Dual Pane Mode (Feature #21)
  13. Waveform Visualization (Feature #23)
  14. Estimated Export Times (Feature #25)

- Integration Features
  15. Watch Folder (Feature #26)
  16. Command-Line Interface (Feature #27)
  17. Presets Import (Feature #28)


## Notes for Implementation

- Each feature should be implemented in its own branch
- Add unit tests for service-layer features
- Add widget tests for UI features
- Update documentation (README.md, FEATURES.md) when adding features
- Consider backward compatibility with existing configurations
- Keep the modular structure - add new services/widgets as separate files

## Contributing

When implementing a feature:
1. Create a new branch: `feature/name-of-feature`
2. Follow the existing code structure (models, services, widgets, utils)
3. Add tests if applicable
4. Update this file to mark feature as implemented
5. Submit a pull request with clear description

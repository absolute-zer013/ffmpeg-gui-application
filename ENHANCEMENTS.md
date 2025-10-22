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

### 22. File Preview
Built-in video player to preview files before export.

**Implementation:**
- Integrate video player library (e.g., video_player package)
- Show preview in dialog or side panel
- Quick seek to verify content
- Show specific track playback

### 23. Waveform Visualization
Visual representation of audio tracks.

**Implementation:**
- Generate waveform from audio stream
- Show waveform for each audio track
- Click to jump to position
- Useful for detecting silence/issues

### 24. Export Queue Management
Pause/resume/reorder export queue.

**Implementation:**
- Show queue as separate panel
- Drag-drop to reorder pending files
- Pause/resume individual exports
- Save queue state between sessions

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

### 29. Notification System
Desktop notifications when exports complete.

**Implementation:**
- Use Windows notifications API
- Only notify on all complete or on errors

---

### 30. Batch Codec/Quality Apply
Apply selected video/audio codec and audio quality presets to multiple files at once.

**Implementation:**
- Add an "Apply to selected files" option in `CodecSettingsDialog` to bulk-apply current selections.
- Provide batch toolbar actions: Set Video Codec, Set Audio Codec, Set Audio Quality (presets).
- Extend `ExportProfile` (if necessary) to include codec and quality preset fields for easy reuse.
- Ensure `FFmpegExportService` respects the batch-applied settings per file.
- Add unit tests: bulk apply preserves per-file overrides; batch apply integrates with profiles and configurations.


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

### **Phase 4 - UI Polish** (User Experience)
10. File Preview (Feature #22)
11. Export Queue Management (Feature #24)
12. Better Notifications (Feature #29)
13. Batch Codec/Quality Apply (leverages Features #7 and #8)
  - Add "Apply to selected files" action in the Codec Settings dialog
  - Provide batch toolbar actions: Set Video Codec, Set Audio Codec, Set Audio Quality
  - Respect per-file overrides; enable quick bulk updates across the selection

---

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

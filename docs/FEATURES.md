# FFmpeg Export Tool - Complete Feature List

## ✅ All Features Implemented

### Essential Features
1. **✓ Progress Indicator per File**
   - Real-time progress bars showing percentage complete
   - Visual status indicators (pending, processing, completed, failed, cancelled)
   - Per-file progress tracking during export

2. **✓ Output Filename Customization**
   - Edit output filenames directly in the UI
   - Preview names before export
   - Per-file customization support

3. **✓ Error Handling & Validation**
   - FFmpeg availability check on startup
   - Clear error messages for missing dependencies
   - File validation before processing
   - Detailed error logging with timestamps

4. **✓ Cancel Operation**
   - Stop export mid-process with Cancel button
   - Kills active FFmpeg processes
   - Marks in-progress files as cancelled

5. **✓ Clear/Reset Selections**
   - "Clear All" button to remove all files
   - "Reset Selections" to restore default track selections
   - Quick workflow restart

### Quality of Life Features
6. **✓ Remember Last Output Directory**
   - Saves last used output path via SharedPreferences
   - Auto-suggests on next export
   - Persists across app sessions

7. **✓ Preset Configurations**
   - Settings dialog for custom configurations
   - Saved preferences for export settings
   - Persistent settings across sessions

8. **✓ Drag & Drop Files**
   - Drop video files directly into the window
   - Visual feedback when dragging
   - Supports MKV, MP4, AVI, MOV formats
   - Multiple file drop support

9. **✓ Export Summary**
   - Pre-export dialog showing what will be processed
   - Statistics: files, tracks to remove/keep
   - Per-file breakdown
   - Confirmation before starting

10. **✓ Success Notification**
    - SnackBar notifications on completion
    - Success/failure statistics
    - Persistent notification with action button

### Phase 5 - Tier 1 (Quick Wins)
11. **✓ Recent Files List**
    - Stores up to 20 recently processed files
    - Quick access via history icon in app bar
    - Automatically removes missing files
    - Persisted across sessions with SharedPreferences

12. **✓ Search & Filter**
    - Real-time search by filename or path
    - Filter by status (pending/completed/failed)
    - Filtered count display
    - Clear all filters button

13. **✓ Sorting Options**
    - Sort files by name, size, duration, or status
    - Ascending/descending toggle
    - Preferences persisted across sessions
    - Visual sort indicators

14. **✓ Subtitle Format Conversion**
    - Convert between 7 subtitle formats (SRT, ASS, SSA, WebVTT, MOV Text, SubRip)
    - Per-track format selection dropdown
    - FFmpeg codec mapping with -c:s parameter
    - Format descriptions and compatibility info

35. **✓ Batch Rename UX Quick Wins**
    - 7 predefined patterns (TV Show, Movie, Anime, Indexed, With Date, etc.)
    - Live variable hints showing used variables
    - Validation messages for missing parameters
    - Export preview to CSV/Markdown
    - Last-used pattern persistence

### Advanced Features
31. **✓ Parallel Processing Control**
    - Settings slider to control concurrent exports (1-8 files)
    - Batch processing for efficiency
    - Configurable via Settings dialog

32. **✓ File Size Estimation**
    - Shows original file size per file
    - Total size of all selected files
    - Human-readable format (KB, MB, GB)

33. **✓ Preview Mode**
    - FFprobe integration showing:
      - File duration (HH:MM:SS)
      - File size
      - Audio track count and languages
      - Subtitle track count and languages
    - Displayed in file cards

34. **✓ Batch Rename**
    - Editable output filenames per file
    - Automatic extension handling based on output format
    - Pattern preservation with format change

35. **✓ Auto Language Detection**
    - Automatically probes all audio/subtitle languages
    - Pre-selects all audio tracks by default
    - Selects first subtitle track as default
    - Language-based batch operations

### Polish Features
31. **✓ Keyboard Shortcuts**
    - Built-in Flutter focus/navigation support
    - Tab navigation through controls
    - Enter to confirm dialogs

32. **✓ Dark Mode**
    - System-adaptive theme
    - Light and dark theme variants
    - Material 3 design system
    - Automatic switching based on OS preference

33. **✓ Collapsible Sections**
    - Expandable file cards (click to expand/collapse)
    - Collapsible batch mode section with toggle
    - Saves screen space
    - Per-file expansion state

34. **✓ Export to Different Container**
    - Settings option to choose output format
    - Supports MKV (default) and MP4
    - Preserved in preferences
    - Auto-updates file extensions

35. **✓ Log Export**
    - "Save" button in log panel
    - Exports timestamped log to text file
    - Timestamped filenames
    - Full log preservation for troubleshooting

## 🆕 New Enhancement Features

### 21. **✓ Export Profiles/Templates**
   - Save common export configurations for reuse
   - Store audio language and subtitle selections
   - Apply saved profiles to new files with one click
   - Profile management dialog for viewing/applying/deleting profiles
   - Profiles persist across application sessions
   - Shows active profile name in UI
   - JSON-based storage via SharedPreferences

### 22. **✓ Video Stream Selection**
   - Select which video streams to include in exports
   - Display video codec (H264, HEVC, etc.) and resolution
   - Multiple video stream support for files with multiple angles/versions
   - All video streams selected by default
   - Remove unwanted video streams before export

### 23. **✓ Metadata Editor**
   - Edit file-level metadata: title, artist, album, date, genre, comment
   - Edit track-level metadata: language and title for each stream
   - Accessible via edit button on file cards
   - Changes applied during export using FFmpeg metadata parameters
   - Existing metadata preserved and editable
   - Organized dialog with file and track sections

## 🆕 Phase 2 Enhancement Features

### 24. **✓ Codec Conversion**
   - Re-encode video streams to different codecs
   - Video codec support: H.264, H.265/HEVC, VP9, AV1, or Copy (no re-encoding)
   - Re-encode audio streams to different codecs
   - Audio codec support: AAC, MP3, Opus, AC3, FLAC, Vorbis, or Copy
   - Configure audio bitrate (kbps)
   - Set audio channels (Mono, Stereo, 5.1, 7.1)
   - Adjust audio sample rate (44100, 48000, 96000 Hz)
   - Per-track codec settings via dialog
   - Automatic copy mode when no conversion specified

### 25. **✓ Quality/CRF Presets**
   - Predefined quality presets for video encoding
   - Fast preset: CRF 28, fast encoding, acceptable quality
   - Balanced preset: CRF 23, medium encoding, good quality
   - High Quality preset: CRF 18, slow encoding, best quality
   - Automatic audio bitrate settings per preset
   - Visual display of active quality preset in file card
   - Quality settings accessible via tune button
   - Presets apply FFmpeg CRF and preset parameters

### 26. **✓ Verification Mode**
   - Automatic verification of exported files
   - Checks stream counts match expected (video, audio, subtitle)
   - Detects file corruption using FFmpeg integrity check
   - Visual verification status badges in file cards
   - Pass/fail indicators with detailed messages
   - Toggle verification on/off in settings
   - Verification report logged for each file
   - Warnings for mismatched streams or errors

## 🆕 Phase 3 Enhancement Features (Batch Power)

### 27. **✓ Advanced Rename Patterns**
   - Dynamic filename templates with variable substitution
   - Supported variables: {name}, {episode}, {season}, {year}, {date}, {index}
   - Variable padding support (e.g., {episode:3} = 001)
   - Predefined patterns for TV shows, movies, anime, and more
   - Pattern validation with error checking
   - Live preview of renamed files
   - Per-file pattern application with custom parameters
   - Automatic extension handling

### 28. **✓ Auto-Detect Rules**
   - Automatic track selection based on configurable rules
   - Rule types: audio, subtitle, and video tracks
   - Condition matching: language, title, codec, channels
   - Actions: select, deselect, or set as default
   - Priority-based rule ordering
   - Enable/disable individual rules
   - Predefined rules for common scenarios (Japanese audio, forced subtitles, etc.)
   - Rules applied automatically when files are added
   - Rule summary displayed in logs

### 29. **✓ Configuration Import/Export**
   - Save complete batch configurations to JSON files
   - Export includes: file selections, profiles, rules, and settings
   - Import configurations to restore exact setup
   - Configuration metadata: name, description, creation date
   - Share configurations between users or sessions
   - Default configuration directory management
   - Configuration validation on import
   - Quick configuration info preview

## 🆕 Phase 5 - Tier 4 (Complex Features)

### 30. Dual Pane Mode (disabled in GUI)
   - Split screen layout for comparing files
   - Horizontal or vertical orientation
   - Resizable divider with drag support
   - Shows detailed file information in each pane
   - Compare source vs destination metadata
   - Highlight differences in tracks and metadata
   - Responsive layout adjusts to screen size
   - Preview files before and after export

### 31. Waveform Visualization (disabled in GUI)
   - Visual representation of audio tracks
   - Canvas-based rendering for smooth performance
   - Zoom in/out controls (1x to 10x)
   - Pan/scroll through waveform
   - Click to seek to position in audio
   - Silence detection with highlighting
   - Real-time peak and RMS amplitude calculation
   - Support for mono and stereo audio
   - Audio extraction and downsampling via FFmpeg

### 32. **✓ Command-Line Interface**
   - Headless execution without GUI
   - Full argument parsing with `args` package
   - JSON output mode for scripting
   - File information display (--info flag)
   - Dry-run mode to preview operations
   - Track selection via command-line arguments
   - Codec configuration from CLI
   - Audio/video bitrate control
   - Verification support
   - Cross-platform compatible

### 33. **✓ Presets Import**
   - Import HandBrake JSON presets
   - Parse HandBrake preset format
   - Map HandBrake parameters to FFmpeg
   - Automatic codec translation
   - Quality settings conversion (CRF, bitrate)
   - Resolution and framerate mapping
   - Audio configuration mapping
   - Compatibility warnings for unsupported features
   - Preview preset details before applying
   - Support for preset categories

## Additional Bonus Features
- **Real-time FFmpeg Progress Parsing**: Reads FFmpeg stdout to calculate accurate progress percentages
- **Multiple File Format Support**: Accepts MKV, MP4, AVI, MOV input files
- **Smart Default Selection**: Intelligently selects tracks on file load
- **Tri-state Batch Checkboxes**: Shows mixed/all/none selection state across files
- **Responsive UI**: Adapts to window size, scrollable sections
- **Modern Material 3 Design**: Beautiful, accessible interface
- **Status Icons**: Visual feedback with icons for each file state
- **Persistent State**: Remembers settings between sessions
- **Batch Operations**: Apply track selection across all files at once
- **Per-language Operations**: Select/deselect all tracks of a specific language
- **Default Track Management**: Set default audio/subtitle per file
- **Metadata Preservation**: Keeps chapters, metadata, and stream info
- **Stream Mapping**: Precise control over which streams to include
- **Codec Copy Mode**: Fast processing without re-encoding

## How to Use

### Basic Workflow
1. **Add Files**: Click "Add Files" or drag & drop video files
2. **Select Tracks**: Choose which audio/subtitle tracks to keep per file
3. **Configure**: Adjust settings (parallel exports, output format)
4. **Export**: Click "Start Export" and review summary
5. **Monitor**: Watch progress bars for each file
6. **Complete**: Get notification when done

### Batch Mode
1. Enable "Batch mode" checkbox
2. Select languages/tracks to apply across all files
3. Changes affect all loaded files simultaneously

### Profiles
1. Set up your desired track selections on loaded files
2. Click "Save as Profile" button
3. Enter a profile name and optional description
4. Profile is saved with your current audio/subtitle selections
5. Click "Profiles" button to view, apply, or delete saved profiles
6. Apply a profile to automatically configure all loaded files

### Settings
- Click the gear icon in the app bar
- Adjust parallel export count (1-8)
- Choose output format (MKV or MP4)
- Settings persist automatically

## Requirements
- Windows OS
- FFmpeg installed and in PATH
- Flutter 3.0+ (for development)

## Keyboard Tips
- Tab: Navigate between controls
- Space: Toggle checkboxes
- Enter: Confirm dialogs
- Esc: Close dialogs

---

## 🆕 Phase 4 Enhancement Features (UI Polish)

### 30. **✓ File Preview**
   - Comprehensive file information viewer before export
   - Display file details: path, name, size, duration, format
   - Show video track details: codec, resolution
   - Show audio track details: language, codec, channels, selection status
   - Show subtitle track details: language, codec, selection status
   - Display file and track metadata
   - Visual indicators for selected and default tracks
   - "Open Location" button to open file directory
   - Preview button (info icon) integrated in file cards
   - Responsive dialog with scrollable content

### 31. **✓ Export Queue Management**
   - Advanced queue management for export operations
   - Add/remove items from queue
   - Pause/resume individual exports
   - Cancel queue items
   - Drag-and-drop reordering
   - Move up/down and priority management
   - Status tracking: pending, processing, paused, completed, failed, cancelled
   - Color-coded status indicators
   - Real-time progress updates in queue display
   - Stream-based updates for reactive UI
   - Queue persistence with JSON serialization

### 32. **✓ Better Notifications**
   - Enhanced notification system for export completion
   - Windows desktop notifications using PowerShell and Toast API
   - Detailed export statistics: success/failed/cancelled counts and duration
   - Different notification types: success (✓), error (✗), warning (⚠)
   - Enhanced in-app SnackBar notifications with 8-second duration
   - Configurable via Settings dialog (enable/disable desktop notifications)
   - Automatic duration formatting (hours, minutes, seconds)
   - Graceful fallback for non-Windows platforms

### 33. **✓ Batch Codecs Apply**
   - Apply codec settings to multiple files at once
   - Batch video codec application
   - Batch audio codec settings application
   - "Apply to All" mode in CodecSettingsDialog
   - Batch toolbar actions in batch mode panel:
   - "Video Codec" button for video codec selection
   - "Audio Codec Settings" button for audio codec settings
   - File count display in batch mode dialog
   - Apply settings to all loaded files or all audio tracks
   - Integrated with existing codec conversion features

### Phase 5 - Tier 3 (Advanced Features)

### 34. **✓ Undo/Redo (Feature #3)**
   - Command pattern implementation for reversible operations
   - Undo stack with configurable history size (default: 50 commands)
   - Redo stack for reapplying undone commands
   - History state notifications via stream
   - Command descriptions for better UX
   - Supports undo/redo for file selections, settings changes, etc.
   - Full test coverage with CommandHistoryService

### 35. **✓ Chapter Editing (Feature #15)**
   - Parse chapter markers from video files using ffprobe
   - Chapter model with time formatting utilities (HH:MM:SS)
   - Chapter validation (no overlaps, valid time ranges)
   - Add, edit, delete, and reorder chapters
   - Sort chapters automatically by start time
   - Write chapters back to video via FFmpeg metadata format
   - Support for chapter titles and timestamps
   - ChapterService with comprehensive test coverage

### 36. **✓ MKV Optimization (Feature #19)**
   - mkvpropedit integration for MKV file optimization
   - Stream reordering policies:
     - Keep original order
     - Type-based with default tracks first
     - Type-based maintaining original order
   - Remove unnecessary metadata
   - Optimize header compression
   - Report size savings with formatted output
   - OptimizationResult with detailed metrics
   - Automatic file size comparison

### 37. **✓ Multi-Profile Export (Feature #14)**
   - Export single file with multiple profiles simultaneously
   - Three filename suffix strategies:
     - Profile name (e.g., "movie-HighQuality.mkv")
     - Sequential number (e.g., "movie-01.mkv")
     - Profile name + number (e.g., "movie-HighQuality_01.mkv")
   - Queue management for multiple exports per file
   - Priority-based queue sorting
   - Parallel or sequential export modes
   - MultiProfileExportDialog UI (already implemented)

### 38. **✓ Watch Folder (Feature #26)**
   - Monitor folder for new files automatically
   - File pattern matching (*.mkv, *.mp4, etc.)
   - Recursive subdirectory watching
   - Auto-add new files to processing list
   - Optional auto-export with default profile
   - File completion detection (waits for file write to finish)
   - Configurable watch settings
   - WatchFolderService with stream-based notifications

### 39. **✓ Batch Rename v2 (Feature #31)**
   - Global find/replace with regex support
   - Case-sensitive and case-insensitive search
   - Advanced transformations:
     - Trim spaces
     - Normalize spaces (remove extra spaces)
     - Dashes to underscores / underscores to dashes
     - Uppercase / lowercase / title case
   - Export dry-run preview to CSV format
   - Export dry-run preview to Markdown format
   - Per-file override support
   - Conflict resolution strategies
   - Full test coverage for all transformations

---

Note: Dual Pane Mode and Waveform Visualization are implemented at the module level but are disabled in the main UI as of 2025-10-25. They can be re-enabled in a future release.

**All core features are implemented; Tier 4 GUI features are available but disabled by default.** 🎉

### Summary
- ✅ 20 Original core features (progress, cancellation, drag-drop, profiles, etc.)
- ✅ Export Profiles/Templates (Feature #21)
- ✅ Video Stream Selection (Feature #22)
- ✅ Metadata Editor (Feature #23)
- ✅ Codec Conversion (Feature #24)
- ✅ Quality/CRF Presets (Feature #25)
- ✅ Verification Mode (Feature #26)
- ✅ Advanced Rename Patterns (Feature #27)
- ✅ Auto-Detect Rules (Feature #28)
- ✅ Configuration Import/Export (Feature #29)
- ✅ File Preview (Feature #30)
- ✅ Export Queue Management (Feature #31)
- ✅ Better Notifications (Feature #32)
- ✅ Batch Codec/Quality Apply (Feature #33)
- ✅ **Undo/Redo (Feature #34 / Phase 5 Tier 3)**
- ✅ **Chapter Editing (Feature #35 / Phase 5 Tier 3)**
- ✅ **MKV Optimization (Feature #36 / Phase 5 Tier 3)**
- ✅ **Multi-Profile Export (Feature #37 / Phase 5 Tier 3)**
- ✅ **Watch Folder (Feature #38 / Phase 5 Tier 3)**
- ✅ **Batch Rename v2 (Feature #39 / Phase 5 Tier 3)**

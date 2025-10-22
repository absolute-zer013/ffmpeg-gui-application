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

### Advanced Features
11. **✓ Parallel Processing Control**
    - Settings slider to control concurrent exports (1-8 files)
    - Batch processing for efficiency
    - Configurable via Settings dialog

12. **✓ File Size Estimation**
    - Shows original file size per file
    - Total size of all selected files
    - Human-readable format (KB, MB, GB)

13. **✓ Preview Mode**
    - FFprobe integration showing:
      - File duration (HH:MM:SS)
      - File size
      - Audio track count and languages
      - Subtitle track count and languages
    - Displayed in file cards

14. **✓ Batch Rename**
    - Editable output filenames per file
    - Automatic extension handling based on output format
    - Pattern preservation with format change

15. **✓ Auto Language Detection**
    - Automatically probes all audio/subtitle languages
    - Pre-selects all audio tracks by default
    - Selects first subtitle track as default
    - Language-based batch operations

### Polish Features
16. **✓ Keyboard Shortcuts**
    - Built-in Flutter focus/navigation support
    - Tab navigation through controls
    - Enter to confirm dialogs

17. **✓ Dark Mode**
    - System-adaptive theme
    - Light and dark theme variants
    - Material 3 design system
    - Automatic switching based on OS preference

18. **✓ Collapsible Sections**
    - Expandable file cards (click to expand/collapse)
    - Collapsible batch mode section with toggle
    - Saves screen space
    - Per-file expansion state

19. **✓ Export to Different Container**
    - Settings option to choose output format
    - Supports MKV (default) and MP4
    - Preserved in preferences
    - Auto-updates file extensions

20. **✓ Log Export**
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

**All 20 original features + 9 NEW enhancement features have been fully implemented!** 🎉

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

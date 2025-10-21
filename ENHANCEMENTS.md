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

### 6. Video Stream Selection
Choose specific video tracks (useful for files with multiple video streams).

**Implementation:**
- Extend `Track` model to include video tracks
- Update `FFprobeService.probeFile()` to detect video streams
- Add video track selection UI in `FileCard`
- Update `FFmpegExportService` to handle video stream mapping

### 7. Codec Conversion
Re-encode audio/video (e.g., convert HEVC to H.264, AC3 to AAC).

**Implementation:**
- Add codec selection dropdowns per track type
- Replace `-c copy` with specific codec parameters
- Add quality/bitrate settings
- Show estimated time/size based on codec

### 8. Quality Presets
CRF/bitrate settings for re-encoding.

**Implementation:**
- Add preset selector (Fast, Balanced, High Quality, Custom)
- Map presets to FFmpeg parameters (-crf, -preset, -bitrate)
- Show preview of expected quality/size trade-off

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

### 11. Batch Rename Patterns
More advanced templates with regex support.

**Implementation:**
- Add rename pattern input with variables: `{name}`, `{date}`, `{index}`, `{episode}`
- Support regex find/replace
- Live preview of renamed files
- Common presets (TV shows, movies, etc.)

### 12. Auto-Detect Patterns
Automatically select tracks based on rules (e.g., "always include Japanese audio").

**Implementation:**
- Create rule builder UI (if language = X, then select)
- Store rules as JSON
- Apply rules automatically when files are added
- Allow rule priorities/ordering

### 13. Import/Export Configurations
Save entire batch setups to JSON files for reuse.

**Implementation:**
- Export current file list + selections to JSON
- Import JSON to restore exact configuration
- Share configurations between users
- Include metadata (creation date, description)

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

### 16. Metadata Editor
Edit file metadata, track titles, languages.

**Implementation:**
- Show all metadata fields from FFprobe
- Allow editing title, artist, date, etc.
- Edit per-track metadata (language, title)
- Use FFmpeg `-metadata` parameter

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

### 20. Verification Mode
Check exported files for errors after completion.

**Implementation:**
- Run FFprobe on exported files
- Verify stream counts match expected
- Check for corruption/errors in output
- Generate verification report
- Mark files with issues

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

### 29. Cloud Storage Integration
Export directly to Google Drive/Dropbox.

**Implementation:**
- Add cloud storage package dependencies
- OAuth authentication flow
- Upload exported files to cloud
- Show upload progress
- Option to delete local after upload

### 30. Notification System
Desktop notifications, email, or Discord webhooks when exports complete.

**Implementation:**
- Use Windows notifications API
- Add optional email settings (SMTP)
- Discord webhook URL input
- Customize notification message
- Only notify on all complete or on errors

---

## Implementation Priority Suggestions

### **Phase 1 - Core Enhancements** (Most Impact)
1. ✅ Export Profiles (Feature #2) - **COMPLETED**
2. Video Stream Selection (Feature #6)
3. Metadata Editor (Feature #16)

### **Phase 2 - Advanced Export** (Power User Features)
4. Codec Conversion (Feature #7)
5. Quality/CRF Presets (Feature #8)
6. Verification Mode (Feature #20)

### **Phase 3 - Batch Power** (Automation)
7. Advanced Rename Patterns (Feature #11)
8. Auto-Detect Rules (Feature #12)
9. Configuration Import/Export (Feature #13)

### **Phase 4 - UI Polish** (User Experience)
10. File Preview (Feature #22)
11. Export Queue Management (Feature #24)
12. Better Notifications (Feature #30)

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

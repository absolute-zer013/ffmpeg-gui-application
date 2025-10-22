# Phase 5 — Feature Reference

Quick reference for all Phase 5 planned features. See `PHASE5_PLANNING.md` for detailed implementation guidance.

## Summary

**Status:** Planning phase (not yet implemented)  
**Total Features:** 17  
**Categories:** 5 (Quality of Life, Export Enhancements, Batch Operations, Advanced Features, UI/UX Enhancements, Integration Features)

## Feature List

### Quality of Life (4 features)

| # | Feature | Description | Priority | Complexity |
|---|---------|-------------|----------|------------|
| 1 | Recent Files List | Quick access to recently processed files | Medium | Low |
| 3 | Undo/Redo | Reverse selection changes with Ctrl+Z/Y | Medium | Medium |
| 4 | Search/Filter | Filter files by name, status, size, duration | Medium | Low |
| 5 | Sorting Options | Sort files by name, size, duration, status | Medium | Low |

### Export Enhancements (2 features)

| # | Feature | Description | Priority | Complexity |
|---|---------|-------------|----------|------------|
| 9 | Trim/Cut Functionality | Export portions of files with start/end timestamps | High | Medium |
| 10 | Resolution/Framerate Changes | Downscale video or change framerate during export | Medium | Medium |

### Batch Operations (1 feature)

| # | Feature | Description | Priority | Complexity |
|---|---------|-------------|----------|------------|
| 14 | Multi-Profile Export | Export each file with multiple profiles simultaneously | Medium | Medium |

### Advanced Features (4 features)

| # | Feature | Description | Priority | Complexity |
|---|---------|-------------|----------|------------|
| 15 | Chapter Editing | View, edit, reorder, remove chapter markers | Medium | Medium |
| 17 | Audio/Subtitle Sync | Adjust timing offsets for out-of-sync tracks | Medium | Medium |
| 18 | Subtitle Format Conversion | Convert between ASS, SRT, SUP formats | Medium | Low-Medium |
| 19 | MKV Optimization | Reorder streams, optimize header compression | Low | Medium |

### UI/UX Enhancements (3 features)

| # | Feature | Description | Priority | Complexity |
|---|---------|-------------|----------|------------|
| 21 | Dual Pane Mode | Split screen: source vs destination comparison | Low | High |
| 23 | Waveform Visualization | Visual representation of audio tracks | Low | High |
| 25 | Estimated Export Times | Show time remaining based on system performance | Medium | Medium |

### Integration Features (3 features)

| # | Feature | Description | Priority | Complexity |
|---|---------|-------------|----------|------------|
| 26 | Watch Folder | Automatically process files added to monitored folder | Medium | Medium |
| 27 | Command-Line Interface | Automate exports via CLI without GUI | Medium | High |
| 28 | Presets Import | Import HandBrake or other tool presets | Low | High |

## Quick Stats

### By Priority
- **High:** 1 feature (Trim/Cut)
- **Medium:** 12 features
- **Low:** 4 features

### By Complexity
- **Low:** 3 features (Recent Files, Search/Filter, Sorting)
- **Low-Medium:** 1 feature (Subtitle Format Conversion)
- **Medium:** 9 features
- **High:** 4 features (Dual Pane, Waveform, CLI, Presets Import)

### By Category
- **Quality of Life:** 4 features (23.5%)
- **Export Enhancements:** 2 features (11.8%)
- **Batch Operations:** 1 feature (5.9%)
- **Advanced Features:** 4 features (23.5%)
- **UI/UX Enhancements:** 3 features (17.6%)
- **Integration Features:** 3 features (17.6%)

## Implementation Tiers

### Tier 1: Quick Wins
Low effort, high impact features that can be implemented quickly:
- Feature #4: Search/Filter
- Feature #5: Sorting Options
- Feature #1: Recent Files List
- Feature #18: Subtitle Format Conversion

**Total:** 4 features | **Estimated:** 7-11 days

### Tier 2: Export Power
Medium effort export enhancements with high user value:
- Feature #9: Trim/Cut Functionality
- Feature #10: Resolution/Framerate Changes
- Feature #17: Audio/Subtitle Sync
- Feature #25: Estimated Export Times

**Total:** 4 features | **Estimated:** 15-22 days

### Tier 3: Advanced Features
Medium effort features for power users:
- Feature #3: Undo/Redo
- Feature #15: Chapter Editing
- Feature #19: MKV Optimization
- Feature #14: Multi-Profile Export
- Feature #26: Watch Folder

**Total:** 5 features | **Estimated:** 22-31 days

### Tier 4: Complex Features
High effort features with specialized use cases:
- Feature #21: Dual Pane Mode
- Feature #23: Waveform Visualization
- Feature #27: Command-Line Interface
- Feature #28: Presets Import

**Total:** 4 features | **Estimated:** 33-47 days

## Feature Details (Brief)

### 1. Recent Files List
Store last 10-20 processed file paths. Add dropdown menu for quick access. Uses SharedPreferences for persistence.

**FFmpeg:** None  
**Models:** RecentFile  
**Services:** RecentFilesService  
**UI:** Dropdown menu in app bar

### 3. Undo/Redo
Command pattern for reversible operations. History stack with undo (Ctrl+Z) and redo (Ctrl+Y) support.

**FFmpeg:** None  
**Models:** Command (abstract), specific command implementations  
**Services:** CommandHistoryService  
**UI:** Keyboard shortcuts, optional toolbar buttons

### 4. Search/Filter
Real-time search and filtering of file list. Filter by name, status (pending/completed/failed), size range, and duration.

**FFmpeg:** None  
**Models:** FilterCriteria  
**Services:** None (UI state)  
**UI:** Search TextField, filter chips

### 5. Sorting Options
Sort file list by name, size, duration, or status. Toggle ascending/descending. Persist sort preference.

**FFmpeg:** None  
**Models:** SortOption (enum), SortOrder (enum)  
**Services:** None (UI state)  
**UI:** Sort dropdown, sort order button

### 9. Trim/Cut Functionality
Set start and end timestamps to export file portions. Timeline slider for visual selection. FFmpeg `-ss` (start) and `-to` (end) parameters.

**FFmpeg:** `-ss`, `-to`  
**Models:** TrimSettings  
**Services:** None (integrate in FFmpegExportService)  
**UI:** Time inputs (HH:MM:SS), timeline slider

### 10. Resolution/Framerate Changes
Downscale video or change framerate. Presets: 4K, 1080p, 720p, 480p, or custom. FFmpeg scale filter and fps parameter.

**FFmpeg:** `-vf scale`, `-r`  
**Models:** ResolutionPreset, FramerateOption  
**Services:** None (integrate in FFmpegExportService)  
**UI:** Resolution/framerate dropdowns, size estimate

### 14. Multi-Profile Export
Export each file with multiple profiles. Queue multiple exports per file. Output files with profile name suffixes.

**FFmpeg:** None (multiple export invocations)  
**Models:** MultiProfileExportConfig  
**Services:** Extend ExportQueueService  
**UI:** Profile multi-select, queue management

### 15. Chapter Editing
View, edit, reorder, remove chapter markers. Parse from FFprobe, write with FFmpeg metadata format.

**FFmpeg:** `-f ffmetadata`  
**Models:** Chapter  
**Services:** ChapterService  
**UI:** Chapter editor dialog with list

### 17. Audio/Subtitle Sync
Adjust timing offsets in milliseconds. FFmpeg `-itsoffset` parameter per track.

**FFmpeg:** `-itsoffset`  
**Models:** SyncOffset  
**Services:** None (integrate in FFmpegExportService)  
**UI:** Offset inputs per track, preview button

### 18. Subtitle Format Conversion
Convert between ASS, SRT, SUP formats. Detect current format, select target. FFmpeg subtitle codec conversion.

**FFmpeg:** `-c:s` with format codec  
**Models:** SubtitleFormat (enum)  
**Services:** None (integrate in FFmpegExportService)  
**UI:** Format dropdown per subtitle track

### 19. MKV Optimization
Run mkvpropedit for header optimization. Reorder streams by type. Remove unnecessary metadata. Show size savings.

**FFmpeg:** `mkvpropedit`  
**Models:** OptimizationSettings  
**Services:** MkvOptimizationService  
**UI:** Optimization button, settings dialog, results

### 21. Dual Pane Mode
Split screen layout. Left pane: source file details. Right pane: output preview. Show differences in tracks/metadata.

**FFmpeg:** None  
**Models:** None  
**Services:** None  
**UI:** Split layout, comparison view

### 23. Waveform Visualization
Generate and display audio waveforms. Click to jump to position. Detect silence/issues. Canvas rendering.

**FFmpeg:** Audio data extraction  
**Models:** WaveformData  
**Services:** WaveformGenerationService  
**UI:** Waveform canvas widget

### 25. Estimated Export Times
Track export speed (MB/s or fps). Calculate ETA for current and pending files. Learn from historical performance.

**FFmpeg:** None (speed tracking)  
**Models:** PerformanceMetrics  
**Services:** PerformanceTrackingService  
**UI:** ETA display in progress, total ETA

### 26. Watch Folder
Monitor folder with FileSystemWatcher. Auto-add matching files. Optional auto-export with default profile.

**FFmpeg:** None  
**Models:** WatchFolderConfig  
**Services:** WatchFolderService  
**UI:** Settings for watch folder, status indicator

### 27. Command-Line Interface
CLI entry point separate from GUI. Accept file paths, selections, output as arguments. JSON output for scripting.

**FFmpeg:** Same as GUI  
**Models:** None (reuse existing)  
**Services:** CLIService  
**UI:** None (CLI only)

### 28. Presets Import
Parse HandBrake JSON/XML presets. Map HandBrake settings to FFmpeg parameters. Show compatibility warnings.

**FFmpeg:** Parameter mapping  
**Models:** ExternalPreset, PresetMapping  
**Services:** PresetImportService  
**UI:** Import dialog, mapping preview

## Related Documents

- **Tracking Issue:** `docs/issues/PHASE5_TRACKING_ISSUE.md`
- **Planning Guide:** `docs/PHASE5_PLANNING.md` (detailed implementation guidance)
- **Roadmap:** `docs/ENHANCEMENTS.md` (full descriptions)
- **Phase Summary:** `docs/PHASES_REPORT.md`
- **Current Features:** `docs/FEATURES.md`

---

**Last Updated:** 2025-10-22  
**Total Estimated Effort:** 77-111 days (approximately 3-5 months for single developer)

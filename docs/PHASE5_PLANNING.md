# Phase 5 — Consolidated Backlog Planning Guide

This document provides detailed planning guidance for Phase 5 features. It complements the tracking issue (`docs/issues/PHASE5_TRACKING_ISSUE.md`) and the roadmap (`docs/ENHANCEMENTS.md`).

## Overview

Phase 5 consolidates all remaining planned features from the roadmap into a single backlog for prioritization and future implementation. Unlike Phases 1–4 (which have been completed), Phase 5 features are documented but not yet scheduled.

**Status:** Planning phase  
**Total Features:** 17 across 5 categories  
**Dependencies:** None (Phases 1–4 complete)

## Feature Categories

### Quality of Life (4 features)

**Priority:** Medium  
**Complexity:** Low to Medium  
**User Impact:** High (daily workflow improvements)

1. **Recent Files List** (Feature #1)
   - Quick access to recently processed files
   - Stores last 10-20 file paths in SharedPreferences
   - Technical: Add recent files service, UI dropdown/menu
   - Estimated effort: Small (1-2 days)

2. **Undo/Redo** (Feature #3)
   - Reverse selection changes with Ctrl+Z/Y
   - Implement command pattern for state management
   - Technical: History stack, command objects, keyboard shortcuts
   - Estimated effort: Medium (3-5 days)

3. **Search/Filter** (Feature #4)
   - Filter files by name, status, size, duration
   - Real-time search with filtered count display
   - Technical: Search TextField, filter predicates, reactive UI
   - Estimated effort: Small (2-3 days)

4. **Sorting Options** (Feature #5)
   - Sort by name, size, duration, status
   - Ascending/descending toggle with persistence
   - Technical: Comparator functions, sort state management
   - Estimated effort: Small (1-2 days)

### Export Enhancements (2 features)

**Priority:** Medium to High  
**Complexity:** Medium  
**User Impact:** High (advanced export control)

9. **Trim/Cut Functionality** (Feature #9)
   - Export portions of files with start/end timestamps
   - Timeline slider for visual selection
   - Technical: FFmpeg `-ss` and `-to` parameters, time parsing
   - Estimated effort: Medium (4-6 days)

10. **Resolution/Framerate Changes** (Feature #10)
    - Downscale video or change framerate during export
    - Presets: 4K, 1080p, 720p, 480p, custom
    - Technical: FFmpeg scale filter, fps parameter, size estimation
    - Estimated effort: Medium (3-5 days)

### Batch Operations (1 feature)

**Priority:** Low to Medium  
**Complexity:** Medium  
**User Impact:** Medium (power user feature)

14. **Multi-Profile Export** (Feature #14)
    - Export each file with multiple profiles simultaneously
    - Queue management for multiple outputs per file
    - Technical: Queue service extension, filename suffixes, parallel tracking
    - Estimated effort: Medium (4-6 days)

### Advanced Features (4 features)

**Priority:** Low to Medium  
**Complexity:** Medium to High  
**User Impact:** Medium (specialized use cases)

15. **Chapter Editing** (Feature #15)
    - View, edit, reorder, remove chapter markers
    - Parse chapters from FFprobe, write with FFmpeg metadata
    - Technical: Chapter parser, editor dialog, FFmpeg chapter format
    - Estimated effort: Medium (5-7 days)

17. **Audio/Subtitle Sync** (Feature #17)
    - Adjust timing offsets for out-of-sync tracks
    - Millisecond precision, preview capability
    - Technical: FFmpeg `-itsoffset` parameter, sync detection
    - Estimated effort: Medium (4-6 days)

18. **Subtitle Format Conversion** (Feature #18)
    - Convert between ASS, SRT, SUP formats
    - Preserve styling where possible
    - Technical: FFmpeg subtitle conversion, format detection
    - Estimated effort: Small to Medium (3-4 days)

19. **MKV Optimization** (Feature #19)
    - Reorder streams, optimize header compression
    - Show file size savings
    - Technical: mkvpropedit integration, stream reordering
    - Estimated effort: Medium (4-5 days)

### UI/UX Enhancements (3 features)

**Priority:** Low  
**Complexity:** Medium to High  
**User Impact:** Medium (visual improvements)

21. **Dual Pane Mode** (Feature #21)
    - Split screen: source vs destination comparison
    - Show differences in tracks and metadata
    - Technical: Split layout, comparison logic, responsive design
    - Estimated effort: Large (7-10 days)

23. **Waveform Visualization** (Feature #23)
    - Visual representation of audio tracks
    - Click to jump to position, detect silence
    - Technical: Audio analysis, waveform generation, canvas rendering
    - Estimated effort: Large (8-12 days)

25. **Estimated Export Times** (Feature #25)
    - Show time remaining based on system performance
    - Learn from historical export speeds
    - Technical: Performance tracking, ETA calculation, statistics
    - Estimated effort: Medium (4-5 days)

### Integration Features (3 features)

**Priority:** Low to Medium  
**Complexity:** Medium to High  
**User Impact:** Medium (automation and integration)

26. **Watch Folder** (Feature #26)
    - Automatically process files added to monitored folder
    - FileSystemWatcher with auto-export option
    - Technical: File system monitoring, auto-add logic, background processing
    - Estimated effort: Medium (5-7 days)

27. **Command-Line Interface** (Feature #27)
    - Automate exports via CLI without GUI
    - Accept file paths, selections, output paths as arguments
    - Technical: CLI parser, headless mode, JSON output
    - Estimated effort: Large (8-10 days)

28. **Presets Import** (Feature #28)
    - Import HandBrake or other tool presets
    - Map external settings to FFmpeg parameters
    - Technical: Preset parser (JSON/XML), parameter mapping, compatibility warnings
    - Estimated effort: Large (10-15 days)

## Implementation Strategy

### Prioritization Criteria

Features should be prioritized based on:
1. **User demand**: Requested features from users/issues
2. **Effort vs. impact**: High impact, low effort features first
3. **Dependencies**: Features that enable other features
4. **Risk**: Low-risk features before complex/risky ones
5. **Alignment**: Features aligned with product vision

### Suggested Implementation Order

**Tier 1: Quick Wins (Low effort, High impact)**
- Search/Filter (Feature #4)
- Sorting Options (Feature #5)
- Recent Files List (Feature #1)
- Subtitle Format Conversion (Feature #18)

**Tier 2: Export Power (Medium effort, High impact)**
- Trim/Cut Functionality (Feature #9)
- Resolution/Framerate Changes (Feature #10)
- Audio/Subtitle Sync (Feature #17)
- Estimated Export Times (Feature #25)

**Tier 3: Advanced Features (Medium effort, Medium impact)**
- Undo/Redo (Feature #3)
- Chapter Editing (Feature #15)
- MKV Optimization (Feature #19)
- Multi-Profile Export (Feature #14)
- Watch Folder (Feature #26)

**Tier 4: Complex Features (High effort, Medium impact)**
- Dual Pane Mode (Feature #21)
- Waveform Visualization (Feature #23)
- Command-Line Interface (Feature #27)
- Presets Import (Feature #28)

## Development Guidelines

### For Each Feature

1. **Planning**
   - Review feature description in ENHANCEMENTS.md
   - Create sub-issue with detailed technical design
   - Identify models, services, widgets needed
   - List dependencies and risks

2. **Implementation**
   - Create feature branch: `feature/name-of-feature`
   - Follow existing code structure (models, services, widgets, utils)
   - Add unit tests for services and models
   - Add widget tests for UI components
   - Update documentation as you go

3. **Testing**
   - Write tests before or alongside implementation
   - Ensure analyzer/lints pass: `flutter analyze`
   - Format code: `dart format .`
   - Run tests: `flutter test`
   - Test manually on Windows

4. **Documentation**
   - Update ENHANCEMENTS.md: Mark feature as implemented
   - Update FEATURES.md: Add to feature list with description
   - Update README.md: Add to "New Features" if notable
   - Add code comments for complex logic

5. **Review & Merge**
   - Submit PR with clear description and screenshots
   - Link to tracking issue
   - Address review feedback
   - Ensure CI passes before merge

### Code Quality Standards

- **Consistency**: Follow existing patterns and naming conventions
- **Testing**: Minimum 80% code coverage for new code
- **Documentation**: All public APIs documented with dartdoc comments
- **Error Handling**: Graceful failures with user-friendly messages
- **Performance**: No blocking operations on UI thread
- **Backward Compatibility**: Existing configurations must work

### Testing Requirements

For each feature, ensure:
- **Unit tests**: All services and utilities
- **Widget tests**: All dialogs and UI components
- **Integration tests**: End-to-end workflows (optional)
- **Manual tests**: Windows platform validation

## Sub-Issue Template

When creating sub-issues for specific features, use this template:

```markdown
# [Feature Name] — Feature #[Number]

**Phase:** 5  
**Category:** [Quality of Life|Export Enhancements|Batch Operations|Advanced Features|UI/UX Enhancements|Integration Features]  
**Priority:** [Low|Medium|High]  
**Complexity:** [Small|Medium|Large]  
**Estimated Effort:** [X days]

## Description

[Brief description from ENHANCEMENTS.md]

## User Stories

- As a user, I want [action] so that [benefit]
- As a power user, I want [action] so that [benefit]

## Technical Design

### Models
- [ ] Model 1: [description]
- [ ] Model 2: [description]

### Services
- [ ] Service 1: [description]
- [ ] Service 2: [description]

### UI Components
- [ ] Widget 1: [description]
- [ ] Widget 2: [description]

### Utilities
- [ ] Utility 1: [description]

## Implementation Checklist

- [ ] Design UX mockup or description
- [ ] Create models with JSON serialization
- [ ] Implement services with business logic
- [ ] Create UI widgets and dialogs
- [ ] Add unit tests (services, models, utils)
- [ ] Add widget tests (dialogs, components)
- [ ] Update FFmpegExportService if needed
- [ ] Manual testing on Windows
- [ ] Update ENHANCEMENTS.md (mark implemented)
- [ ] Update FEATURES.md (add to list)
- [ ] Update README.md if notable
- [ ] CI passes (format, analyze, test)

## Acceptance Criteria

- [ ] Feature works as described
- [ ] Tests pass with >80% coverage
- [ ] Analyzer/lints pass
- [ ] Manual testing successful
- [ ] Documentation updated
- [ ] No regressions in existing features

## Dependencies

- Depends on: [list features or issues]
- Blocks: [list features or issues]

## Risks & Mitigation

- Risk 1: [description] → Mitigation: [approach]
- Risk 2: [description] → Mitigation: [approach]
```

## Progress Tracking

Track overall Phase 5 progress:

- **Total Features:** 17
- **Completed:** 0
- **In Progress:** 0
- **Planned:** 17

Update the tracking issue checklist as features are completed.

## Questions & Discussion

For questions about Phase 5 planning:
1. Review this document and ENHANCEMENTS.md
2. Check existing documentation (FEATURES.md, PHASES_REPORT.md)
3. Open a discussion or comment on the tracking issue
4. Consider creating a sub-issue for detailed design

## Related Documents

- **Tracking Issue:** `docs/issues/PHASE5_TRACKING_ISSUE.md`
- **Roadmap:** `docs/ENHANCEMENTS.md` (Phase 5 section)
- **Phase Summary:** `docs/PHASES_REPORT.md` (Phase 5 section)
- **Implemented Features:** `docs/FEATURES.md`
- **Testing Guide:** `docs/TESTING.md`
- **Deployment:** `docs/DEPLOYMENT.md`

---

**Last Updated:** 2025-10-22  
**Status:** Planning phase - features documented, not yet scheduled for implementation

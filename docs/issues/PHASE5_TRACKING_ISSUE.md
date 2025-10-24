# Phase 5 — Consolidated Backlog (Remaining Planned Features)

Labels: enhancement, backlog, phase-5, planning

This tracking issue aggregates all remaining planned features into a single phase for prioritization and scheduling. Items below match the numbering used in `ENHANCEMENTS.md`.

References:
- Roadmap: `docs/ENHANCEMENTS.md` (Phase 5 — Consolidated Backlog)
- Phase summaries: `docs/PHASES_REPORT.md` (Phase 5 section)
- Planning guide: `docs/PHASE5_PLANNING.md` (detailed implementation guidance)
- Feature reference: `docs/PHASE5_FEATURES.md` (quick feature lookup)

## Checklist by category

### Quality of Life
- [ ] 1. Recent Files List
- [ ] 3. Undo/Redo
- [ ] 4. Search/Filter
- [ ] 5. Sorting Options

### Export Enhancements
- [ ] 9. Trim/Cut Functionality
- [ ] 10. Resolution/Framerate Changes

### Batch Operations
- [ ] 14. Multi-Profile Export

### Advanced Features
- [ ] 15. Chapter Editing
- [ ] 17. Audio/Subtitle Sync
- [ ] 18. Subtitle Format Conversion
- [ ] 19. MKV Optimization

### UI/UX Enhancements
- [ ] 21. Dual Pane Mode
- [ ] 23. Waveform Visualization
- [ ] 25. Estimated Export Times

### Integration Features
- [ ] 26. Watch Folder
- [ ] 27. Command-Line Interface
- [ ] 28. Presets Import

## Recently Implemented (Post-Phase 4) 🆕

These features were implemented during Phase 5 planning but are not yet reflected in the main ENHANCEMENTS.md:

- ✅ **Export Stage Progress Tracking** - Two-stage export (remux + encode) with progress display for both stages
- ✅ **Comprehensive Export Logging** - Per-file logs with stdout/stderr, timing, and detailed encoding info
- ✅ **Auto-Fix Codec Compatibility** - Automatic transcoding of incompatible codecs when container format selected; auto-drop unsupported subtitles
- ✅ **Dynamic Codec Filtering** - When auto-fix enabled and MP4/WebM format selected, hide incompatible codecs from UI
- ✅ **Codec Preset System for All Codecs** - Quick preset chips (Speed/Balanced/Quality) for H.264, H.265, VP9 (in addition to AV1)
- ✅ **CRF Adjustment** - Manual CRF field for all video codecs
- ✅ **Preset Switching** - Smooth codec switching with automatic reset of preset values to avoid conflicts
- ✅ **Export Summary with Encoding Details** - Display video/audio codec selections, CRF, presets, bitrates in export summary dialog
- ✅ **Cancellation Handling** - Proper exit code mapping for cancellation (shows user-friendly message instead of error)

## Acceptance criteria (general)
For each item above:
- Clear UX behavior defined (mock or description)
- Minimal technical design (data model/service updates)
- Tests added or updated (unit/widget as applicable)
- Documentation updated (README/FEATURES/ENHANCEMENTS if needed)
- CI green (format, analyze, lint, tests)

## Planning notes
- Consider sub-issues per feature for parallel work and clearer review scope.
- Apply labels: `enhancement`, `phase-5`, `backlog`.
- Optional milestone: "Phase 5".
- Keep scope tight; defer risky extras to follow-ups.

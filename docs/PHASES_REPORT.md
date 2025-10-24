# Project Enhancement Phases — Consolidated Report

This single document summarizes the enhancement phases for the FFmpeg Export Tool. Each section highlights what shipped, the value to users, and where to look if you need the full technical write‑ups.

- Phase 1 — Core workflow upgrades (profiles, video stream selection, metadata)
- Phase 2 — Advanced export (codec conversion, quality presets, verification)
- Phase 3 — Batch power (rename patterns, auto‑detect rules, config import/export)
- Phase 4 — UI polish (batch apply, notifications, export queue, file preview)
- Phase 5 — Consolidated backlog (remaining planned features)

This report is self‑contained. Former per‑phase documents have been consolidated here for simplicity.

## Phase 1 — Core Workflow Upgrades

What shipped
- Export Profiles/Templates (Feature #2): Save, apply, and manage reusable export configurations that persist across sessions.
- Video Stream Selection (Feature #6): Detect and selectively include video streams with codec, resolution, and framerate details; proper FFmpeg stream mapping.
- Metadata Editor (Feature #16): Edit file‑level and per‑track metadata with FFmpeg `-metadata` integration.

Impact
- Faster, repeatable workflows via profiles
- Precise control over multi‑stream files
- Cleaner, correct metadata in exported files

Notes
- Models and services extended for tracks and metadata
- UI integrated in file cards; analyzer/tests updated and passing

## Phase 2 — Advanced Export

What shipped
- Codec Conversion (Feature #7): Per‑track video/audio re‑encoding, including Copy mode; arguments built dynamically for FFmpeg.
- Quality/CRF Presets (Feature #8): Fast, Balanced, High Quality presets applying `-crf`, encoder `-preset`, and audio bitrate.
- Verification Mode (Feature #20): Post‑export checks using FFprobe/FFmpeg (existence, stream counts, codec presence, short integrity decode) with visual status.

Impact
- Power users get predictable quality and codec control
- Automatic safety net for export issues with minimal overhead

Notes
- New models/services/widgets added for options and verification
- UI: codec settings dialog, preset chip on file cards, settings toggle

## Phase 3 — Batch Power

What shipped
- Advanced Rename Patterns (Feature #11): Variable substitution with padding (e.g., `{name}`, `{season:2}`, `{episode:3}`, `{index:3}`), predefined templates, validation, and automatic application.
- Auto‑Detect Rules (Feature #12): Priority‑based rules to auto‑select tracks by language/title/channels/type with enable/disable and predefined rules.
- Configuration Import/Export (Feature #13): Complete batch configurations to/from JSON with validation and metadata.

Impact
- Dramatically faster setup for large batches
- Consistent, predictable track selection
- Shareable, reproducible configurations

Notes
- Models/services/utils with comprehensive unit tests
- Integration hooks in export service and main workflow

## Phase 4 — UI Polish

What shipped
- Batch Codecs Apply (Feature #30): Batch mode in `CodecSettingsDialog` and helpers to apply video and audio codec settings across files.
- Better Notifications (Feature #29): Desktop notifications on Windows with rich export stats, plus enhanced in‑app SnackBars and a settings toggle.
- Export Queue Management (Feature #24): Queue item model, service, and panel for reorder/pause/resume/cancel with stream‑based updates.
- File Preview (Feature #22): Detailed preview dialog with tracks, metadata, indicators, and "Open Location" integration.

Impact
- Faster multi‑file operations and clearer progress
- Professional, informative system notifications
- Control and visibility over export workflow
- Confidence before export via rich previews

Notes
- Dialog/layout improvements tuned for responsiveness
- Tests added across services and widgets; analyzer/lints green

## At a Glance — What to Use When
- Need repeatability: Export Profiles (P1)
- Need specific codecs/quality: Codec Conversion + Presets (P2)
- Need large batch automation: Rename Patterns + Rules + Configs (P3)
- Need smooth UX at scale: Batch Apply + Queue + Preview + Notifications (P4)

## Phase 5 — Consolidated Backlog (Planning)

Status
- Phase 5 aggregates all remaining planned features for future implementation
- Items organized by category for easier prioritization and scheduling
- Each feature has clear scope defined in ENHANCEMENTS.md
- Tracking issue: `docs/issues/PHASE5_TRACKING_ISSUE.md`

Scope (17 features across 5 categories)

Quality of Life (4 features)
- Recent Files List (Feature #1): Quick access to recently processed files
- Undo/Redo (Feature #3): Reverse recent selection changes
- Search/Filter (Feature #4): Filter file list by name, status, size, or duration
- Sorting Options (Feature #5): Sort files by various criteria with ascending/descending toggle

Export Enhancements (2 features)
- Trim/Cut Functionality (Feature #9): Set start/end timestamps to export portions of files
- Resolution/Framerate Changes (Feature #10): Downscale or change framerate during export

Batch Operations (1 feature)
- Multi-Profile Export (Feature #14): Export each file with multiple configurations at once

Advanced Features (4 features)
- Chapter Editing (Feature #15): View, edit, or remove chapter markers
- Audio/Subtitle Sync (Feature #17): Adjust timing offsets for out-of-sync tracks
- Subtitle Format Conversion (Feature #18): Convert between ASS/SRT/SUP formats
- MKV Optimization (Feature #19): Reorder streams, optimize header compression

UI/UX Enhancements (3 features)
- Dual Pane Mode (Feature #21): Source vs destination comparison view
- Waveform Visualization (Feature #23): Visual representation of audio tracks
- Estimated Export Times (Feature #25): Show time remaining based on performance metrics

Integration Features (3 features)
- Watch Folder (Feature #26): Automatically process files added to a specific folder
- Command-Line Interface (Feature #27): Automate exports via CLI
- Presets Import (Feature #28): Import HandBrake or other tool presets

Planning Notes
- Features are scoped but not scheduled for implementation
- Consider creating sub-issues for parallel development
- Each feature requires: UX design, technical design, tests, and documentation
- Maintain backward compatibility with existing configurations
- Defer risky or complex features to follow-up phases as needed

## Status and Quality (Phases 1–4)
- Phases 1–4 implemented and documented
- Analyzer/lints/tests passing across environments
- CI workflow stabilized (including Windows build/packaging)
- Phase 5 features planned and documented for future work

## Implementation Strategy
- Phases 1–4: Completed (33 features across 4 phases)
- Phase 5: Planned backlog (17 features awaiting prioritization)
- Follow-up opportunities from Phases 1–4:
  - UI for pattern/rule editors and configuration manager (P3)
  - Hardware‑accelerated encoders and two‑pass options (P2)
  - Extended verification with deeper file scans (P2)

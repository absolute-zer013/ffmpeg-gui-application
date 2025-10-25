# Implementation Overview — Consolidated (All Phases)

This document consolidates all implemented work to date across phases, replaces previous phase summaries and implementation reports, and serves as the single source of truth for what’s shipped.

Last updated: 2025-10-25

## What’s Implemented

For full, user-facing details of each feature, see `docs/FEATURES.md`. Below is a compact inventory grouped by area.

### Core Workflow
- Export Profiles/Templates — Save/apply common export setups
- Video Stream Selection — Choose specific video tracks
- Metadata Editor — Edit file and track metadata
- Verification Mode — Post-export integrity checks and reporting

### Encoding & Quality
- Codec Conversion — Re-encode audio/video with multiple codec options
- Quality Presets — Speed/Balanced/Quality presets mapped to encoder flags
- Two-Stage Export Pipeline — Remux first, then optional re-encode (Phase 5)
- Auto-Fix Codec Compatibility — Container-aware codec enforcement (Phase 5)
- Dynamic Codec Filtering — Hide incompatible codecs when auto-fix is on (Phase 5)
- Codec Preset System (All Major Codecs) — Quick preset chips for common encoders (Phase 5)

### Batch & Automation
- Advanced Rename Patterns — Variable templates, padding, validation
- Auto-Detect Rules — Language/codec/title-based selection rules
- Import/Export Configurations — Save/restore whole batch setups (JSON)
- Batch Codecs Apply — Apply codec settings across many files at once

### UI/UX & Management
- File Preview — Rich file/track details viewer
- Export Queue Management — Reorder, pause/resume/cancel, progress
- Better Notifications — Desktop + in-app notifications with summary
- Quick Reference — Common actions and shortcuts in one place

### Integration
- Command-Line Interface (CLI) — Headless mode with argument parsing + JSON output
- Presets Import — HandBrake JSON import and mapping to FFmpeg

## Reliability & Logging
- Single session log file per app run (always generated), with a timestamped path sourced from the main UI.
- All export stages log commands and stderr/stdout for postmortem analysis.
- CLI mirrors logging behavior for parity in headless mode.

## Feature Removals (As of 2025-10-25)
The following features were fully removed based on user direction. Their modules and tests have been neutralized to keep the build stable, and documentation has been updated accordingly.

- Dual Pane Mode — Removed (model/widget/tests replaced with sentinel content)
- Waveform Visualization — Removed (model/service/widget/tests replaced with sentinel content)

Note: Historical integration guidance remains in `docs/TIER4_INTEGRATION_GUIDE.md` for reference but is not active.

## Notable File References
- CLI: `bin/ffmpeg_cli.dart` (with `bin/CLI_README.md`)
- Presets Import: `lib/models/external_preset.dart`, `lib/services/preset_import_service.dart`, `lib/widgets/preset_import_dialog.dart`
- Export Pipeline and Compatibility: `lib/services/FFmpegExportService` and related UI/config models

## How to Use
- New to the app? Start with `README.md` and `docs/QUICK_REFERENCE.md`.
- Looking for a complete feature list with details? See `docs/FEATURES.md`.
- Running tests and verifying quality? See `docs/TESTING.md`.
- Packaging/distribution? See `docs/DEPLOYMENT.md`.

## Superseded Documents
This file replaces the previous phase/tier summaries and planning docs; those files have been removed to avoid duplication.

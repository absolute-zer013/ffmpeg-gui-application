# Phase 5 — Tier 2: Export Power

Labels: enhancement, phase-5, tier-2, planning

Scope: Medium-effort export enhancements with high user value.

Features in this tier:
- [ ] #9 Trim/Cut Functionality
- [ ] #10 Resolution/Framerate Changes
- [ ] #17 Audio/Subtitle Sync
- [ ] #25 Estimated Export Times

References:
- Roadmap: `docs/PHASE5_FEATURES.md` (Tier 2)
- Planning Guide: `docs/PHASE5_PLANNING.md`

## Global Acceptance Criteria
- Clear UX behavior defined (mock or description)
- Minimal technical design (data model/service updates)
- Tests added or updated (unit/widget as applicable)
- Documentation updated (README/FEATURES/ENHANCEMENTS if needed)
- CI green (format, analyze, lint, tests)

## Work Items

### 1) Trim/Cut Functionality (#9)
- [ ] UI: start/end (HH:MM:SS) and timeline slider
- [ ] Parse and validate times
- [ ] FFmpeg: -ss / -to integration
- [ ] Tests for parsing and argument building

### 2) Resolution/Framerate Changes (#10)
- [ ] UI: resolution/framerate presets
- [ ] FFmpeg: scale filter and -r parameter
- [ ] Size estimate display
- [ ] Tests for mapping logic

### 3) Audio/Subtitle Sync (#17)
- [ ] Per-track ms offset inputs
- [ ] FFmpeg: -itsoffset integration
- [ ] Optional preview plan
- [ ] Tests for offset mapping

### 4) Estimated Export Times (#25)
- [ ] Track throughput; compute ETA current + total
- [ ] Persist metrics; rolling average
- [ ] UI: status chips/badges
- [ ] Unit tests for ETA calculation

## Done Definition
- [ ] All tasks checked above
- [ ] User docs updated
- [ ] Release notes entry prepared

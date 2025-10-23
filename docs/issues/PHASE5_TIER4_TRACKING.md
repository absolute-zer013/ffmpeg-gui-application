# Phase 5 — Tier 4: Complex Features

Labels: enhancement, phase-5, tier-4, planning

Scope: High-effort features with specialized use cases.

Features in this tier:
- [ ] #21 Dual Pane Mode
- [ ] #23 Waveform Visualization
- [ ] #27 Command-Line Interface
- [ ] #28 Presets Import

References:
- Roadmap: `docs/PHASE5_FEATURES.md` (Tier 4)
- Planning Guide: `docs/PHASE5_PLANNING.md`

## Global Acceptance Criteria
- Clear UX behavior defined (mock or description)
- Minimal technical design (data model/service updates)
- Tests added or updated (unit/widget as applicable)
- Documentation updated (README/FEATURES/ENHANCEMENTS if needed)
- CI green (format, analyze, lint, tests)

## Work Items

### Dual Pane Mode (#21)
- [ ] Split layout; responsive behavior
- [ ] Differences view for tracks/metadata
- [ ] Tests for layout logic

### Waveform Visualization (#23)
- [ ] Audio extraction and downsampling
- [ ] Canvas rendering; zoom/scroll
- [ ] Tests for waveform pipeline

### Command-Line Interface (#27)
- [ ] CLI entry point; argument parsing
- [ ] JSON output; headless execution
- [ ] Tests for CLI commands

### Presets Import (#28)
- [ ] Parse HandBrake JSON/XML
- [ ] Mapping to FFmpeg params; compatibility warnings
- [ ] Tests for parsers and mappings

## Done Definition
- [ ] All tasks checked above
- [ ] User docs updated
- [ ] Release notes entry prepared

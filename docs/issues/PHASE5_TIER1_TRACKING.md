# Phase 5 — Tier 1: Quick Wins

Labels: enhancement, phase-5, tier-1, planning

Scope: Low-effort, high-impact items to ship first.

Features in this tier:
- [ ] #1 Recent Files List
- [ ] #4 Search/Filter
- [ ] #5 Sorting Options
- [ ] #18 Subtitle Format Conversion
- [ ] #32 Batch Rename UX Quick Wins (presets + preview export)

References:
- Roadmap: `docs/PHASE5_FEATURES.md` (Tier 1, Features #1, #4, #5, #18, #32)
- Planning Guide: `docs/PHASE5_PLANNING.md`

## Global Acceptance Criteria
- Clear UX behavior defined (mock or description)
- Minimal technical design (data model/service updates)
- Tests added or updated (unit/widget as applicable)
- Documentation updated (README/FEATURES/ENHANCEMENTS if needed)
- CI green (format, analyze, lint, tests)

## Work Items

### 1) Recent Files List (#1)
- [ ] Persist last 10–20 processed files (SharedPreferences)
- [ ] App bar dropdown / quick access
- [ ] Remove/browse handling, missing file state
- [ ] Unit + widget tests

### 2) Search/Filter (#4)
- [ ] Search text field and filter chips
- [ ] Filter by name/status/size/duration
- [ ] Filtered count display
- [ ] Widget tests for filtering logic

### 3) Sorting Options (#5)
- [ ] Sort by name/size/duration/status
- [ ] Asc/Desc toggle
- [ ] Persist preference
- [ ] Unit tests for comparator logic

### 4) Subtitle Format Conversion (#18)
- [ ] UI: subtitle format dropdown per track
- [ ] FFmpeg parameter mapping (-c:s)
- [ ] Validation + tests
- [ ] Docs update

### 5) Batch Rename UX Quick Wins (#32)
- [ ] Presets: TV, Movie, Anime, Indexed, With Date
- [ ] Live variable hints + validation messages
- [ ] Export preview table to CSV/Markdown
- [ ] Persist last-used pattern + params
- [ ] Unit tests for export and presets

## Done Definition
- [ ] All tasks checked above
- [ ] Demo GIF added to README or FEATURES.md (optional)
- [ ] Release notes entry prepared

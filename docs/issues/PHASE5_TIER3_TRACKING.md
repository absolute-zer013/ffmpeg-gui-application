# Phase 5 — Tier 3: Advanced Features

Labels: enhancement, phase-5, tier-3, planning

Scope: Medium-effort features for power users.

Features in this tier:
- [ ] #3 Undo/Redo
- [ ] #15 Chapter Editing
- [ ] #19 MKV Optimization
- [ ] #14 Multi-Profile Export
- [ ] #26 Watch Folder
- [ ] (Candidate) #31 Batch Rename v2 — consider pulling in if prioritized

References:
- Roadmap: `docs/PHASE5_FEATURES.md` (Tier 3)
- Planning Guide: `docs/PHASE5_PLANNING.md`

## Global Acceptance Criteria
- Clear UX behavior defined (mock or description)
- Minimal technical design (data model/service updates)
- Tests added or updated (unit/widget as applicable)
- Documentation updated (README/FEATURES/ENHANCEMENTS if needed)
- CI green (format, analyze, lint, tests)

## Work Items

### Undo/Redo (#3)
- [ ] Command pattern; history stacks
- [ ] Keyboard shortcuts (Ctrl+Z/Y)
- [ ] Tests for reversible actions

### Chapter Editing (#15)
- [ ] Parse chapters (ffprobe)
- [ ] Editor dialog: add/edit/delete/reorder
- [ ] Write back via FFmpeg metadata
- [ ] Tests for parsing/serialization

### MKV Optimization (#19)
- [ ] mkvpropedit integration
- [ ] Stream reordering policies
- [ ] Report size savings
- [ ] Tests for invocation/mapping

### Multi-Profile Export (#14)
- [ ] Select multiple profiles per file
- [ ] Queue per-profile exports
- [ ] Suffix strategy for outputs
- [ ] Tests for queue behavior

### Watch Folder (#26)
- [ ] Config UI and persistence
- [ ] File system watcher
- [ ] Auto-add + optional auto-export
- [ ] Tests for watcher logic

### (Candidate) Batch Rename v2 (#31)
- [ ] Global find/replace (regex option)
- [ ] Conflict policy selection UI
- [ ] Dry-run report export
- [ ] Per-file overrides

## Done Definition
- [ ] All tasks checked above
- [ ] User docs updated
- [ ] Release notes entry prepared

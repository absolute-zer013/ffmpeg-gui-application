# FFmpeg Export Tool — Documentation Index

Complete guide to all project documentation. Start here to find what you need.

## Quick Links

### Getting Started
- **[README.md](../README.md)** - Project overview, setup, and basic usage
- **[FEATURES.md](FEATURES.md)** - Complete list of implemented features

### Testing & Quality
- **[TESTING.md](TESTING.md)** - Testing guide and running tests
- **[CI_CD_SETUP.md](../CI_CD_SETUP.md)** - Continuous integration setup

### Deployment
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Build and distribution instructions

### Enhancement Planning
- **[ENHANCEMENTS.md](ENHANCEMENTS.md)** - Complete roadmap (Phases 1-5)
- **[PHASES_REPORT.md](PHASES_REPORT.md)** - Phase summaries (Phases 1-5)

## Documentation by Phase

### Phase 1 — Core Workflow Upgrades ✅ Completed
**Features:** Export Profiles, Video Stream Selection, Metadata Editor

**Documentation:**
- Summary: `PHASES_REPORT.md` (Phase 1 section)
- Detailed descriptions: `ENHANCEMENTS.md` (Features #2, #6, #16)
- Implementation: `FEATURES.md` (Features #21-23)

### Phase 2 — Advanced Export ✅ Completed
**Features:** Codec Conversion, Quality Presets, Verification Mode

**Documentation:**
- Summary: `PHASES_REPORT.md` (Phase 2 section)
- Detailed descriptions: `ENHANCEMENTS.md` (Features #7, #8, #20)
- Implementation: `FEATURES.md` (Features #24-26)

### Phase 3 — Batch Power ✅ Completed
**Features:** Advanced Rename Patterns, Auto-Detect Rules, Configuration Import/Export

**Documentation:**
- Summary: `PHASES_REPORT.md` (Phase 3 section)
- Detailed descriptions: `ENHANCEMENTS.md` (Features #11-13)
- Implementation: `FEATURES.md` (Features #27-29)

### Phase 4 — UI Polish ✅ Completed
**Features:** File Preview, Export Queue Management, Better Notifications, Batch Codec/Quality Apply

**Documentation:**
- Summary: `PHASES_REPORT.md` (Phase 4 section)
- Detailed descriptions: `ENHANCEMENTS.md` (Features #22, #24, #29, #30)
- Implementation: `FEATURES.md` (Features #30-33)

### Phase 5 — Consolidated Backlog 📋 Planning
**Features:** 17 remaining planned features across 5 categories

**Documentation:**
- **[PHASE5_TRACKING_ISSUE.md](issues/PHASE5_TRACKING_ISSUE.md)** - Tracking issue with checklist
- **[PHASE5_PLANNING.md](PHASE5_PLANNING.md)** - Detailed implementation guidance
- **[PHASE5_FEATURES.md](PHASE5_FEATURES.md)** - Quick reference table
- **Summary:** `PHASES_REPORT.md` (Phase 5 section)
- **Detailed descriptions:** `ENHANCEMENTS.md` (Phase 5 section)

## Documentation by Type

### Planning Documents
| Document | Purpose | Audience |
|----------|---------|----------|
| [ENHANCEMENTS.md](ENHANCEMENTS.md) | Complete roadmap with all planned features | Developers, Contributors |
| [PHASES_REPORT.md](PHASES_REPORT.md) | Executive summary of all phases | Product Owners, Managers |
| [PHASE5_PLANNING.md](PHASE5_PLANNING.md) | Phase 5 implementation guidance | Developers, Contributors |
| [PHASE5_FEATURES.md](PHASE5_FEATURES.md) | Phase 5 quick reference | All stakeholders |
| [issues/PHASE5_TRACKING_ISSUE.md](issues/PHASE5_TRACKING_ISSUE.md) | Phase 5 tracking checklist | Project Managers |

### Implementation Documents
| Document | Purpose | Audience |
|----------|---------|----------|
| [FEATURES.md](FEATURES.md) | Implemented feature list | Users, Developers |
| [README.md](../README.md) | Getting started guide | Users, New Developers |
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Quick usage reference | Users |

### Development Documents
| Document | Purpose | Audience |
|----------|---------|----------|
| [TESTING.md](TESTING.md) | Testing guide and standards | Developers, QA |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Build and release process | Developers, DevOps |
| [CI_CD_SETUP.md](../CI_CD_SETUP.md) | CI/CD configuration | DevOps |

## Phase 5 Documentation Deep Dive

Phase 5 has the most comprehensive planning documentation. Here's how to use it:

### For Project Managers
1. Start with **[PHASES_REPORT.md](PHASES_REPORT.md)** (Phase 5 section) for overview
2. Review **[PHASE5_FEATURES.md](PHASE5_FEATURES.md)** for feature list and priorities
3. Use **[issues/PHASE5_TRACKING_ISSUE.md](issues/PHASE5_TRACKING_ISSUE.md)** for tracking progress

### For Developers
1. Read **[PHASE5_PLANNING.md](PHASE5_PLANNING.md)** for implementation strategy
2. Use **[ENHANCEMENTS.md](ENHANCEMENTS.md)** for detailed feature descriptions
3. Follow sub-issue template in **[PHASE5_PLANNING.md](PHASE5_PLANNING.md)** for new features

### For Product Owners
1. Start with **[PHASE5_FEATURES.md](PHASE5_FEATURES.md)** for feature priorities
2. Review **[ENHANCEMENTS.md](ENHANCEMENTS.md)** for user-facing descriptions
3. Track progress in **[issues/PHASE5_TRACKING_ISSUE.md](issues/PHASE5_TRACKING_ISSUE.md)**

### For Contributors
1. Read **[PHASE5_PLANNING.md](PHASE5_PLANNING.md)** development guidelines
2. Pick a feature from **[PHASE5_FEATURES.md](PHASE5_FEATURES.md)**
3. Follow implementation checklist in **[PHASE5_PLANNING.md](PHASE5_PLANNING.md)**

## Documentation Structure

```
/
├── README.md                      # Project overview and setup
├── CI_CD_SETUP.md                # CI/CD summary
│
├── docs/
│   ├── DOCUMENTATION_INDEX.md    # This file
│   ├── FEATURES.md               # Implemented features (Phases 1-4)
│   ├── ENHANCEMENTS.md           # Complete roadmap (Phases 1-5)
│   ├── PHASES_REPORT.md          # Phase summaries (Phases 1-5)
│   ├── TESTING.md                # Testing guide
│   ├── DEPLOYMENT.md             # Deployment guide
│   ├── QUICK_REFERENCE.md        # Quick usage reference
│   │
│   ├── PHASE5_PLANNING.md        # Phase 5 implementation guide
│   ├── PHASE5_FEATURES.md        # Phase 5 feature reference
│   │
│   └── issues/
│       └── PHASE5_TRACKING_ISSUE.md  # Phase 5 tracking checklist
```

## Finding Information

### "How do I use feature X?"
→ [FEATURES.md](FEATURES.md) or [README.md](../README.md)

### "What features are planned?"
→ [ENHANCEMENTS.md](ENHANCEMENTS.md) or [PHASE5_FEATURES.md](PHASE5_FEATURES.md)

### "How do I implement feature Y?"
→ [PHASE5_PLANNING.md](PHASE5_PLANNING.md) and [ENHANCEMENTS.md](ENHANCEMENTS.md)

### "What's the status of Phase Z?"
→ [PHASES_REPORT.md](PHASES_REPORT.md)

### "How do I run tests?"
→ [TESTING.md](TESTING.md)

### "How do I build and deploy?"
→ [DEPLOYMENT.md](DEPLOYMENT.md)

### "What's in Phase 5?"
→ [PHASE5_FEATURES.md](PHASE5_FEATURES.md) (quick reference)  
→ [PHASE5_PLANNING.md](PHASE5_PLANNING.md) (implementation details)  
→ [issues/PHASE5_TRACKING_ISSUE.md](issues/PHASE5_TRACKING_ISSUE.md) (tracking)

## Contributing

When adding new features:
1. Review the appropriate planning document (e.g., [PHASE5_PLANNING.md](PHASE5_PLANNING.md))
2. Follow the sub-issue template
3. Update documentation when complete:
   - Mark feature as implemented in [ENHANCEMENTS.md](ENHANCEMENTS.md)
   - Add to [FEATURES.md](FEATURES.md) with details
   - Update tracking issue checklist
   - Update README.md if notable

## Documentation Maintenance

### When to Update
- **README.md**: When adding major features visible to users
- **FEATURES.md**: When completing any feature from the roadmap
- **ENHANCEMENTS.md**: When a feature is completed (mark with ✅)
- **PHASES_REPORT.md**: When completing a phase or updating phase status
- **PHASE5_* files**: When planning changes or features are completed
- **Tracking issues**: When feature status changes

### Documentation Standards
- Use Markdown for all documentation
- Include dates on planning documents
- Keep cross-references up to date
- Use consistent formatting and structure
- Include examples where helpful
- Update both summary and detailed docs

## Questions?

If you can't find what you need:
1. Check this index first
2. Search across all documentation files
3. Review the relevant phase documentation
4. Open a discussion or issue on GitHub

---

**Last Updated:** 2025-10-22  
**Documentation Version:** 5.0 (reflects Phases 1-5)
